#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="https://github.com/danmunoz/dotfiles.git"
DOTFILES_SOURCE_DIR="$REPO_ROOT/Scripts/dotfiles"

source "$REPO_ROOT/bootstrap/lib/ui.sh"
source "$REPO_ROOT/bootstrap/lib/checks.sh"
source "$REPO_ROOT/bootstrap/lib/homebrew.sh"
source "$REPO_ROOT/bootstrap/lib/xcode.sh"
source "$REPO_ROOT/bootstrap/lib/dock.sh"
source "$REPO_ROOT/bootstrap/lib/dotfiles.sh"

install_rosetta_if_requested() {
  if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    info "Rosetta is already installed."
    return 0
  fi

  if confirm "Install Rosetta 2? Choose yes only if you need Intel-only apps."; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  fi
}

run_macos_prefs_if_requested() {
  local script="$REPO_ROOT/Scripts/Prefs/setup-macos-prefs"
  [[ -x "$script" ]] || return 0

  if confirm "Apply baseline macOS preferences?"; then
    "$script"
  fi
}

setup_github_push_if_requested() {
  if ! confirm "Authenticate with GitHub and make this dotfiles clone push-ready?"; then
    return 0
  fi

  gh auth status || gh auth login
  git -C "$REPO_ROOT" remote set-url origin "$REPO_URL"
  git -C "$REPO_ROOT" fetch origin
}

main() {
  local environment_label brewfile dock_plist

  ui_header "danmunoz/dotfiles bootstrap"
  ensure_apple_silicon_macos
  ensure_command_line_tools
  ensure_sudo
  setup_homebrew

  environment_label="$(choose_one "Choose environment" "Personal" "Work")" || die "No environment selected."
  case "$environment_label" in
    Personal)
      brewfile="$REPO_ROOT/Brewfile"
      dock_plist="$REPO_ROOT/Scripts/Prefs/com.apple.dock.plist"
      ;;
    Work)
      brewfile="$REPO_ROOT/work/Brewfile-work"
      dock_plist="$REPO_ROOT/work/com.apple.dock.plist"
      ;;
    *)
      die "Unknown environment: $environment_label"
      ;;
  esac

  if confirm "Install or update direct symlinks for managed dotfiles?"; then
    link_dotfiles "$DOTFILES_SOURCE_DIR"
  else
    die "Dotfile linking was skipped by user."
  fi

  if confirm "Install Homebrew packages for $environment_label?"; then
    install_environment_bundle "$brewfile"
  fi

  install_oh_my_zsh_if_needed
  configure_xcode
  install_xcode_themes_if_requested "$REPO_ROOT"

  if confirm "Restore $environment_label Dock layout? This overwrites the current Dock."; then
    restore_dock "$dock_plist"
  fi

  install_rosetta_if_requested
  run_macos_prefs_if_requested
  run_private_commands_if_present
  setup_github_push_if_requested

  ui_header "Bootstrap complete"
  printf "Dotfiles repo:    %s\n" "$REPO_ROOT"
  printf "Managed source:   %s\n" "$DOTFILES_SOURCE_DIR"
  printf "Edit aliases:     %s\n" "$DOTFILES_SOURCE_DIR/aliases"
  printf "Check links:      ls -l ~/.zshrc ~/.zprofile ~/.gitconfig ~/.gitignore ~/.dotfiles\n"
  printf "Repo shell:       cd %s\n" "$REPO_ROOT"
}

main "$@"
