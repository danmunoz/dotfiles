#! /usr/bin/env bash
source ./Scripts/Utilities/print-color

set -e

# Installs Homebrew or updates it if it was already installed
function installHomebrew() {
  if ! command -v brew >/dev/null; then
    printMessage "*** Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  else
    printMessage "*** Homebrew already installed, updating"
    brew update
  fi
}

# Install Xcode
function installXcode() {
  printMessage "*** Installing mas-cli"
  brew install mas
  printMessage "*** Installing Xcode from Mac App Store"
  mas install 497799835
  printMessage "*** Setting xcode-select to Xcode.app"
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  printMessage "*** Accepting xcodebuild's license"
  sudo xcodebuild -license accept 
}

# Install Homebrew dependencies
function installHomebrewDependencies() {
  printMessage "*** Installing Homebrew dependencies"
  brew bundle
}

function copyDotfilesDir() {
  setupGitConfig;
  printMessage "*** Copying .dotfiles dir"
	 rsync --exclude ".git/" \
	 	--exclude ".DS_Store" \
	 	-avh --no-perms Scripts/dotfiles/ ~/.dotfiles;
}

function setupSimLinks() {
  printMessage "*** Setting up SymLinks"
  
  read -p "This operation will replace existing zshrc and gitconfig files. Do you wish to continue? (y/n) " -n 1
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -sfn $HOME/.dotfiles/zshrc $HOME/.zshrc
    ln -sfn $HOME/.dotfiles/gitconfig $HOME/.gitconfig
  fi
}

# Install Xcode themes
function installXcodeThemes() {
  ./Scripts/XcodeThemes/install-xcode-themes
}

# Setup macOS Preferences
function setupPrefs() {
  ./Scripts/Prefs/setup-macos-prefs
}

# Restore Dock Elements
function restoreDock() {
  printMessage "*** Restoring the Dock elements"
  cp Scripts/Prefs/com.apple.dock.plist ~/Library/Preferences/
  killall "Dock"
}

function installOhMyZsh() {
  printMessage "*** Installing Oh-my-zsh"
  rm -rf ~/.oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

function setupGitConfig() {
  printMessage "*** Creating basic .gitconfig file"
  read -p 'Name: ' namevar
  read -p 'Email: ' emailvar
  echo "[user]
	name = $namevar
	email = $emailvar
[mergetool]
	keepBackup = true
[core]
	filemode = false" > Scripts/dotfiles/gitconfig
}

function checkFullDiskAccess() {
  if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null ; then
  printErrorMessage "This script requires your terminal app to have Full Disk Access."
  printErrorMessage "Add this terminal to the Full Disk Access list in \nSystem Preferences > Security & Privacy, quit the app, and re-run this script."
  open /System/Library/PreferencePanes/Security.prefPane
  exit 1
fi
}

function start() {
  printMessage "*** Setting up your Computer..."
  checkFullDiskAccess

  # Ask for the administrator password upfront
  echo -e "${BIBlue}This script will use ${magenta}sudo${_reset} ${BIBlue}enter your password to authenticate if prompted.${_reset}"
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until `.setup` has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  installHomebrew
  installXcode
  installHomebrewDependencies
  installOhMyZsh
  copyDotfilesDir
  setupSimLinks
  installXcodeThemes
  setupPrefs
  restoreDock
  cecho "*** Finished." $green
  cecho "macOS configuration complete." $white
  cecho "Note that some of these changes require a logout/restart to take effect." $white
  echo "Please restart the system."
}

# Initial prompt (Inspired by @cdzombak)
echo ""
echo "   ------                           ------"
echo "   ------    macOS Configuration    ------"
echo "   ------                           ------"
echo ""

cecho "#############################################" $red
cecho "#       DO NOT RUN THIS SCRIPT BLINDLY      #" $red
cecho "#                                           #" $red
cecho "#             READ IT THOROUGHLY            #" $red
cecho "#        AND EDIT TO SUIT YOUR NEEDS        #" $red
cecho "#############################################" $red
echo ""

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	start
else
  cecho "This may overwrite existing files in your home directory. Do you want to continue? (y/n) " $white
  read -r response
	if [[ $response =~ ^([Yy][eE][sS]|[yY])$ ]]; then
		start
	fi
fi
