#!/usr/bin/env bash

if [[ (-t 1 || -t 2) && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  CLR_RESET=$'\033[0m'
  CLR_BOLD=$'\033[1m'
  CLR_DIM=$'\033[2m'
  CLR_BLUE=$'\033[1;34m'
  CLR_CYAN=$'\033[1;36m'
  CLR_YELLOW=$'\033[1;33m'
  CLR_RED=$'\033[1;31m'
  CLR_MAGENTA=$'\033[1;35m'
else
  CLR_RESET=""
  CLR_BOLD=""
  CLR_DIM=""
  CLR_BLUE=""
  CLR_CYAN=""
  CLR_YELLOW=""
  CLR_RED=""
  CLR_MAGENTA=""
fi

ui_header() {
  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border normal \
      --margin "1 0" \
      --padding "1 2" \
      --foreground 212 \
      "$1"
  else
    printf "\n%s%s=== %s ===%s\n" "$CLR_BOLD" "$CLR_MAGENTA" "$1" "$CLR_RESET"
  fi
}

info() {
  printf "%s==>%s %s%s%s\n" "$CLR_BLUE" "$CLR_RESET" "$CLR_BOLD" "$1" "$CLR_RESET"
}

warn() {
  printf "%swarning:%s %s\n" "$CLR_YELLOW" "$CLR_RESET" "$1" >&2
}

die() {
  printf "%serror:%s %s\n" "$CLR_RED" "$CLR_RESET" "$1" >&2
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

  printf "\n" >&2

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum confirm "$prompt"
    return $?
  fi

  local reply
  printf "%s?%s %s%s%s %s[y/N]%s " "$CLR_CYAN" "$CLR_RESET" "$CLR_BOLD" "$prompt" "$CLR_RESET" "$CLR_DIM" "$CLR_RESET" >&2
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

choose_one() {
  local header="$1"
  shift

  printf "\n" >&2

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum choose --header "$header" "$@"
    return $?
  fi

  local option index=1 reply
  printf "%s%s%s\n" "$CLR_BOLD" "$header" "$CLR_RESET" >&2
  for option in "$@"; do
    printf "  %s%d)%s %s\n" "$CLR_CYAN" "$index" "$CLR_RESET" "$option" >&2
    index=$((index + 1))
  done
  printf "%sSelection:%s " "$CLR_DIM" "$CLR_RESET" >&2
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

choose_multiple() {
  local header="$1"
  shift

  printf "\n" >&2

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum choose --no-limit \
      --header "$header (Press Space/Tab to toggle, Enter to confirm)" \
      --cursor-prefix "[ ] " \
      --selected-prefix "[x] " \
      --unselected-prefix "[ ] " \
      --height 15 \
      "$@"
    return $?
  fi

  local option index=1
  printf "%s%s%s\n" "$CLR_BOLD" "$header" "$CLR_RESET" >&2
  printf "%sEnter numbers separated by spaces or commas (e.g. 1 3 5), or 'all'/'none':%s\n" "$CLR_DIM" "$CLR_RESET" >&2
  for option in "$@"; do
    printf "  %s%3d)%s %s\n" "$CLR_CYAN" "$index" "$CLR_RESET" "$option" >&2
    index=$((index + 1))
  done

  printf "%sSelection:%s " "$CLR_DIM" "$CLR_RESET" >&2
  local reply
  read -r reply

  if [[ "$reply" == "all" ]]; then
    for option in "$@"; do
      printf "%s\n" "$option"
    done
    return 0
  elif [[ "$reply" == "none" || -z "$reply" ]]; then
    return 0
  fi

  reply="${reply//,/ }"
  local total=$#
  local -a all_options=("$@")
  local num
  for num in $reply; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= total )); then
      printf "%s\n" "${all_options[$((num - 1))]}"
    fi
  done
  return 0
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
