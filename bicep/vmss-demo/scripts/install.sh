#!/bin/bash

sudo systemctl stop goweb.service
sudo systemctl disable goweb.service
sudo rm /etc/systemd/system/goweb.service

cp ./vmss-test-app /home/localadmin/vmss-test-app

cat <<EOF > /etc/systemd/system/goweb.service
[Unit]
Description=Go web app
After=multi-user.target

[Service]
User=root
Group=root
ExecStart=/home/localadmin/vmss-test-app

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start goweb.service
sudo systemctl enable goweb.service
