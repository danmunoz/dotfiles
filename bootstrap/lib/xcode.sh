#!/usr/bin/env bash

select_xcode_app() {
  local app_path="$1"
  [[ -d "$app_path/Contents/Developer" ]] || die "Xcode developer directory not found in $app_path."

  sudo xcode-select -s "$app_path/Contents/Developer"
  sudo xcodebuild -license accept
  xcodebuild -version
}

latest_xcode_app() {
  ls -dt /Applications/Xcode*.app 2>/dev/null | head -n 1
}

configure_xcode() {
  local choice app_path

  choice=$(choose_one "Xcode setup" \
    "Select existing /Applications/Xcode.app" \
    "Install latest Xcode with xcodes" \
    "Skip Xcode setup") || die "No Xcode option selected."

  case "$choice" in
    "Select existing /Applications/Xcode.app")
      select_xcode_app "/Applications/Xcode.app"
      ;;
    "Install latest Xcode with xcodes")
      command -v xcodes >/dev/null 2>&1 || die "xcodes is not installed."
      xcodes install --latest
      app_path="$(latest_xcode_app)"
      [[ -n "$app_path" ]] || die "xcodes finished, but no Xcode app was found."
      select_xcode_app "$app_path"
      ;;
    "Skip Xcode setup")
      warn "Skipped Xcode setup."
      ;;
  esac
}

install_xcode_themes_if_requested() {
  local repo_root="$1"

  [[ -x "$repo_root/Scripts/XcodeThemes/install-xcode-themes" ]] || return 0
  if confirm "Install Xcode themes?"; then
    "$repo_root/Scripts/XcodeThemes/install-xcode-themes"
  fi
}
