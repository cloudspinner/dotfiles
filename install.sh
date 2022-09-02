#!/usr/bin/env bash
dotfiledir="$(dirname "$(realpath "$0")")"
echo "dotfiles in $dotfiledir"

echo "Installing Go...\n"
curl -OL https://go.dev/dl/go1.19.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.linux-amd64.tar.gz
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

echo "Installing ssh...\n"
curl -sSL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/sshd-debian.sh | sudo bash -s -- 2222 $(whoami) true $SSH_PASSW
echo "done"

echo "Installing clj-kondo...\n"
cd /usr/local
sudo curl -sLO https://raw.githubusercontent.com/clj-kondo/clj-kondo/master/script/install-clj-kondo
sudo chmod +x install-clj-kondo
sudo ./install-clj-kondo
echo "done"

echo "Installing tmux+neovim+conjure...\n"
cd /home/vscode
sudo apt-get install -y tmux neovim python3-pip
# Set nvim as the default vim command
sudo update-alternatives --config vim
pip3 install --upgrade msgpack
sh -c 'curl -fLo /home/vscode/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
mkdir -p /home/vscode/.config/nvim
cp "$dotfiledir"/scripts/init.vim /home/vscode/.config/nvim
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
mkdir -p /home/vscode/.local/bin
cp "$dotfiledir"/scripts/acme/bin/* /home/vscode/.local/bin
cat << EOF >> /home/vscode/.bashrc
## If inside Acme...
if [ \${winid} ]; then
  ## ... then patch the `cd` command
  _cd () {
    \cd \${@} && awd
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

## Install dependencies for acme scripts:
$gobin/go install github.com/cloudspinner/gonrepl@latest
$gobin/go install github.com/cloudspinner/acmeaddr@latest
echo 'export PATH=$PATH:$HOME/go/bin' >> /home/vscode/.profile

echo "Installing Go fonts...\n"
cd /home/vscode
git clone https://go.googlesource.com/image
mkdir .fonts
cp /home/vscode/image/font/gofont/ttfs/*.ttf /home/vscode/.fonts

echo "Installing Source Code Pro font...\n"
cd .fonts
curl -OL "https://github.com/adobe-fonts/source-code-pro/raw/release/TTF/SourceCodePro-Regular.ttf"

echo "Updating font cache...\n"
#sudo apt-get install -y fontconfig
sudo fc-cache -f -v

sudo cp "$dotfiledir"/scripts/devcontainer-init.sh /etc/profile.d
