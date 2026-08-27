mkdir -p "$HOME/.local/bin"

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

# Container images tend to set PATH explicitly, which beats the ~/.profile logic that
# would otherwise add ~/.local/bin. Put INSTALL_DIR on PATH before anything needs it.
echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >>~/.bashrc

echo 'eval "$(oh-my-posh --init --shell bash --config ~/.vityusha-ohmyposhv3-v2.json)"' >>~/.bashrc

# Fonts
mkdir -p $SHARE_DIR/fonts
curl -Lo /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
unzip -o /tmp/Meslo.zip -d $SHARE_DIR/fonts
rm /tmp/Meslo.zip

curl -Lo "/tmp/Ubuntu Mono derivative Powerline.ttf" https://github.com/powerline/fonts/raw/master/UbuntuMono/Ubuntu%20Mono%20derivative%20Powerline.ttf
mv "/tmp/Ubuntu Mono derivative Powerline.ttf" $SHARE_DIR/fonts

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
ln -sfv $dotFilesDir/.inputrc ~/.inputrc
ln -sfv $dotFilesDir/.vityusha-ohmyposhv3-v2.json ~/.vityusha-ohmyposhv3-v2.json
ln -sfv $dotFilesDir/difftool.sh ~/difftool.sh
ln -sfv $dotFilesDir/gitconflict.sh ~/gitconflict.sh
mkdir -p ~/.config/git
ln -sfv $dotFilesDir/.config/git/ignore ~/.config/git/ignore

# dotnet tools
#dotnet tool install dotnet-outdated-tool --global --ignore-failed-sources
#dotnet tool install dotnet-ef --global --ignore-failed-sources

# Global CLI tools. Use npm, not yarn/pnpm: npm's global bin dir is already on
# PATH in this image (yarn's ~/.yarn/bin is not, and pnpm needs a `pnpm setup`
# bootstrap first), and npm's resolver honours "engines" so it picks the newest
# ncu the installed Node actually supports instead of failing outright.
if command -v npm >/dev/null 2>&1; then
  npm install -g npm-check-updates
fi

# Claude Code (native installer, lands in ~/.local/bin)
if ! command -v claude >/dev/null 2>&1; then
  echo "installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
