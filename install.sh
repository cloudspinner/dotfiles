dotfiledir="$(dirname "$(realpath "$0")")"
echo "dotfiles in $dotfiledir"

echo "Installing Go...\n"
curl -OL https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz
PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile
echo "done" 

echo "Installing Tailscale...\n"
mkdir -p /usr/local/go/src/tailscale
cd /usr/local/go/src/tailscale
git clone https://github.com/tailscale/tailscale.git
cd tailscale
go mod downloads
sudo go install -mod=readonly ./cmd/tailscaled ./cmd/tailscale
sudo apt-get update
sudo apt-get install -y curl gpg dnsutils
sudo cp "$dotfiledir"/scripts/tailscaled /etc/init.d
sudo cp /usr/local/go/bin/tailscaled /usr/sbin/tailscaled
sudo cp /usr/local/go/bin/tailscale /usr/bin/tailscale
sudo mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
echo "done"

echo "Installing VNC...\n"
sudo exec "$dotfiledir"/scripts/desktop-lite-debian.sh
echo "done"

echo 'sudo service ssh status > /dev/null || service ssh start' >> $HOME/.profile
echo 'sudo service tailscaled status > /dev/null || service tailscaled start' >> $HOME/.profile

echo "Installing Acme...\n"
sudo apt-get install -y xorg-dev mosh
cd /usr/local
git clone https://github.com/9fans/plan9port plan9
cd plan9
git apply "$dotfiledir"/scripts/acme-vnc-fix.patch
sh INSTALL
echo "done"

echo 'export PLAN9=/usr/local/plan9' >> $HOME/.profile
echo 'export PATH=$PATH:$PLAN9/bin' >> $HOME/.profile