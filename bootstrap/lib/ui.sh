#!/usr/bin/env bash

ui_header() {
  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border normal \
      --margin "1 0" \
      --padding "1 2" \
      --foreground 212 \
      "$1"
  else
    printf "\n%s\n\n" "$1"
  fi
}

info() {
  printf "==> %s\n" "$1"
}

warn() {
  printf "warning: %s\n" "$1" >&2
}

die() {
  printf "error: %s\n" "$1" >&2
  exit 1
}

is_dry_run() {
  [[ "${DRY_RUN:-0}" == "1" ]]
}

run() {
  is_dry_run && return 0
  "$@"
}

confirm() {
  local prompt="$1"

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum confirm "$prompt"
    return $?
  fi

  local reply
  printf "%s [y/N] " "$prompt" >&2
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

choose_one() {
  local header="$1"
  shift

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum choose --header "$header" "$@"
    return $?
  fi

  local option index=1 reply
  printf "%s\n" "$header" >&2
  for option in "$@"; do
    printf "%d. %s\n" "$index" "$option" >&2
    index=$((index + 1))
  done
  printf "Selection: " >&2
  read -r reply

  index=1
  for option in "$@"; do
    if [[ "$reply" == "$index" || "$reply" == "$option" ]]; then
      printf "%s\n" "$option"
      return 0
    fi
    index=$((index + 1))
  done

  return 1
}

run_step() {
  local title="$1"
  shift

  if command -v gum >/dev/null 2>&1; then
    gum spin --spinner dot --show-output --title "$title" -- "$@"
  else
    info "$title"
    "$@"
  fi
}
