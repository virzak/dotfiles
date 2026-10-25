mkdir -p "$HOME/.local/bin"

INSTALL_DIR=$([ "$(id -u)" -eq 0 ] && echo /usr/local/bin || echo "$HOME/.local/bin")
SHARE_DIR=$([ "$(id -u)" -eq 0 ] && echo /usr/local/share || echo "$HOME/.local/share")

# Termux runs this inside its proot Debian (where pwsh lives); ~ there is Termux's own home.
# /data/data/com.termux is visible both natively and inside proot.
IS_TERMUX=$([ -d /data/data/com.termux ] && echo 1)

DIFFT_VERSION="0.67.0"
if [ ! -f $INSTALL_DIR/difft ]; then
  echo "installing difftastic ${DIFFT_VERSION}"
  curl -Lo /tmp/difft.tar.gz https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}/difft-$(uname -m)-unknown-linux-gnu.tar.gz
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
# Termux's bash can't run the Debian binaries in INSTALL_DIR, so leave its ~/.bashrc alone there.
add_to_bashrc() { grep -qxF "$1" ~/.bashrc 2>/dev/null || echo "$1" >>~/.bashrc; }
if [ -z "$IS_TERMUX" ]; then
  add_to_bashrc "export PATH=\"$INSTALL_DIR:\$PATH\""
  add_to_bashrc 'eval "$(oh-my-posh --init --shell bash --config ~/.vityusha-ohmyposhv3-v2.json)"'
fi

# Fonts. Termux reads exactly one font, ~/.termux/font.ttf; keep a custom one if present.
if [ -n "$IS_TERMUX" ]; then
  if [ ! -f ~/.termux/font.ttf ]; then
    mkdir -p ~/.termux
    curl -Lo /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
    unzip -o -j /tmp/Meslo.zip MesloLGMNerdFont-Regular.ttf -d /tmp
    mv /tmp/MesloLGMNerdFont-Regular.ttf ~/.termux/font.ttf
    rm /tmp/Meslo.zip
  fi
else
  mkdir -p $SHARE_DIR/fonts
  curl -Lo /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
  unzip -o /tmp/Meslo.zip -d $SHARE_DIR/fonts
  rm /tmp/Meslo.zip

  curl -Lo "/tmp/Ubuntu Mono derivative Powerline.ttf" https://github.com/powerline/fonts/raw/master/UbuntuMono/Ubuntu%20Mono%20derivative%20Powerline.ttf
  mv "/tmp/Ubuntu Mono derivative Powerline.ttf" $SHARE_DIR/fonts
fi

pathToCheck="$HOME/dotfiles"

if [ -d "$pathToCheck" ]; then
  dotFilesDir="$pathToCheck"
else
  dotFilesDir="$PWD"
fi

# Relative links (-r) so they resolve from Termux too, where proot's /root is Termux's home.
mkdir -p $HOME/.config/Code/User
ln -srfv $dotFilesDir/settings.json ~/.vscode-remote/data/Machine/settings.json
ln -srfv $dotFilesDir/.actrc ~/.actrc
ln -srfv $dotFilesDir/.gitconfig ~/.gitconfig
ln -srfv $dotFilesDir/.inputrc ~/.inputrc
ln -srfv $dotFilesDir/.vityusha-ohmyposhv3-v2.json ~/.vityusha-ohmyposhv3-v2.json
ln -srfv $dotFilesDir/difftool.sh ~/difftool.sh
ln -srfv $dotFilesDir/gitconflict.sh ~/gitconflict.sh
mkdir -p ~/.config/git
ln -srfv $dotFilesDir/.config/git/ignore ~/.config/git/ignore
# pwsh reads $PROFILE from ~/.config/powershell on Linux
mkdir -p ~/.config/powershell
ln -srfv $dotFilesDir/Microsoft.PowerShell_profile.ps1 ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# The profile imports Terminal-Icons when present.
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -c 'if (-not (Get-Module -ListAvailable Terminal-Icons)) { Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module Terminal-Icons -Scope CurrentUser }'
fi

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

# Claude Code (native installer, lands in ~/.local/bin). Not under Termux's proot.
if [ -z "$IS_TERMUX" ] && ! command -v claude >/dev/null 2>&1; then
  echo "installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
