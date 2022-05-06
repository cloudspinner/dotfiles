dotfiledir="$(dirname "$(realpath "$0")")"

echo "Installing Tailscale...\n"
mkdir -p /go/src/tailscale
cd /go/src/tailscale
git clone https://github.com/tailscale/tailscale.git
cd tailscale
go mod downloads
sudo go install -mod=readonly ./cmd/tailscaled ./cmd/tailscale
sudo apt-get update
sudo apt-get install -y curl gpg dnsutils
sudo cp "$dotfiledir"/scripts/tailscaled /etc/init.d
sudo cp /go/bin/tailscaled /usr/sbin/tailscaled
sudo cp /go/bin/tailscale /usr/bin/tailscale
sudo mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
echo "done"

echo "Installing VNC...\n"
exec "$dotfiledir"/scripts/desktop-lite-debian.sh
echo "done"

echo 'sudo service ssh status > /dev/null || service ssh start' >> /home/vscode/.bashrc
echo 'sudo service tailscaled status > /dev/null || service tailscaled start' >> /home/vscode/.bashrc

echo "Installing Acme...\n"
sudo apt-get install -y xorg-dev mosh
cd /usr/local
git clone https://github.com/9fans/plan9port plan9
cd plan9
git apply "$dotfiledir"/scripts/acme-vnc-fix.patch
sh INSTALL
echo "done"

echo 'export PLAN9=/usr/local/plan9' >> /home/vscode/.bashrc
echo 'export PATH=$PATH:$PLAN9/bin' >> /home/vscode/.bashrc