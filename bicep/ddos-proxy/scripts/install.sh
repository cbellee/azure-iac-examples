#!/bin/bash

if [ -x "$(command -v docker)" ]; then
    echo "Docker is already installed"
else
      echo "Installing Docker..."
  
  sudo apt-get update -y && sudo apt-get upgrade -y

  sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --no-tty --batch --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  sudo chmod o+r /usr/share/keyrings/docker-archive-keyring.gpg

  sudo echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi
