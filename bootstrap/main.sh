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

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      -n|--dry-run)
        export DRY_RUN=1
        ;;
      -h|--help)
        printf "Usage: %s [OPTIONS]\n\n" "$0"
        printf "Options:\n"
        printf "  -n, --dry-run    Simulate setup actions without modifying system or files\n"
        printf "  -h, --help       Show this help message\n"
        exit 0
        ;;
      *)
        die "Unknown argument: $arg"
        ;;
    esac
  done
}

install_rosetta_if_requested() {
  if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    info "Rosetta is already installed."
    return 0
  fi

  if confirm "Install Rosetta 2? Choose yes only if you need Intel-only apps."; then
    run /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  fi
}

run_macos_prefs_if_requested() {
  local script="$REPO_ROOT/Scripts/Prefs/setup-macos-prefs"
  [[ -x "$script" ]] || return 0

  if confirm "Apply baseline macOS preferences?"; then
    run "$script"
  fi
}

setup_github_push_if_requested() {
  if ! confirm "Authenticate with GitHub and make this dotfiles clone push-ready?"; then
    return 0
  fi

  run gh auth status || run gh auth login
  run git -C "$REPO_ROOT" remote set-url origin "$REPO_URL"
  run git -C "$REPO_ROOT" fetch origin
}

main() {
  parse_args "$@"

  local environment_label brewfile dock_plist

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if is_dry_run; then
    ui_header "danmunoz/dotfiles bootstrap (dry run)"
  else
    ui_header "danmunoz/dotfiles bootstrap"
  fi
  ensure_apple_silicon_macos
  ensure_command_line_tools
  ensure_sudo
  setup_homebrew
  install_bootstrap_bundle "$REPO_ROOT"

  environment_label="$(choose_one "Choose environment" "Personal" "Work" "Custom")" || die "No environment selected."
  case "$environment_label" in
    Personal)
      brewfile="$REPO_ROOT/Brewfile"
      dock_plist="$REPO_ROOT/Scripts/Prefs/com.apple.dock.plist"
      ;;
    Work)
      brewfile="$REPO_ROOT/work/Brewfile-work"
      dock_plist="$REPO_ROOT/work/com.apple.dock.plist"
      ;;
    Custom)
      setup_custom_brewfile "$REPO_ROOT" || die "Custom package configuration was aborted."
      brewfile="$CUSTOM_BREWFILE"
      dock_plist=""
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

  install_packages_for_environment "$environment_label" "$brewfile"

  install_oh_my_zsh_if_needed
  configure_xcode
  install_xcode_themes_if_requested "$REPO_ROOT"

  restore_dock_for_environment "$environment_label" "$dock_plist" "$REPO_ROOT"

  install_rosetta_if_requested
  run_macos_prefs_if_requested
  run_private_commands_if_present
  setup_github_push_if_requested

  if is_dry_run; then
    ui_header "Bootstrap complete (dry run)"
  else
    ui_header "Bootstrap complete"
  fi
  printf "\n"
  printf "%sDotfiles repo:%s    %s\n" "$CLR_DIM" "$CLR_RESET" "$REPO_ROOT"
  printf "%sManaged source:%s   %s\n" "$CLR_DIM" "$CLR_RESET" "$DOTFILES_SOURCE_DIR"
  printf "%sEdit aliases:%s     %s\n" "$CLR_DIM" "$CLR_RESET" "$DOTFILES_SOURCE_DIR/aliases"
  printf "%sCheck links:%s      ls -l ~/.zshrc ~/.zprofile ~/.gitconfig ~/.gitignore ~/.dotfiles\n" "$CLR_DIM" "$CLR_RESET"
  printf "%sRepo shell:%s       cd %s\n" "$CLR_DIM" "$CLR_RESET" "$REPO_ROOT"
}

main "$@"
