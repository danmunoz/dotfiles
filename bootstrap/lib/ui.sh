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

choose_multiple_tui() {
  local header="$1"
  shift
  local -a items=("$@")
  local total=${#items[@]}
  (( total == 0 )) && return 0

  local -a selected=()
  local i
  for (( i=0; i<total; i++ )); do
    selected+=(0)
  done

  local cursor=0
  local offset=0
  local window_size=15
  (( total < window_size )) && window_size=$total

  local old_stty
  old_stty="$(stty -g 2>/dev/null || true)"
  stty -echo -icanon min 1 time 0 2>/dev/null || true
  printf "\033[?25l" >&2

  local lines_drawn=$(( window_size + 4 ))

  while true; do
    local end=$(( offset + window_size ))
    (( end > total )) && end=$total

    printf "%s%s%s %s(↑/↓/j/k: navigate, Space/x: toggle, a: all, Enter: confirm, q: cancel)%s\r\n" \
      "$CLR_BOLD" "$header" "$CLR_RESET" "$CLR_DIM" "$CLR_RESET" >&2

    if (( offset > 0 )); then
      printf "  %s↑ (%d more above)%s\r\n" "$CLR_DIM" "$offset" "$CLR_RESET" >&2
    else
      printf "  %s────────────────────────────────────────%s\r\n" "$CLR_DIM" "$CLR_RESET" >&2
    fi

    for (( i=offset; i<end; i++ )); do
      local cur="  "
      [[ $i -eq $cursor ]] && cur="${CLR_CYAN}>${CLR_RESET} "
      local box="[ ]"
      [[ ${selected[$i]} -eq 1 ]] && box="${CLR_BOLD}[x]${CLR_RESET}"
      printf "%s%s %s\r\n" "$cur" "$box" "${items[$i]}" >&2
    done

    local below=$(( total - end ))
    if (( below > 0 )); then
      printf "  %s↓ (%d more below)%s\r\n" "$CLR_DIM" "$below" "$CLR_RESET" >&2
    else
      printf "  %s────────────────────────────────────────%s\r\n" "$CLR_DIM" "$CLR_RESET" >&2
    fi

    local count=0
    for (( i=0; i<total; i++ )); do
      (( ${selected[$i]} == 1 )) && count=$(( count + 1 ))
    done
    printf "  %s[%d of %d selected]%s\r\n" "$CLR_BOLD" "$count" "$total" "$CLR_RESET" >&2

    local key="" rest=""
    IFS= read -rsn1 key || break
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 rest || true
      key+="$rest"
    fi

    case "$key" in
      $'\x1b[A'|k|K)
        if (( cursor > 0 )); then
          cursor=$(( cursor - 1 ))
          (( cursor < offset )) && offset=$cursor
        fi
        ;;
      $'\x1b[B'|j|J)
        if (( cursor < total - 1 )); then
          cursor=$(( cursor + 1 ))
          (( cursor >= offset + window_size )) && offset=$(( cursor - window_size + 1 ))
        fi
        ;;
      " "|x|X)
        selected[$cursor]=$(( 1 - selected[$cursor] ))
        ;;
      a|A)
        local all_sel=1
        for (( i=0; i<total; i++ )); do
          if (( ${selected[$i]} == 0 )); then
            all_sel=0
            break
          fi
        done
        for (( i=0; i<total; i++ )); do
          selected[$i]=$(( 1 - all_sel ))
        done
        ;;
      "")
        printf "\033[%dA\033[J" "$lines_drawn" >&2
        break
        ;;
      q|Q)
        printf "\033[%dA\033[J" "$lines_drawn" >&2
        [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null || true
        printf "\033[?25h" >&2
        return 1
        ;;
    esac

    printf "\033[%dA\033[J" "$lines_drawn" >&2
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null || true
  printf "\033[?25h" >&2

  for (( i=0; i<total; i++ )); do
    if (( ${selected[$i]} == 1 )); then
      printf "%s\n" "${items[$i]}"
    fi
  done
  return 0
}

choose_multiple() {
  local header="$1"
  shift

  printf "\n" >&2

  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    gum choose --no-limit \
      --header "$header (Space/x to toggle, Enter to confirm)" \
      --cursor="> " \
      --cursor-prefix="[ ] " \
      --selected-prefix="[x] " \
      --unselected-prefix="[ ] " \
      --height 15 \
      "$@"
    return $?
  fi

  if [ -t 0 ]; then
    choose_multiple_tui "$header" "$@"
    return $?
  fi

  local option
  local reply
  read -r reply || return 1

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
