# macOS initial configuration (Daniel's dotfiles)

Dotfiles and Initial macOS configuration, including:
- Dotfiles (.zshrc & .gitconfig)
- macOS apps installation using Homebrew's Bundle
- macOS configuration
- Xcode themes installation

**Warning:** Before using the content of this repo, you should download, review and modify it to suit your needs. Use it at your own risk!

## Installation

### 1. Get the files
Depending on your current situation, you could either have or not have (fresh install) git installed on your computer:

*** Git already Installed ***
You can clone the repository with the following command:

```bash
git clone https://github.com/danmunoz/dotfiles && cd dotfiles
```

*** Git ***not*** installed ***
Run this command to download and unzip the repo into your current directory:

```bash
curl https://github.com/danmunoz/dotfiles/archive/refs/heads/main.zip -L -o dotfiles.zip && unzip dotfiles.zip && rm -f dotfiles.zip \
&& cd dotfiles-main
```
### 2. Run the script
Once you have the files on your machine, just run the bootstrap script:

```bash
./bootstrap.sh
```

Again, I strongly encourage you to avoid running this script directly and to customize it to suit your needs.
