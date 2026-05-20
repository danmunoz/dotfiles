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

confirm() {
  local prompt="$1"

  if command -v gum >/dev/null 2>&1; then
    gum confirm "$prompt"
    return $?
  fi

  local reply
  printf "%s [y/N] " "$prompt"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

choose_one() {
  local header="$1"
  shift

  if command -v gum >/dev/null 2>&1; then
    gum choose --header "$header" "$@"
    return $?
  fi

  local option index=1 reply
  printf "%s\n" "$header"
  for option in "$@"; do
    printf "%d. %s\n" "$index" "$option"
    index=$((index + 1))
  done
  printf "Selection: "
  read -r reply

  index=1
  for option in "$@"; do
    if [[ "$reply" == "$index" ]]; then
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
