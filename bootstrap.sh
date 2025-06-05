#! /usr/bin/env bash

######################################################################
# 🍺 danmunoz/dotfiles | macOS Configuration Bootstrap              #
######################################################################
# This script automates the setup of a new macOS system, installing #
# Homebrew, essential packages, dotfiles, and system preferences.    #
# IMPORTANT: Review this script thoroughly before execution!         #
# Licensed under MIT (C) Daniel Munoz 2025 <https://danmunoz.com>    #
######################################################################

# Source the utility script for colored output
source "./Scripts/Utilities/print-color"

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration Variables ---
readonly PERSONAL_ENV=1
readonly WORK_ENV=2
environment=$PERSONAL_ENV
prompt_timeout=15 # Seconds to wait for user input
question_color=$yellow
start_time=$(date +%s)

# --- Helper Functions ---

# Prompts the user to review and edit the Brewfile.
function edit_brewfile() {
  local _response="y" # Default to 'y'
  print_question "\nDo you want to review and edit the Brewfile before proceeding with the installation? (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    local editor="${VISUAL-${EDITOR-nano}}"
    echo -en "📝  ${white}Opening Brewfile in ${editor}...${_reset}\n"
    if [ "$environment" -eq "$PERSONAL_ENV" ]; then
      "${editor}" Brewfile
    else
      "${editor}" work/Brewfile-work
    fi
  else
    printMessage "Skipping Brewfile review/edit."
  fi
}

# Installs or updates Homebrew.
function install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    # This prompt already defaults to proceeding if timeout occurs, as 'read' just pauses.
    print_question "\nHomebrew is not installed. Press any key to begin installation (installation will proceed automatically after $prompt_timeout seconds)..."
    read -t "$prompt_timeout" -n 1 -r || true # '|| true' prevents script from exiting if timeout occurs.
    echo ""

    printMessage "Installing Homebrew..."
    # Use NONINTERACTIVE=1 to prevent prompts during Homebrew installation
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    printMessage "Setting up Homebrew shell configuration..."
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    printMessage "Homebrew is already installed. Updating Homebrew and upgrading packages..."
    brew update
    brew upgrade
  fi
}

# Installs Xcode and related tools.
function install_xcode() {
  printMessage "Installing mas-cli for Mac App Store management..."
  brew install mas

  printMessage "Installing Xcode from the Mac App Store (may require Apple ID login)..."
  mas install 497799835 || printErrorMessage "Failed to install Xcode from Mac App Store. Please install manually if needed."

  printMessage "Setting xcode-select path to Xcode.app..."
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer || printErrorMessage "Failed to set xcode-select path. Ensure Xcode is installed."

  printMessage "Accepting Xcode's license agreement..."
  sudo xcodebuild -license accept || printErrorMessage "Failed to accept Xcode license. Please accept manually if prompted later."

  install_xcode_themes # Call to install Xcode themes
}

# Installs Rosetta 2.
function install_rosetta() {
  local _response="y" # Default to 'y'
  print_question "\nRosetta 2 is required for some Intel-based applications. Install it now? (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    printMessage "Installing Rosetta 2..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license || printErrorMessage "Failed to install Rosetta 2."
  else
    printMessage "Skipping Rosetta 2 installation."
  fi
}

# Installs Homebrew dependencies based on the Brewfile.
function install_homebrew_dependencies() {
  local _response="y" # Default to 'y'
  print_question "\nProceed with package installation via Brewfile? (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    printMessage "Installing Homebrew dependencies from Brewfile..."
    if [ "$environment" -eq "$PERSONAL_ENV" ]; then
      brew bundle
    else
      brew bundle --file=work/Brewfile-work
    fi
  else
    printMessage "Skipping Homebrew package installation."
  fi
}

# Copies the dotfiles directory to ~/.dotfiles.
function copy_dotfiles_dir() {
  local _response="y" # Default to 'y'
  print_question "\nDo you want to copy the .dotfiles directory to your home folder (~/.dotfiles)? (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    printMessage "Copying .dotfiles directory to $HOME/.dotfiles..."
    rsync --exclude ".git/" \
          --exclude ".DS_Store" \
          -avh --no-perms Scripts/dotfiles/ "$HOME/.dotfiles" || printErrorMessage "Failed to copy dotfiles."
  else
    printMessage "Skipping .dotfiles directory copy."
  fi
}

# Creates symbolic links for dotfiles.
function setup_symlinks() {
  local _response="y" # Default to 'y'
  print_question "\nDo you want to set up symbolic links for dotfiles?"
  print_question "NOTE: This operation will replace existing .zshrc, .zprofile, .gitconfig, and .gitignore files. (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    printMessage "Setting up symbolic links..."
    ln -sfn "$HOME/.dotfiles/zshrc" "$HOME/.zshrc" || printErrorMessage "Failed to link .zshrc"
    ln -sfn "$HOME/.dotfiles/zprofile" "$HOME/.zprofile" || printErrorMessage "Failed to link .zprofile"
    ln -sfn "$HOME/.dotfiles/gitconfig" "$HOME/.gitconfig" || printErrorMessage "Failed to link .gitconfig"
    ln -sfn "$HOME/.dotfiles/gitignore" "$HOME/.gitignore" || printErrorMessage "Failed to link .gitignore"
  else
    printMessage "Skipping symbolic link setup."
  fi
}

# Runs additional private setup commands from 'run-once' file (optional).
function run_private_commands() {
  if [ -f "Scripts/dotfiles/run-once" ]; then
    local _response="y" # Default to 'y'
    print_question "\nDo you want to run additional private setup commands from 'run-once'? (y/n) (Defaults to yes in $prompt_timeout seconds)"
    if read -t "$prompt_timeout" -n 1 -r _user_input; then
      _response="$_user_input"
      echo "" # Newline after user input
    else
      echo "" # Newline after timeout
      # _response remains "y"
    fi

    if [[ "$_response" =~ ^[Yy]$ ]]; then
      printMessage "Running private commands from Scripts/dotfiles/run-once..."
      chmod u+x Scripts/dotfiles/run-once
      echo -e "${BIBlue}Executing ${magenta}run-once${BIBlue} script.${_reset}"
      ./Scripts/dotfiles/run-once || printErrorMessage "Failed to execute 'run-once' script."
    else
      printMessage "Skipping private command execution."
    fi
  else
    printMessage "No 'run-once' script found. Skipping private commands."
  fi
}

# Installs Xcode themes.
function install_xcode_themes() {
  if [ -f "Scripts/XcodeThemes/install-xcode-themes" ]; then
    local _response="y" # Default to 'y'
    print_question "\nWould you like to install Xcode themes? (y/n) (Defaults to yes in $prompt_timeout seconds)"
    if read -t "$prompt_timeout" -n 1 -r _user_input; then
      _response="$_user_input"
      echo "" # Newline after user input
    else
      echo "" # Newline after timeout
      # _response remains "y"
    fi

    if [[ "$_response" =~ ^[Yy]$ ]]; then
      printMessage "Installing Xcode themes..."
      ./Scripts/XcodeThemes/install-xcode-themes || printErrorMessage "Failed to install Xcode themes."
    else
      printMessage "Skipping Xcode theme installation."
    fi
  else
    printMessage "Xcode themes installer not found. Skipping."
  fi
}

# Sets up macOS system preferences.
function setup_macos_prefs() {
  if [ -f "Scripts/Prefs/setup-macos-prefs" ]; then
    local _response="y" # Default to 'y'
    print_question "\nWould you like to apply your macOS system preferences? (y/n) (Defaults to yes in $prompt_timeout seconds)"
    if read -t "$prompt_timeout" -n 1 -r _user_input; then
      _response="$_user_input"
      echo "" # Newline after user input
    else
      echo "" # Newline after timeout
      # _response remains "y"
    fi

    if [[ "$_response" =~ ^[Yy]$ ]]; then
      printMessage "Setting up macOS Preferences..."
      ./Scripts/Prefs/setup-macos-prefs || printErrorMessage "Failed to set macOS preferences."
    else
      printMessage "Skipping macOS system preference setup."
    fi
  else
    printMessage "macOS preferences script not found. Skipping."
  fi
}

# Restores custom Dock configuration.
function restore_dock_config() {
  local _response="y" # Default to 'y'
  print_question "\nDo you want to restore your custom Dock configuration? (y/n) (Defaults to yes in $prompt_timeout seconds)"
  if read -t "$prompt_timeout" -n 1 -r _user_input; then
    _response="$_user_input"
    echo "" # Newline after user input
  else
    echo "" # Newline after timeout
    # _response remains "y"
  fi

  if [[ "$_response" =~ ^[Yy]$ ]]; then
    printMessage "Restoring the Dock configuration..."
    local dock_plist=""
    if [ "$environment" -eq "$PERSONAL_ENV" ]; then
      dock_plist="Scripts/Prefs/com.apple.dock.plist"
    else
      dock_plist="work/com.apple.dock.plist"
    fi

    if [ -f "$dock_plist" ]; then
      cp "$dock_plist" "$HOME/Library/Preferences/" || printErrorMessage "Failed to copy Dock plist."
      killall "Dock" && printMessage "Dock restarted successfully." || printErrorMessage "Failed to restart Dock."
    else
      printErrorMessage "Dock configuration file not found: $dock_plist"
    fi
  else
    printMessage "Skipping Dock configuration restoration."
  fi
}

# Installs Oh My Zsh.
function install_oh_my_zsh() {
  printMessage "Installing Oh My Zsh..."
  # Clean up previous Oh My Zsh installation if it exists
  if [ -d "$HOME/.oh-my-zsh" ]; then
    printMessage "Removing existing Oh My Zsh installation..."
    rm -rf "$HOME/.oh-my-zsh"
  fi
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || printErrorMessage "Failed to install Oh My Zsh."
}

# Checks for Full Disk Access for the Terminal application.
function check_full_disk_access() {
  printMessage "Verifying Full Disk Access for Terminal (recommended)..."
  # Note: This check using plutil on TimeMachine.plist might not be entirely reliable for
  # specifically checking Full Disk Access for the Terminal app. macOS security is granular.
  # A truly robust programmatic check is complex and often requires manual user intervention.
  if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null 2>&1; then
    printErrorMessage "This script requires your terminal application to have Full Disk Access."
    printErrorMessage "Please add your terminal app to the Full Disk Access list in:"
    printErrorMessage "System Settings > Privacy & Security > Full Disk Access"
    printErrorMessage "Then, restart your terminal and re-run this script."
    open /System/Library/PreferencePanes/Security.prefPane
    exit 1
  fi
  printMessage "Full Disk Access check passed (or not strictly verifiable, please ensure manually)."
}

# --- Main Functions ---

# The main installation process.
function start_installation() {
  printMessage "Starting macOS System Configuration..."
  check_full_disk_access

  # Ask for the administrator password upfront
  echo -e "${yellow2}This script will use ${magenta}sudo${_reset} for certain operations."
  echo -e "${yellow2}If prompted, please enter your password to authenticate.${_reset}"
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  printMessage "\n*** Choose Your Environment ***"
  echo "1. Personal"
  echo "2. Work"
  # This prompt is explicitly excluded from defaulting to "yes"
  print_question "Select your environment (1 or 2): "
  read -t "$prompt_timeout" -n 1 -r response
  echo "" # Newline for cleaner output

  case "$response" in
    "$PERSONAL_ENV")
      echo -e "\nProceeding with ${green}Personal${_reset} environment configuration."
      environment=$PERSONAL_ENV
      ;;
    "$WORK_ENV")
      echo -e "\nProceeding with ${cyan}Work${_reset} environment configuration."
      environment=$WORK_ENV
      ;;
    *)
      printErrorMessage "Invalid selection or timeout. Exiting script."
      cecho "Goodbye!" "$green"
      exit 1 # Exit with error code for invalid input or timeout
      ;;
  esac

  # --- Installation Steps ---
  install_homebrew
  install_xcode
  install_rosetta
  edit_brewfile # User interaction to edit Brewfile before bundle
  install_homebrew_dependencies
  install_oh_my_zsh
  copy_dotfiles_dir
  setup_symlinks
  setup_macos_prefs
  restore_dock_config
  run_private_commands

  # --- Completion Message ---
  cecho "\n*** macOS Configuration Complete! ***" "$green"
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ ${BIBlue}All tasks completed successfully in ${duration} seconds.${_reset}"
  cecho "Please note that some changes require a logout or system restart to take full effect." "$white"
  echo "It is recommended to restart your system now."
}

# Initial introduction and user confirmation.
function intro_prompt() {
  echo ""
  echo "=========================================================="
  echo "  🍺  danmunoz/dotfiles — macOS Configuration Bootstrap 🛠️"
  echo "=========================================================="
  echo ""

  echo -e "${red}    #############################################"
  echo "    #       DO NOT RUN THIS SCRIPT BLINDLY      #"
  echo "    #                                           #"
  echo "    #             READ IT THOROUGHLY            #"
  echo "    #        AND EDIT TO SUIT YOUR NEEDS        #"
  echo "    #############################################"
  echo ""

  echo -e "${white}This script will perform the following actions:${_reset}"
  echo "- Check for Homebrew installation, prompt to install/update if needed."
  echo "- Install Xcode and necessary developer tools."
  echo "- Optionally install Rosetta 2 for Intel-based applications."
  echo "- Allow you to review and edit the Brewfile before package installation."
  echo "- Install all packages and applications specified in the Brewfile."
  echo "- Install Oh My Zsh for enhanced shell capabilities."
  echo "- Copy your dotfiles to a dedicated directory (${HOME}/.dotfiles)."
  echo "- Create symbolic links for critical configuration files (.zshrc, .gitconfig, etc.)."
  echo "- Apply your custom macOS system preferences."
  echo "- Restore your personalized Dock configuration."
  echo "- Optionally run a 'run-once' script for additional private commands."
  echo "- Provide a summary of the installation and execution time."
  echo ""

  if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    start_installation
  else
    local _response="y" # Default to 'y'
    cecho "This script may overwrite existing files in your home directory." "$question_color"
    cecho "Do you want to continue? (y/n) (Defaults to yes in $prompt_timeout seconds) " "$question_color"
    if read -t "$prompt_timeout" -n 1 -r _user_input; then
      _response="$_user_input"
      echo "" # Newline after user input
    else
      echo "" # Newline after timeout
      # _response remains "y"
    fi

    if [[ "$_response" =~ ^([Yy][eE][sS]|[yY])$ ]]; then
      start_installation
    else
      cecho "Installation cancelled. Goodbye!" "$green"
    fi
  fi
}

# Start the script with the introduction prompt.
intro_prompt "$@"