#!/usr/bin/env bash

restore_dock() {
  local plist="$1"

  [[ -f "$plist" ]] || die "Dock plist not found: $plist"
  plutil -lint "$plist" >/dev/null
  cp "$plist" "$HOME/Library/Preferences/com.apple.dock.plist"
  killall Dock >/dev/null 2>&1 || true
}
