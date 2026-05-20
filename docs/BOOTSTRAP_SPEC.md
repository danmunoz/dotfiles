# Bootstrap Specification

## Purpose

This repo provides a one-command Apple Silicon macOS bootstrap for Daniel Munoz's personal and work machines.

The bootstrap must support a fresh Mac Terminal session without prior GitHub authentication. The dotfiles repo is public, so initial setup must not require GitHub login. GitHub authentication is optional at the end, only to make the local clone push-ready.

## Target Architecture

The system uses:

- `https://danmunoz.com/dotfiles-install` as the public short bootstrap URL.
- `install` as the repo-local seed script fetched by that short URL.
- a direct git clone of this repo at `~/Repos/dotfiles` by default.
- direct symlinks from `$HOME` into tracked files under `Scripts/dotfiles/`.
- `gum` for terminal UI prompts, choices, confirmations, and spinners.
- Homebrew Bundle for formulae, casks, and Mac App Store apps.
- `xcodes` as the preferred full Xcode installation path.
- `mas` for non-Xcode Mac App Store apps.

## Source Layout

```text
.
├── install
├── bootstrap/
│   ├── main.sh
│   ├── Brewfile.bootstrap
│   └── lib/
│       ├── checks.sh
│       ├── dock.sh
│       ├── dotfiles.sh
│       ├── homebrew.sh
│       ├── ui.sh
│       └── xcode.sh
├── Scripts/
│   ├── dotfiles/
│   │   ├── zshrc
│   │   ├── zprofile
│   │   ├── gitconfig
│   │   ├── gitignore
│   │   ├── aliases
│   │   ├── functions.zsh
│   │   ├── extra.example
│   │   ├── run-once.example
│   │   └── scripts/
│   │       └── reset-android-emulator
│   ├── Prefs/
│   ├── Utilities/
│   └── XcodeThemes/
├── Brewfile
└── work/
    └── Brewfile-work
```

## Fresh Machine Flow

1. User runs the one-line `install` command.
2. `install` verifies macOS and Apple Silicon.
3. `install` checks for Command Line Tools and starts `xcode-select --install` if needed.
4. `install` installs Homebrew if missing.
5. `install` clones or updates this public repo to `~/Repos/dotfiles` by default.
6. `install` installs bootstrap dependencies from `bootstrap/Brewfile.bootstrap`.
7. `install` launches `bootstrap/main.sh` from the local clone.
8. The TUI asks for Personal or Work.
9. The TUI ensures `~/.dotfiles/` and `~/.dotfiles/scripts/` are real directories.
10. The TUI symlinks managed files from `Scripts/dotfiles/` into `$HOME`.
11. The TUI installs the selected Homebrew bundle.
12. The TUI installs Oh My Zsh only if missing. It must never delete an existing `~/.oh-my-zsh`.
13. The TUI installs/configures Xcode through `xcodes` or selects an existing Xcode.
14. The TUI optionally installs Xcode themes.
15. The TUI optionally restores the environment-specific Dock plist.
16. The TUI optionally installs Rosetta if not already installed.
17. The TUI optionally runs baseline macOS preferences.
18. The TUI optionally runs a local `~/.dotfiles/run-once`.
19. The TUI optionally authenticates GitHub and configures the clone for pushing.

## Managed File Mapping

| Repo source | Home target |
|---|---|
| `Scripts/dotfiles/zshrc` | `~/.zshrc` |
| `Scripts/dotfiles/zprofile` | `~/.zprofile` |
| `Scripts/dotfiles/gitconfig` | `~/.gitconfig` |
| `Scripts/dotfiles/gitignore` | `~/.gitignore` |
| `Scripts/dotfiles/aliases` | `~/.dotfiles/aliases` |
| `Scripts/dotfiles/functions.zsh` | `~/.dotfiles/functions.zsh` |
| `Scripts/dotfiles/scripts/reset-android-emulator` | `~/.dotfiles/scripts/reset-android-emulator` |

The following files remain local-only and untracked:

- `~/.dotfiles/extra`
- `~/.dotfiles/run-once`

Examples live in:

- `Scripts/dotfiles/extra.example`
- `Scripts/dotfiles/run-once.example`

## Required Behavior

- Fresh clone must not require GitHub authentication.
- Destructive actions must require explicit confirmation.
- Required step failures must stop the run.
- The setup must support Apple Silicon only and stop clearly on Intel Macs.
- The setup must be safe to rerun.
- The setup must not overwrite local-only files like `~/.dotfiles/extra` or `~/.dotfiles/run-once`.
- The setup must keep Homebrew rolling-latest behavior.

## Validation Checklist

- `bash -n install bootstrap/main.sh bootstrap/lib/*.sh Scripts/Prefs/setup-macos-prefs Scripts/XcodeThemes/install-xcode-themes Scripts/Utilities/print-color Scripts/dotfiles/scripts/reset-android-emulator` passes.
- `plutil -lint Scripts/Prefs/com.apple.dock.plist work/com.apple.dock.plist` passes.
- `ls -l ~/.zshrc ~/.zprofile ~/.gitconfig ~/.gitignore` shows direct symlinks into the repo.
- `ls -l ~/.dotfiles/aliases ~/.dotfiles/functions.zsh ~/.dotfiles/scripts/reset-android-emulator` shows direct symlinks into the repo.
- Running `./install` from a cloned repo is idempotent and reuses the existing local clone.
