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
echo "done"

# TODO start tailscale & ssh services