# Outline Setup Instructions

On an internet-connected device:

```bash
git clone https://github.com/sears-s/outline-setup.git
cd outline-setup
./outline-setup pull
```

Copy the `outline-setup` directory to the offline device, including the files `outline.sh`, `settings.env`, `docker-compose`, and `images.tar.gz` at the minimum. On the offline device:

```bash
cd outline-setup
./outline.sh start
```
