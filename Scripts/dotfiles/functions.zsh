#!/usr/bin/env bash

# Create a new directory and enter it.
function mkd() {
  mkdir -p "$@" && cd "$_"
}

# Change working directory to the top-most Finder window location.
function cdf() {
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

# `o` with no arguments opens the current directory, otherwise opens the given location.
function o() {
  if [ $# -eq 0 ]; then
    open .
  else
    open "$@"
  fi
}

# Opens DerivedData directory.
function dd() {
  open ~/Library/Developer/Xcode/DerivedData
}

function fossil-admin() {
  local d="$HOME/Repos/fossil-collector/admin-local"
  [[ -d "$d" ]] || { echo "missing: $d"; return 1; }
  (cd "$d" && npm run dev)
}

function reset_android_emulator() {
  "$HOME/.dotfiles/scripts/reset-android-emulator" "$@"
}

function reset-android-emulator() {
  reset_android_emulator "$@"
}
