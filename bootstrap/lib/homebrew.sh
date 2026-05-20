#!/usr/bin/env bash

setup_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    die "Homebrew was not found at /opt/homebrew/bin/brew."
  fi
}

install_bootstrap_bundle() {
  local repo_root="$1"
  brew bundle --file="$repo_root/bootstrap/Brewfile.bootstrap"
}

install_environment_bundle() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || die "Brewfile not found: $brewfile"
  brew bundle --file="$brewfile"
}

install_oh_my_zsh_if_needed() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "Oh My Zsh already exists; leaving it untouched."
    return 0
  fi

  info "Installing Oh My Zsh."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}
