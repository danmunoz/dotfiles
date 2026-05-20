#!/usr/bin/env bash

ensure_real_directory() {
  local dir="$1"

  if [[ -d "$dir" && ! -L "$dir" ]]; then
    return 0
  fi

  if [[ -e "$dir" || -L "$dir" ]]; then
    if ! confirm "Replace $dir with a real directory for mixed managed and local dotfiles?"; then
      die "Cannot continue without a real directory at $dir."
    fi
    rm -rf "$dir"
  fi

  mkdir -p "$dir"
}

link_managed_file() {
  local source="$1"
  local target="$2"
  local parent_dir

  [[ -e "$source" ]] || die "Managed source file not found: $source"
  parent_dir="$(dirname "$target")"
  mkdir -p "$parent_dir"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    return 0
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if ! confirm "Replace $target with a symlink to $source?"; then
      warn "Keeping existing $target."
      return 0
    fi
    rm -rf "$target"
  fi

  ln -s "$source" "$target"
}

link_dotfiles() {
  local source_root="$1"

  ensure_real_directory "$HOME/.dotfiles"
  ensure_real_directory "$HOME/.dotfiles/scripts"

  link_managed_file "$source_root/zshrc" "$HOME/.zshrc"
  link_managed_file "$source_root/zprofile" "$HOME/.zprofile"
  link_managed_file "$source_root/gitconfig" "$HOME/.gitconfig"
  link_managed_file "$source_root/gitignore" "$HOME/.gitignore"
  link_managed_file "$source_root/aliases" "$HOME/.dotfiles/aliases"
  link_managed_file "$source_root/functions.zsh" "$HOME/.dotfiles/functions.zsh"
  link_managed_file "$source_root/scripts/reset-android-emulator" "$HOME/.dotfiles/scripts/reset-android-emulator"

  if [[ ! -e "$HOME/.dotfiles/extra" ]]; then
    info "Local file not found: $HOME/.dotfiles/extra"
    info "Use $source_root/extra.example as a starting point for private shell config."
  fi

  if [[ ! -e "$HOME/.dotfiles/run-once" ]]; then
    info "Local file not found: $HOME/.dotfiles/run-once"
    info "Use $source_root/run-once.example as a starting point for one-time private setup."
  fi
}

run_private_commands_if_present() {
  local script="$HOME/.dotfiles/run-once"

  [[ -f "$script" ]] || return 0
  [[ -x "$script" ]] || chmod u+x "$script"

  if confirm "Run local one-time setup from $script?"; then
    "$script"
  fi
}
