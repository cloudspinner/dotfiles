#!/usr/bin/env bash
dotfiledir="$(dirname "$(realpath "$0")")"
echo "dotfiles in $dotfiledir"

sudo apt-get update

<<vnc-comment
echo "Installing VNC...\n"
sudo bash "$dotfiledir"/scripts/desktop-lite-debian.sh # todo: use curl to get script?
echo "done"

vnc-comment

# Build latest mosh release, to play nice with Neovim colors
echo "Install mosh...\n"
sudo apt-get install -y libtinfo-dev libssl-dev libprotobuf-dev protobuf-compiler pkg-config
cd /home/vscode
MOSHFILE=mosh-1.4.0
curl -OL https://mosh.org/${MOSHFILE}.tar.gz
tar -xzf ${MOSHFILE}.tar.gz    
rm ${MOSHFILE}.tar.gz                        
cd ${MOSHFILE}                              
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

# Install tmux
echo "installing tmux...\n"
sudo apt-get install -y tmux
echo "set -g default-terminal \"screen-256color\"" >> /home/vscode/.tmux.conf
echo "set -s escape-time 0" >> /home/vscode/.tmux.conf
echo "set -g base-index 1" >> /home/vscode/.tmux.conf
echo "bind-key C-\\\\ last-window" >> /home/vscode/.tmux.conf
echo "" >> /home/vscode/.tmux.conf
echo "# Change prefix to C-\\" >> /home/vscode/.tmux.conf
echo "unbind C-b" >> /home/vscode/.tmux.conf
echo "set-option -g prefix C-\\\\" >> /home/vscode/.tmux.conf

<<neovim-comment
# Install latest neovim to play nice with Treesitter
echo "installing neovim...\n"
cd /home/vscode
curl -OL https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.deb
sudo apt-get install ./nvim-linux64.deb
rm nvim-linux64.deb
echo "done"

echo "Setup neovim as clojure IDE...\n"
cd /home/vscode
sudo apt-get install -y ripgrep 
git clone https://github.com/Olical/magic-kit.git /home/vscode/.config/nvim
cd /home/vscode/.config/nvim/fnl/magic/plugin
curl -OL https://raw.githubusercontent.com/rafaeldelboni/nvim-fennel-lsp-conjure-as-clojure-ide/main/.config/nvim/fnl/config/plugin/treesitter.fnl
cd ..
sed -i '$i\  nvim-treesitter/nvim-treesitter {:mod treesitter :run ":TSUpdate"}' init.fnl
/home/vscode/.config/nvim/script/sync.sh
echo "done"

neovim-comment

echo "Installing emacs...\n"
cd /home/vscode
# curl -L http://emacs.ganneff.de/apt.key | sudo apt-key add -
# sudo add-apt-repository "deb http://emacs.ganneff.de/ buster main"
# sudo apt-get update
# sudo apt-get install -y emacs-snapshot fd-find cmake libtool-bin
sudo apt-get install -y emacs fd-find cmake libtool-bin ripgrep
git clone https://github.com/hlissner/doom-emacs /home/vscode/.emacs.d
echo "Installing Doom...\n"
# So we don't have to write ~/.emacs.d/bin/doom every time
PATH="/home/vscode/.emacs.d/bin:$PATH"

# Create a directory for our private config
mkdir /home/vscode/.doom.d  # or ~/.config/doom

# The init.example.el file contains an example doom! call, which tells Doom what
# modules to load and in what order.
cp /home/vscode/.emacs.d/templates/init.example.el /home/vscode/.doom.d/init.el
cp /home/vscode/.emacs.d/templates/config.example.el /home/vscode/.doom.d/config.el
cp /home/vscode/.emacs.d/templates/packages.example.el /home/vscode/.doom.d/packages.el

# You might want to edit ~/.doom.d/init.el here and make sure you only have the
# modules you want enabled.
# sed -i 's/;;lispy/lispy/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;eshell/eshell/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;vterm/vterm/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;(spell +flyspell)/(spell +flyspell)/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;lsp/lsp/g' /home/vscode/.doom.d/init.el 
sed -i 's/;;clojure/(clojure +lsp)/g' /home/vscode/.doom.d/init.el 

# Then synchronize Doom with your config:
# doom sync

# If you know Emacs won't be launched from your shell environment (e.g. you're
# on macOS or use an app launcher that doesn't launch programs with the correct
# shell) then create an envvar file to ensure Doom correctly inherits your shell
# environment.
#
# If you don't know whether you need this or not, there's no harm in doing it
# anyway. `doom install` will have prompted you to generate one. If you
# responded no, you can generate it later with the following command:
# doom env

cat << EOF >> /home/vscode/.doom.d/packages.el
(package! evil-paredit)
EOF

cat << EOF >> /home/vscode/.doom.d/config.el
(add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode)                                                                                                              
(add-hook 'emacs-lisp-mode-hook #'evil-paredit-mode)                                                                                                                
(add-hook 'clojure-mode-hook #'enable-paredit-mode)                                                                                                                 
(add-hook 'clojure-mode-hook #'evil-paredit-mode)
(after! cider
  (setq cider-clojure-cli-aliases ":dev"))
EOF

# Lastly, install the icon fonts Doom uses:
emacs --batch -f all-the-icons-install-fonts
# On Windows, `all-the-icons-install-fonts` will only download the fonts, you'll
# have to install them by hand afterwards!

echo 'export PATH=$HOME/.emacs.d/bin:$PATH' >> /home/vscode/.profile
mkdir -p /home/vscode/.local/bin
echo 'mkdir /tmp/emacs1000' >> /home/vscode/.local/bin/e
echo 'chmod 700 /tmp/emacs1000/' >> /home/vscode/.local/bin/e
echo '# emacsclient -c -a ""' >> /home/vscode/.local/bin/e
echo 'emacs' >> /home/vscode/.local/bin/e
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

echo "Authenticating Tailscale...\n"
sudo tailscale up --accept-routes
