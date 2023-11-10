#!/bin/bash -v

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
sudo apt update && \
sudo apt install git
sudo mkdir /usr/src/app
sudo chmod 767 /usr/src/app

cd /usr/src/app
git clone https://github.com/Yuriy777/docker-run.git .
npm ci && npm run build
npm run start