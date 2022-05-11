sudo /usr/local/share/desktop-init.sh
sudo /usr/local/share/ssh-init.sh
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sudo tailscale up --authkey=$TAILSCALE_AUTHKEY

export PLAN9=/usr/local/plan9
export PATH=$PATH:$PLAN9/bin:/usr/local/go/bin
