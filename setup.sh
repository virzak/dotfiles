mkdir -p /home/vscode/.local/bin

INSTALL_DIR=$([ "$(id -u)" -eq 0 ] && echo /usr/local/bin || echo "$HOME/.local/bin")
SHARE_DIR=$([ "$(id -u)" -eq 0 ] && echo /usr/local/share || echo "$HOME/.local/share")

DIFFT_VERSION="0.67.0"
if [ ! -f $INSTALL_DIR/difft ]; then
  echo "installing difftastic ${DIFFT_VERSION}"
  curl -Lo /tmp/difft.tar.gz https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz
  tar xvf /tmp/difft.tar.gz --directory $INSTALL_DIR
fi

curl -s https://ohmyposh.dev/install.sh | bash -s -- -d $INSTALL_DIR

# Ensure everyone can use docker if available
if [ -S /var/run/docker.sock ]; then
  echo "Changing /var/run/docker.sock permissions"
  sudo chmod 666 /var/run/docker.sock
else
  echo "/var/run/docker.sock not available"
fi

# Allow act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | BINDIR=$INSTALL_DIR bash

echo 'eval "$(oh-my-posh --init --shell bash --config ~/.vityusha-ohmyposhv3-v2.json)"' >>~/.bashrc

# Fonts
mkdir -p $SHARE_DIR/fonts
curl -Lo /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
unzip -f /tmp/Meslo.zip -d $SHARE_DIR/fonts
rm /tmp/Meslo.zip

pathToCheck="$HOME/dotfiles"

if [ -d "$pathToCheck" ]; then
  dotFilesDir="$pathToCheck"
else
  dotFilesDir="$PWD"
fi


mkdir -p $HOME/.config/Code/User
ln -sfv $dotFilesDir/settings.json ~/.vscode-remote/data/Machine/settings.json
ln -sfv $dotFilesDir/.actrc ~/.actrc
ln -sfv $dotFilesDir/.gitconfig ~/.gitconfig
ln -sfv $dotFilesDir/.vityusha-ohmyposhv3-v2.json ~/.vityusha-ohmyposhv3-v2.json
ln -sfv $dotFilesDir/difftool.sh ~/difftool.sh
ln -sfv $dotFilesDir/gitconflict.sh ~/gitconflict.sh
mkdir -p ~/.config/git
ln -sfv $dotFilesDir/.config/git/ignore ~/.config/git/ignore

# dotnet tools
#dotnet tool install dotnet-outdated-tool --global --ignore-failed-sources
#dotnet tool install dotnet-ef --global --ignore-failed-sources

if command -v node >/dev/null 2>&1 && command -v yarn >/dev/null 2>&1; then
  # yarn tools
  yarn global add npm-check-updates
fi
