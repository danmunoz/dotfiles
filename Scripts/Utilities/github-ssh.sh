#! /usr/bin/env bash

if [ ! -f ~/.ssh/id_ed25519 ]; then
  read -p "Enter email for ssh cert: " email
  ssh-keygen -t ed25519 -C "$email"
  eval "$(ssh-agent -s)"

  echo "Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config

  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install gh

gh auth login

gh ssh-key add ~/.ssh/id_ed25519.pub
