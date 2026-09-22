#!/usr/bin/env bash

xcode_bundle_version() {
  local app_path="$1"
  local version
  version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    version="${version}.0"
  fi
  printf "%s\n" "$version"
}

select_xcode_app() {
  local app_path="$1"
  is_dry_run && return 0
  [[ -d "$app_path/Contents/Developer" ]] || die "Xcode developer directory not found in $app_path."

  if [[ "$app_path" != "/Applications/Xcode.app" ]]; then
    if [[ -d "/Applications/Xcode.app" ]]; then
      local old_version
      old_version="$(xcode_bundle_version "/Applications/Xcode.app")"
      if [[ -n "$old_version" && ! -e "/Applications/Xcode-${old_version}.app" ]]; then
        info "Renaming existing /Applications/Xcode.app to /Applications/Xcode-${old_version}.app"
        sudo mv "/Applications/Xcode.app" "/Applications/Xcode-${old_version}.app"
      else
        sudo rm -rf "/Applications/Xcode.app"
      fi
    fi
    info "Renaming $app_path to /Applications/Xcode.app"
    sudo mv "$app_path" "/Applications/Xcode.app"
    app_path="/Applications/Xcode.app"
  fi

  sudo xcode-select -s "$app_path/Contents/Developer"
  sudo xcodebuild -license accept
  xcodebuild -version
}

latest_xcode_app() {
  local candidate version result
  result="$(
    for candidate in /Applications/Xcode.app /Applications/Xcode-*.app /Applications/Xcode_*.app; do
      [[ -d "$candidate/Contents/Developer" ]] || continue
      [[ "$candidate" == *Beta* || "$candidate" == *beta* || "$candidate" == *Release_Candidate* ]] && continue
      version="$(xcode_bundle_version "$candidate")"
      [[ -n "$version" ]] || version="0.0.0"
      printf "%s\t%s\n" "$version" "$candidate"
    done | sort -V -k1,1 | tail -n 1 | cut -f2-
  )"

  if [[ -z "$result" ]]; then
    result="$(
      for candidate in /Applications/Xcode.app /Applications/Xcode-*.app /Applications/Xcode_*.app; do
        [[ -d "$candidate/Contents/Developer" ]] || continue
        version="$(xcode_bundle_version "$candidate")"
        [[ -n "$version" ]] || version="0.0.0"
        printf "%s\t%s\n" "$version" "$candidate"
      done | sort -V -k1,1 | tail -n 1 | cut -f2-
    )"
  fi

  printf "%s\n" "$result"
}

configure_xcode() {
  local choice app_path dev_dir

  choice=$(choose_one "Xcode setup" \
    "Select existing /Applications/Xcode.app" \
    "Install latest Xcode with xcodes" \
    "Skip Xcode setup") || die "No Xcode option selected."

  case "$choice" in
    "Select existing /Applications/Xcode.app")
      app_path="/Applications/Xcode.app"
      if [[ ! -d "$app_path/Contents/Developer" ]]; then
        app_path="$(latest_xcode_app)"
      fi
      [[ -n "$app_path" ]] || die "No installed Xcode app was found in /Applications."
      select_xcode_app "$app_path"
      ;;
    "Install latest Xcode with xcodes")
      is_dry_run && return 0
      command -v xcodes >/dev/null 2>&1 || die "xcodes is not installed."
      xcodes install --latest --experimental-unxip --select || true
      dev_dir="$(xcode-select -p 2>/dev/null || true)"
      if [[ "$dev_dir" == /Applications/Xcode*.app/Contents/Developer && -d "$dev_dir" ]]; then
        app_path="${dev_dir%/Contents/Developer}"
      else
        app_path="$(latest_xcode_app)"
      fi
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
    run "$repo_root/Scripts/XcodeThemes/install-xcode-themes"
  fi
}
