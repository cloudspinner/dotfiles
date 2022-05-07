#!/usr/bin/env bash
dotfiledir="$(dirname "$(realpath "$0")")"
echo "dotfiles in $dotfiledir"

echo "Installing Go...\n"
curl -OL https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz
gobin=/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile
echo "done"

echo "Installing Tailscale...\n"
sudo mkdir -p /usr/local/go/src/tailscale
cd /usr/local/go/src/tailscale
sudo git clone https://github.com/tailscale/tailscale.git
cd tailscale
$gobin/go mod downloads
sudo $gobin/go install -mod=readonly ./cmd/tailscaled ./cmd/tailscale
sudo apt-get update
sudo apt-get install -y gpg dnsutils
sudo cp "$dotfiledir"/scripts/tailscaled /etc/init.d # todo: use curl to get tailscaled?
sudo cp /usr/local/go/bin/tailscaled /usr/sbin/tailscaled
sudo cp /usr/local/go/bin/tailscale /usr/bin/tailscale
sudo mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
echo "done"

echo "Installing VNC...\n"
sudo bash "$dotfiledir"/scripts/desktop-lite-debian.sh # todo: use curl to get script?
echo 'sudo /usr/local/share/desktop-init.sh' >> $HOME/.profile
echo "done"

echo "Installing ssh..."
curl -sSL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/sshd-debian.sh | sudo bash -s -- 2222 $(whoami) true $VSCODE_PASSW
echo "done"

echo 'sudo service ssh status > /dev/null || sudo service ssh start' >> $HOME/.profile
echo 'tailscale status > /dev/null || sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &' >> $HOME/.profile
echo 'tailscale status > /dev/null || sudo tailscale up --authkey=$TAILSCALE_AUTHKEY' >> $HOME/.profile

echo "Installing Acme...\n"
sudo apt-get install -y libx11-dev libfreetype6-dev libfontconfig1-dev libxext-dev libxt-dev mosh
cd /usr/local
sudo git clone https://github.com/9fans/plan9port plan9
cd plan9
sudo git apply "$dotfiledir"/scripts/acme-vnc-fix.patch
sudo sh INSTALL
echo "done"

echo 'export PLAN9=/usr/local/plan9' >> $HOME/.profile
echo 'export PATH=$PATH:$PLAN9/bin' >> $HOME/.profile
