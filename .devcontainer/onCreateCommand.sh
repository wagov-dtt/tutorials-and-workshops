#!/bin/bash
# This script enables docker in docker locally, then installs brew, just and fzf on linux
sudo chown $(whoami) /var/run/docker.sock
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
brew install just fzf
# Install mountpoint for s3 (AWS)
wget "https://s3.amazonaws.com/mountpoint-s3-release/latest/$(uname -m)/mount-s3.deb" && sudo apt-get update && sudo apt-get install -y ./mount-s3.deb; rm mount-s3.deb