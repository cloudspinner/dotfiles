#!/bin/bash

sudo /usr/local/share/desktop-init.sh
sudo /usr/local/share/ssh-init.sh
if [ -z "$(sudo netstat -tupln | grep 1055)" ];
then
    sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
    sudo tailscale up --authkey=$TAILSCALE_AUTHKEY
fi

export PLAN9=/usr/local/plan9
export PATH=$PATH:$PLAN9/bin:/usr/local/go/bin
