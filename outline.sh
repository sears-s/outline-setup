#!/usr/bin/env bash

# Check script is running as root
if [ $(id -u) -ne 0 ]; then
	echo "Error: Run this script as root or sudo." >&2
	exit 1
fi

# Constants
script_dir=$(dirname $(realpath $0))
compose_path=${script_dir}/docker-compose
compose_cmd=${compose_path} -f ${script_dir}/docker-compose.yml --env-file ${script_dir}/settings.env
images_path=${script_dir}/images.tar.gz

get_image_list() {
	return $($compose_cmd config --images)
}

cmd_help() {
	echo "Usage: $0 <command>"
	echo "Commands:"
	echo "help: show this message"
	echo "pull: download required files on an internet-connected device"
	echo "install: install downloaded files on the offline device"
	echo "start: install if not already done; stop services if currently running; start services"
	echo "stop: stops services"
	echo "compose: run an arbitrary docker compose command"
}

cmd_pull() {
	# Download docker compose binary
	curl https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -Lo $compose_path
	chmod +x $compose_path

	# Pull and export docker images
	$compose_cmd pull
	docker image save $(get_image_list) | gzip >$images_path
}

cmd_install() {
	# Return if docker images already imported
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
	cmd_stop
	cmd_install
	$compose_cmd up -d
}

cmd_stop() {
	$compose_cmd down
}

cmd_compose() {
	$compose_cmd $@
}

# Show help menu
cmd=$1
case $cmd in
"" | "-h" | "--help")
	cmd_help
	;;
*)

	# Check if compose is installed
	if [ $cmd != "install" ] && [ ! -f $compose_path ]; then
		echo "Error: $compose_path does not exist. Run the pull command on an internet-connected device." >&2
		exit 1
	fi

	# Run user command
	shift
	cmd_${cmd} $@
	if [ $? = 127 ]; then
		echo "Error: $cmd is not a known command." >&2
		cmd_help
		exit 1
	fi
	;;
esac
