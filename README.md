🍺 macOS Setup Automation (Daniel's Dotfiles)

Personal dotfiles and macOS bootstrap automation. The public install entrypoint is the branded short URL `https://danmunoz.com/dotfiles-install`.

The current bootstrap is designed for fresh Apple Silicon Macs. It uses a public one-command installer, direct symlinks into this repo for dotfiles, `gum` for terminal UI prompts, Homebrew Bundle for packages, and `xcodes` for Xcode setup.

> Warning: this repository is intentionally opinionated and can change files in your home directory. Destructive actions require explicit confirmation.

## Fresh Install

Run this from Terminal on a new Mac:

```bash
/bin/bash -c "$(curl -fsSL https://danmunoz.com/dotfiles-install)"
```

The repo is public, so GitHub authentication is not required for initial setup. At the end, the bootstrap can optionally run `gh auth login` so the local dotfiles clone can push changes back to GitHub.

## What It Does

The `install` seed script:

- verifies macOS on Apple Silicon
- installs Apple Command Line Tools if missing
- installs Homebrew if missing
- clones this repo to `~/Repos/dotfiles` by default on a fresh machine
- reuses the current local clone when run from inside the repo
- otherwise updates the existing clone before launching the interactive setup flow
- installs bootstrap tools from `bootstrap/Brewfile.bootstrap`
- launches the repo-local terminal UI at `bootstrap/main.sh`

The terminal UI:

- asks for `Personal` or `Work`
- creates a real `~/.dotfiles` directory for mixed managed and local files
- symlinks managed dotfiles directly into your home directory
- installs the selected Homebrew bundle
- installs Oh My Zsh only if missing
- installs or selects Xcode through `xcodes`
- optionally installs Xcode themes
- optionally restores the selected Dock layout
- optionally installs Rosetta
- optionally applies baseline macOS preferences
- optionally runs a local `~/.dotfiles/run-once`
- optionally authenticates GitHub for pushing dotfile changes

## Direct Symlink Workflow

The default local clone path is:

```bash
~/Repos/dotfiles
```

Tracked dotfiles live in:

```bash
Scripts/dotfiles/
```

Common commands:

```bash
cd ~/Repos/dotfiles                # open the repo
git status                         # see tracked changes
./install                          # update the local clone if needed, then rerun setup
code Scripts/dotfiles/aliases      # edit a managed dotfile directly
```

Managed files:

| Source | Target |
|---|---|
| `Scripts/dotfiles/zshrc` | `~/.zshrc` |
| `Scripts/dotfiles/zprofile` | `~/.zprofile` |
| `Scripts/dotfiles/gitconfig` | `~/.gitconfig` |
| `Scripts/dotfiles/gitignore` | `~/.gitignore` |
| `Scripts/dotfiles/aliases` | `~/.dotfiles/aliases` |
| `Scripts/dotfiles/functions.zsh` | `~/.dotfiles/functions.zsh` |
| `Scripts/dotfiles/scripts/reset-android-emulator` | `~/.dotfiles/scripts/reset-android-emulator` |

Local-only files are intentionally not managed. Use these examples as references:

- `Scripts/dotfiles/extra.example` -> create `~/.dotfiles/extra`
- `Scripts/dotfiles/run-once.example` -> create `~/.dotfiles/run-once`

## Repository Layout

```text
.
├── install
├── bootstrap/
│   ├── main.sh
│   ├── Brewfile.bootstrap
│   └── lib/
├── Brewfile
├── Scripts/
│   ├── dotfiles/
│   ├── Prefs/
│   ├── Utilities/
│   └── XcodeThemes/
├── dock/
├── work/
│   ├── Brewfile-work
│   └── com.apple.dock.plist
└── docs/
    └── BOOTSTRAP_SPEC.md
```

## Environment Differences

Personal setup uses:

- `Brewfile`
- `Scripts/Prefs/com.apple.dock.plist`

Work setup uses:

- `work/Brewfile-work`
- `work/com.apple.dock.plist`

The work setup installs Microsoft Outlook and Microsoft Teams because the work Dock expects them.

## Xcode

Xcode is handled as a first-class setup step.

Preferred path:

1. install `xcodes`
2. install or select Xcode
3. run `sudo xcode-select -s ...`
4. run `sudo xcodebuild -license accept`

`mas` is kept for other Mac App Store apps, not as the primary Xcode installer.

## Development

Validate shell syntax:

```bash
bash -n install \
  bootstrap/main.sh \
  bootstrap/lib/*.sh \
  Scripts/Prefs/setup-macos-prefs \
  Scripts/XcodeThemes/install-xcode-themes \
  Scripts/Utilities/print-color \
  Scripts/dotfiles/scripts/reset-android-emulator
```

Validate Dock plists:

```bash
plutil -lint Scripts/Prefs/com.apple.dock.plist work/com.apple.dock.plist
```

Validate Homebrew bundles:

```bash
brew bundle check --file=bootstrap/Brewfile.bootstrap
brew bundle check --file=Brewfile
brew bundle check --file=work/Brewfile-work
```

Validate direct links:

```bash
ls -l ~/.zshrc ~/.zprofile ~/.gitconfig ~/.gitignore
ls -l ~/.dotfiles/aliases ~/.dotfiles/functions.zsh ~/.dotfiles/scripts/reset-android-emulator
```

The detailed implementation contract is in [`docs/BOOTSTRAP_SPEC.md`](docs/BOOTSTRAP_SPEC.md).

## Troubleshooting

- If Command Line Tools installation opens a GUI installer, complete it and return to Terminal.
- If Xcode installation through `xcodes` requires Apple authentication, complete the prompt and rerun the bootstrap if needed.
- If Mac App Store apps fail, sign into the App Store and rerun the selected Homebrew bundle.
- Some Dock and system changes require logout or restart.

## Acknowledgements

Inspired by:

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [cdzombak/dotfiles](https://github.com/cdzombak/dotfiles)

## License

MIT. See [`LICENSE`](LICENSE).
