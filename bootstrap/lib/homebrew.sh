#!/usr/bin/env bash

setup_homebrew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Homebrew is already installed."
    return 0
  fi

  info "Installing Homebrew (unattended)."
  run env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif ! is_dry_run; then
    die "Homebrew was not found at /opt/homebrew/bin/brew."
  fi
}

install_bootstrap_bundle() {
  local repo_root="$1"
  if ! command -v gum >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    info "Installing bootstrap tools from bootstrap/Brewfile.bootstrap."
    brew bundle --file="$repo_root/bootstrap/Brewfile.bootstrap"
  else
    run brew bundle --file="$repo_root/bootstrap/Brewfile.bootstrap"
  fi
}

install_environment_bundle() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || die "Brewfile not found: $brewfile"
  run brew bundle --file="$brewfile"
}

custom_brewfile_has_packages() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || return 1
  grep -q -E '^[[:space:]]*(brew|cask|mas|vscode)[[:space:]]' "$brewfile"
}

parse_brewfile_catalog() {
  local line label
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* || "$line" == cask_args* || "$line" == "brew \"mas\"" ]] && continue

    if [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\" ]]; then
      label="${BASH_REMATCH[1]} (mas)"
      printf "%s\t%s\n" "$label" "$line"
    elif [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
      label="${BASH_REMATCH[1]} (cask)"
      printf "%s\t%s\n" "$label" "$line"
    elif [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
      label="${BASH_REMATCH[1]} (brew)"
      printf "%s\t%s\n" "$label" "$line"
    elif [[ "$line" =~ ^vscode[[:space:]]+\"([^\"]+)\" ]]; then
      label="${BASH_REMATCH[1]} (vscode)"
      printf "%s\t%s\n" "$label" "$line"
    fi
  done < <(cat "$@")
}

setup_custom_brewfile() {
  local repo_root="$1"
  local catalog_file selected_file
  catalog_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles_catalog.XXXXXX")"
  selected_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles_selected.XXXXXX")"

  parse_brewfile_catalog "$repo_root/Brewfile" "$repo_root/work/Brewfile-work" | sort -f | awk -F"\t" '!seen[$1]++' > "$catalog_file"

  local -a labels=()
  local label
  while IFS=$'\t' read -r label _; do
    [[ -n "$label" ]] && labels+=("$label")
  done < "$catalog_file"

  while true; do
    > "$selected_file"
    if ! choose_multiple "Select dependencies to install" "${labels[@]}" > "$selected_file"; then
      rm -f "$catalog_file" "$selected_file"
      warn "Custom dependency selection was cancelled."
      return 1
    fi

    local count
    count="$(grep -c -v '^[[:space:]]*$' "$selected_file" || true)"

    if (( count == 0 )); then
      warn "No dependencies were selected."
      if confirm "Proceed without installing any packages?"; then
        break
      fi
      continue
    fi

    printf "\n%sSelected dependencies (%d):%s\n" "$CLR_BOLD" "$count" "$CLR_RESET"
    while IFS= read -r item; do
      [[ -n "$item" ]] && printf "  %s•%s %s\n" "$CLR_CYAN" "$CLR_RESET" "$item"
    done < "$selected_file"

    if confirm "Install only these $count selected dependencies?"; then
      break
    fi

    if ! confirm "Would you like to re-select dependencies?"; then
      rm -f "$catalog_file" "$selected_file"
      warn "Custom installation aborted by user."
      return 1
    fi
  done

  if is_dry_run; then
    CUSTOM_BREWFILE="$(mktemp "${TMPDIR:-/tmp}/Brewfile.custom.XXXXXX")"
    info "Dry run: would write $HOME/.dotfiles/Brewfile.custom ($count package(s))"
  else
    CUSTOM_BREWFILE="$HOME/.dotfiles/Brewfile.custom"
    ensure_real_directory "$HOME/.dotfiles"
  fi

  {
    printf "cask_args appdir: \"/Applications\"\n\n"

    local has_mas=0
    while IFS= read -r line; do
      if [[ "$line" =~ \(mas\) ]]; then
        has_mas=1
        break
      fi
    done < "$selected_file"

    if (( has_mas )); then
      printf "brew \"mas\"\n"
    fi

    awk -F"\t" 'NR==FNR { sel[$0]; next } $1 in sel { print $2 }' "$selected_file" "$catalog_file"
  } > "$CUSTOM_BREWFILE"

  rm -f "$catalog_file" "$selected_file"
  return 0
}

install_packages_for_environment() {
  local environment_label="$1"
  local brewfile="$2"

  if [[ "$environment_label" == "Custom" ]]; then
    if custom_brewfile_has_packages "$brewfile"; then
      install_environment_bundle "$brewfile"
    else
      info "No custom packages selected; skipping Homebrew bundle installation."
    fi
  elif confirm "Install Homebrew packages for $environment_label?"; then
    install_environment_bundle "$brewfile"
  fi
}

install_oh_my_zsh_if_needed() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "Oh My Zsh already exists; leaving it untouched."
    return 0
  fi

  info "Installing Oh My Zsh."
  run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}
