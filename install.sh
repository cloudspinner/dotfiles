#!/usr/bin/env bash
dotfiledir="$(dirname "$(realpath "$0")")"
echo "dotfiles in $dotfiledir"

echo "Installing Go...\n"
curl -OL https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz
gobin=/usr/local/go/bin
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
echo "done"

echo "Installing ssh..."
curl -sSL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/sshd-debian.sh | sudo bash -s -- 2222 $(whoami) true $VSCODE_PASSW
echo "done"

echo "Installing Acme...\n"
sudo apt-get install -y libx11-dev libfreetype6-dev libfontconfig1-dev libxext-dev libxt-dev mosh
cd /usr/local
sudo git clone https://github.com/9fans/plan9port plan9
cd plan9
sudo git apply "$dotfiledir"/scripts/acme-vnc-fix.patch
sudo sh INSTALL
echo 'export PLAN9=/usr/local/plan9' >> /home/vscode/.profile
echo 'export PATH=$PATH:$PLAN9/bin' >> /home/vscode/.profile
mkdir /home/vscode/.local/bin
cp "$dotfiledir"/scripts/acme/bin/* /home/vscode/.local/bin
cat << EOF >> /home/vscode/.bashrc
## If inside Acme...
if [ "$winid" ]; then
  ## ... then patch the `cd` command
  _cd () {
    \cd "$@" && awd
  }
  alias cd=_cd
  PS1='$ '
  alias ls="ls --color=never"
  alias lf="lc -F"
fi
EOF
# Make sure PATH from profile (including the PLAN9 commands)
# is used by non-interactive ssh login (e.g. when using sam -r)
mkdir /home/vscode/.ssh
echo 'BASH_ENV=/home/vscode/.profile' > /home/vscode/.ssh/environment
chmod 600 /home/vscode/.ssh/environment
echo "done"

sudo cp "$dotfiledir"/scripts/devcontainer-init.sh /etc/profile.d
