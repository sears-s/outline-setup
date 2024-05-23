#!/usr/bin/env bash

# Exit on errors
set -e

# Check script is running as root
if [ $(id -u) -ne 0 ]; then
	echo 'Error: Run this script as root or sudo.' >&2
	exit 1
fi

# Constants
script_dir=$(dirname $(realpath $0))
compose_yml_path=$script_dir/docker-compose.yml
settings_path=$script_dir/settings.env
images_path=$script_dir/images.tar.gz
compose_path=$script_dir/docker-compose
source $settings_path
secrets_path=$DATA_DIR/secrets.env
access_log_path=$DATA_DIR/access.log
compose_cmd_online="$compose_path --log-level ERROR -f $compose_yml_path --env-file $settings_path"
compose_cmd_offline="$compose_path -f $compose_yml_path --env-file $settings_path --env-file $secrets_path"

# Check for necessary files
paths=($compose_yml_path $settings_path)
for path in ${paths[@]}; do
	if [ ! -f $path ]; then
		echo "Error: $path does not exist." >&2
		exit 1
	fi
done

# Utility functions
get_image_list() {
	$compose_cmd_online config --images
}

generate_hex() {
	hexdump -vn32 -e'4/4 "%08x"' /dev/urandom
}

# Command functions
cmd_help() {
	echo "Usage: $0 <command>"
	echo 'Commands:'
	echo -e '\thelp: show this message'
	echo -e '\tpull: download required files on an internet-connected device'
	echo -e '\tinstall: install downloaded files on the offline device'
	echo -e '\tstart: install if not already done; stop services if currently running; start services'
	echo -e '\tstop: stops services'
	echo -e '\tcompose: run an arbitrary docker compose command'
}

cmd_pull() {
	# Download docker compose binary
	curl https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -Lo $compose_path
	chmod +x $compose_path

	# Pull and export docker images
	$compose_cmd_online pull
	docker image save $(get_image_list) | gzip >$images_path
}

cmd_install() {
	# Create data directory and fix permissions for outline nodejs user
	$outline_storage_dir=$DATA_DIR/outline-storage
	if [ ! -d $outline_storage_dir ]; then
		mkdir -p $outline_storage_dir
		chown 1001:1001 $outline_storage_dir
	fi

	# Create access log
	if [ ! -f $access_log_path ]; then
		touch $access_log_path
	fi

	# Create randomly-generated secrets
	if [ ! -f $secrets_path ]; then
		touch $secrets_path
		chmod 600 $secrets_path
		secrets=('OUTLINE_SECRET_KEY' 'OUTLINE_UTILS_SECRET' 'POSTGRES_PASSWORD')
		for secret in ${secrets[@]}; do
			echo "$secret=$(generate_hex)" >>$secrets_path
		done
	fi

	# Return if docker images already exist
	if docker image inspect $(get_image_list) >/dev/null 2>&1; then
		return
	fi

	# Import docker images
	if [ ! -f $images_path ]; then
		echo "Error: $images_path does not exist. Run the pull command on an internet-connected device." >&2
		exit 1
	fi
	docker image load <$images_path
}

cmd_start() {
	cmd_install
	cmd_stop
	$compose_cmd_offline up -d
}

cmd_stop() {
	$compose_cmd_offline down
}

cmd_compose() {
	$compose_cmd_offline $@
}

# Show help menu
cmd=$1
case $cmd in
"" | "-h" | "--help")
	cmd_help
	;;
*)

	# Check if compose is downloaded
	if [ $cmd != "install" ] && [ ! -f $compose_path ]; then
		echo "Error: $compose_path does not exist. Run the pull command on an internet-connected device." >&2
		exit 1
	fi

	# Run user command
	shift
	cmd_$cmd $@
	if [ $? = 127 ]; then
		echo "Error: $cmd is not a known command." >&2
		cmd_help
		exit 1
	fi
	;;
esac
