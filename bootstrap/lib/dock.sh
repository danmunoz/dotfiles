#!/usr/bin/env bash

restore_dock() {
  local plist="$1"

  [[ -f "$plist" ]] || die "Dock plist not found: $plist"
  plutil -lint "$plist" >/dev/null
  run cp "$plist" "$HOME/Library/Preferences/com.apple.dock.plist"
  run killall Dock >/dev/null 2>&1 || true
}

restore_dock_for_environment() {
  local environment_label="$1"
  local dock_plist="$2"
  local repo_root="$3"

  if [[ "$environment_label" == "Custom" ]]; then
    if confirm "Restore a preconfigured Dock layout? This overwrites the current Dock."; then
      local dock_choice
      dock_choice="$(choose_one "Choose Dock layout" "Personal" "Work" "Skip")" || dock_choice="Skip"
      case "$dock_choice" in
        Personal)
          restore_dock "$repo_root/Scripts/Prefs/com.apple.dock.plist"
          ;;
        Work)
          restore_dock "$repo_root/work/com.apple.dock.plist"
          ;;
        *)
          info "Skipping Dock layout restoration."
          ;;
      esac
    fi
  else
    if confirm "Restore $environment_label Dock layout? This overwrites the current Dock."; then
      restore_dock "$dock_plist"
    fi
  fi
}
