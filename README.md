# macOS initial configuration (Daniel's dotfiles)

Dotfiles and Initial macOS configuration, including:
- Dotfiles (.zshrc, .gitconfig, etc)
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

## Private information customization

In order to keep private information (e.g. git name) outside of a public repository, there's the possibility to customize two files inside the `dotfiles` directory: `extra` and `run-once`.
#### extra
The `extra` file, can contain commands that will be sourced by `.zshrc` every time terminal is launched.

This is how an `extra` file would look like:

```bash
# Aliases
alias secret_project="cd /path/to/secret"
alias private_folder="cd /path/to/private"
```

#### run-once
The `run-once` script, will run as part of the `bootstrap` script.

This is how a `run-once` file would look like:

```bash
#! /usr/bin/env bash

# Git credentials
# Not in the repository, to prevent people from accidentally committing under my name
GIT_AUTHOR_NAME="Daniel Munoz"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="daniel@example.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"

```

Keep in mind that the main difference between these two files is that `extra` will run every time terminal is launched.

You could also use these files to override settings, functions and aliases from my dotfiles repository, but it is a better idea to [fork this repository](https://github.com/danmunoz/dotfiles/fork) instead.

## Feedback

Suggestions/improvements
[welcome](https://github.com/danmunoz/dotfiles/issues)!

## Aknowledgements
The work done here was inspired by:
- [@mathias's dotfiles](https://github.com/mathiasbynens/dotfiles)
- [@cdzombak's dotfiles](https://github.com/cdzombak/dotfiles)