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

# Build latest mosh release, to play nice with Neovim colors
echo "Install mosh...\n"
sudo apt-get install -y libtinfo-dev libssl-dev libprotobuf-dev protobuf-compiler
cd /home/vscode
curl -OL https://github.com/mobile-shell/mosh/releases/download/mosh-1.3.2.95rc1/mosh-1.3.2.95rc1.tar.gz
tar -xzf mosh-1.3.2.95rc1.tar.gz    
rm mosh-1.3.2.95rc1.tar.gz                        
cd mosh-1.3.2.95rc1                              
./configure && make && sudo make install
make clean
echo "done"

echo "Installing clj-kondo...\n"
cd /usr/local
sudo curl -sLO https://raw.githubusercontent.com/clj-kondo/clj-kondo/master/script/install-clj-kondo
sudo chmod +x install-clj-kondo
sudo ./install-clj-kondo
echo "done"

echo "installing lsp-clojure...\n"
sudo curl -OL https://github.com/clojure-lsp/clojure-lsp/releases/download/2022.09.01-15.27.31/clojure-lsp-native-linux-amd64.zip
sudo unzip clojure-lsp-native-linux-amd64.zip -d /usr/local/bin          
sudo rm clojure-lsp-native-linux-amd64.zip             
echo "done"

# Install latest neovim to play nice with Treesitter
echo "installing neovim...\n"
cd /home/vscode
curl -OL https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.deb
sudo apt-get install ./nvim-linux64.deb
rm nvim-linux64.deb
echo "done"

echo "Setup neovim as clojure IDE...\n"
cd /home/vscode
sudo apt-get install -y tmux ripgrep 
git clone https://github.com/Olical/magic-kit.git /home/vscode/.config/nvim
cd /home/vscode/.config/nvim/fnl/magic/plugin
curl -OL https://raw.githubusercontent.com/rafaeldelboni/nvim-fennel-lsp-conjure-as-clojure-ide/main/.config/nvim/fnl/config/plugin/treesitter.fnl
cd ..
sed -i '$i\  nvim-treesitter/nvim-treesitter {:mod treesitter :run ":TSUpdate"}' init.fnl
/home/vscode/.config/nvim/script/sync.sh
echo "done"

echo "Installing emacs...\n"
cd /home/vscode
# curl -L http://emacs.ganneff.de/apt.key | sudo apt-key add -
# sudo add-apt-repository "deb http://emacs.ganneff.de/ buster main"
# sudo apt-get update
# sudo apt-get install -y emacs-snapshot fd-find
sudo apt-get install -y emacs fd-find
git clone https://github.com/hlissner/doom-emacs /home/vscode/.emacs.d
/home/vscode/.emacs.d/bin/doom install --force
echo 'export PATH=$HOME/.emacs.d/bin:$PATH' >> /home/vscode/.profile
mkdir -p /home/vscode/.local/bin
sed -i 's/;;lispy/lispy/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;eshell/eshell/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;vterm/vterm/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;(spell +flyspell)/(spell +flyspell)/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;lsp/lsp/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;clojure/(clojure +lsp)/g' /home/vscode/.doom.d/init.el 
echo 'mkdir /tmp/emacs1000' >> /home/vscode/.local/bin/e
echo 'chmod 700 /tmp/emacs1000/' >> /home/vscode/.local/bin/e
echo 'emacsclient -c -a ""' >> /home/vscode/.local/bin/e
chmod +x /home/vscode/.local/bin/e

echo "Installing Acme...\n"
sudo apt-get install -y libx11-dev libfreetype6-dev libfontconfig1-dev libxext-dev libxt-dev
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
