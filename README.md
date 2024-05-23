# Outline Setup Instructions

On an internet-connected device:

```bash
git clone https://github.com/sears-s/outline-setup.git
cd outline-setup
./outline-setup pull
```

Copy the `outline-setup` directory to the offline device, including the files `outline.sh`, `docker-compose.yml`, `settings.env`, `docker-compose` (~60MB), and `images.tar.gz` (~650MB) at the minimum. On the offline device, setup Keycloak using the following steps:

1. Go to https://controller.lan/auth/realms/CVAH-SSO/console (or applicable URL) to access the console for the realm.
2. Click on _Clients_, then _Create_.
3. Set _Client ID_ to `outline`, _Client Protocol_ to `openid-connect`, and _Root URL_ to `https://outline.controller.lan:4000` (unless `DOMAIN` or `PORT` are changed in `settings.env`).
4. Click _Save_.
5. Set _Name_ to `Outline Wiki`, _Access Type_ to `confidential`, and _Base URL_ to `https://outline.controller.lan:4000`. Ensure `Standard Flow Enabled` is turned on and all switches below it are turned off.
6. Click _Save_, then _Credentials_.
7. Ensure _Client Authenticator_ is set to _Client Id and Secret_. Copy the _Secret_ value.

Open `settings.env` with a text editor, and set `KEYCLOAK_CLIENT_SECRET` to the value just copied. Adjust other settings as needed. Then start the services:

```bash
cd outline-setup
./outline.sh start
```
