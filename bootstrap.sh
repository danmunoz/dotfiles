#! /usr/bin/env bash
source ./Scripts/Utilities/print-color

set -e

# Install or update Homebrew
function installHomebrew() {
  if ! command -v brew >/dev/null; then
    printMessage "*** Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    printMessage "*** Setting up Homebrew shell configuration"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    printMessage "*** Homebrew already installed, updating"
    brew update
  fi
}

# Install Xcode
# Installs mas-cli if needed
# Installs Xcode from the Mac App Store
# Sets xcode-select to Xcode's path
# Accepts xcodebuild's license
function installXcode() {
  printMessage "*** Installing mas-cli"
  brew install mas
  printMessage "*** Installing Xcode from Mac App Store"
  mas install 497799835
  printMessage "*** Setting xcode-select to Xcode.app"
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  printMessage "*** Accepting xcodebuild's license"
  sudo xcodebuild -license accept
  installXcodeThemes
}

# Installs Rosetta 2
function installRosetta() {
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
}

# Install Homebrew dependencies
# Based on the Brewfile configuration
function installHomebrewDependencies() {
  printMessage "*** Installing Homebrew dependencies"
  brew bundle
}

# Copy Dotfiles
# Copies the dotfiles directory into ~/.dotfiles
function copyDotfilesDir() {
  printMessage "*** Copying .dotfiles dir"
	 rsync --exclude ".git/" \
	 	--exclude ".DS_Store" \
	 	-avh --no-perms Scripts/dotfiles/ ~/.dotfiles;
}

# Setup Symbolic Links
# Creates Symbolic links for dotfiles
function setupSymLinks() {
  printMessage "*** Setting up SymLinks"
  
  read -p "This operation will replace existing .zshrc, .zprofile, .gitconfig and .gitignore files. Do you wish to continue? (y/n) " -n 1
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -sfn $HOME/.dotfiles/zshrc $HOME/.zshrc
    ln -sfn $HOME/.dotfiles/zprofile $HOME/.zprofile
    ln -sfn $HOME/.dotfiles/gitconfig $HOME/.gitconfig
    ln -sfn $HOME/.dotfiles/gitignore $HOME/.gitignore
  fi
}

# Runs commands passed on the run-once file (Optional)
function runPrivateCommands() {
  printMessage "*** Running private commands"
  echo -e "${BIBlue}Running ${magenta}run-once${BIBlue} script.${_reset}"
  sudo chmod u+x Scripts/dotfiles/run-once
  ./Scripts/dotfiles/run-once
}

# Install Xcode themes
function installXcodeThemes() {
  printMessage "*** Installing Xcode themes"
  ./Scripts/XcodeThemes/install-xcode-themes
}

# Setup macOS Preferences
function setupPrefs() {
  printMessage "*** Setting up macOS Preferences"
  ./Scripts/Prefs/setup-macos-prefs
}

# Restore Dock Configuration
function restoreDock() {
  printMessage "*** Restoring the Dock configuration"
  cp Scripts/Prefs/com.apple.dock.plist ~/Library/Preferences/
  killall "Dock"
}

# Installs Oh My Zsh 
function installOhMyZsh() {
  printMessage "*** Installing Oh-my-zsh"
  rm -rf ~/.oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# Checks Full Disk Access for Terminal
function checkFullDiskAccess() {
  if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null ; then
  printErrorMessage "This script requires your terminal app to have Full Disk Access."
  printErrorMessage "Add this terminal to the Full Disk Access list in:\nSystem Settings > Privacy & Security > Full Disk Access\nThen, restart the terminal and re-run this script."
  open /System/Library/PreferencePanes/Security.prefPane
  exit 1
fi
}

# Main Function
function start() {
  printMessage "*** Setting up your Computer..."
  checkFullDiskAccess

  # Ask for the administrator password upfront
  echo -e "${BIBlue}This script will use ${magenta}sudo${_reset}"
  echo -e "${BIBlue}If prompted, please enter your password to authenticate.${_reset}"
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until `.setup` has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  installHomebrew
  installXcode
  installRosetta
  installHomebrewDependencies
  installOhMyZsh
  copyDotfilesDir
  setupSymLinks
  setupPrefs
  restoreDock
  runPrivateCommands
  cecho "*** Finished." $green
  cecho "macOS configuration complete." $white
  cecho "Note that some of these changes require a logout/restart to take effect." $white
  echo "Please restart the system."
}

# Initial prompt
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
  cecho "This may overwrite existing files in your home directory." $white
  cecho "Do you want to continue? (y/n) " $white
  read -r response
	if [[ $response =~ ^([Yy][eE][sS]|[yY])$ ]]; then
		start
  else
    cecho "Goodbye!" $green
	fi
fi
