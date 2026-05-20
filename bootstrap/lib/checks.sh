#!/usr/bin/env bash

ensure_apple_silicon_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap only supports macOS."
  [[ "$(uname -m)" == "arm64" ]] || die "This bootstrap only supports Apple Silicon Macs."
}

ensure_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi

  warn "Apple Command Line Tools are not installed."
  xcode-select --install || true
  printf "Complete the Command Line Tools installer, then press Return to continue."
  read -r _

  xcode-select -p >/dev/null 2>&1 || die "Command Line Tools are still unavailable."
}

ensure_sudo() {
  info "Requesting sudo once for system setup steps."
  sudo -v

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}
