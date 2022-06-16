# macOS initial configuration (Daniel's dotfiles)

Dotfiles and Initial macOS configuration, including:
- Dotfiles (.zshrc & .gitconfig)
- macOS apps installation using Homebrew's Bundle
- macOS configuration
- Xcode themes installation

## Installation

**Warning:** Before using the content of this repo, you should download, review and modify the content to suit your needs. Use at your own risk!

You can clone the repository and run the `setup` script with the following command:

```bash
git clone https://github.com/danmunoz/dotfiles && cd dotfiles && source setup
```

If you are on a fresh macOS installation, you won't be able to use git, so we can proceed manually:

Run this command to download and unzip the repo in your current directory:

```bash
curl https://github.com/danmunoz/dotfiles/archive/refs/heads/main.zip -L -o dotfiles.zip && unzip dotfiles.zip && rm -f dotfiles.zip \
&& cd dotfiles && source setup
```

Again, I strongly encourage you to avoid running this script directly and to customize it to suit your needs.
