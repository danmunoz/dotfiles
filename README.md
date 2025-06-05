# 🍺 macOS Setup Automation (Daniel's Dotfiles)

This repository provides a script (`bootstrap.sh`) to automate the initial setup and configuration of a new macOS machine, tailored with my preferred dotfiles, applications, and system settings.

**Warning:** This script will make significant changes to your system, including installing software, setting up configurations, and potentially overwriting existing dotfiles. **It is crucial to review the `bootstrap.sh` script thoroughly and modify it to suit your specific needs before execution.** Use it at your own risk!

## ✨ Features

The `bootstrap.sh` script automates the following:

* **Environment Selection:** Allows you to choose between 'Personal' and 'Work' environments, which determines which Brewfile and Dock configuration to use.
* **Homebrew Installation & Configuration:** Installs Homebrew (if not present) and sets up its shell environment.
* **Xcode Installation:** Installs Xcode from the Mac App Store, sets the `xcode-select` path, and accepts the license agreement.
* **Xcode Theme Installation:** Installs custom Xcode themes.
* **Rosetta 2 Installation:** Prompts to install Rosetta 2 for Intel-based applications on Apple Silicon Macs.
* **Homebrew Bundle Installation:** Installs all applications and packages specified in your `Brewfile` (personal) or `Brewfile-work` (work environment). You'll be prompted to review/edit the Brewfile before proceeding.
* **Oh My Zsh Installation:** Sets up Oh My Zsh for an enhanced terminal experience.
* **Dotfiles Management:**
    * Copies the `.dotfiles` directory to `~/.dotfiles`.
    * Creates symbolic links for key configuration files (`.zshrc`, `.zprofile`, `.gitconfig`, `.gitignore`), replacing existing ones.
* **macOS System Preferences:** Applies a set of custom macOS system preferences.
* **Dock Configuration:** Restores a personalized Dock layout.
* **Private Command Execution:** Optionally runs a `run-once` script for additional, private setup commands (defaults to 'yes' after timeout).

## 🚀 Installation

### 1. Get the files

First, you need to get the `dotfiles` repository onto your machine.

**If Git is already installed:**

You can clone the repository using the following command:

```bash
git clone [https://github.com/danmunoz/dotfiles](https://github.com/danmunoz/dotfiles) && cd dotfiles
```

**If Git is not installed (fresh macOS install):**

Use `curl` to download and unzip the repository into your current directory:

```bash
curl [https://github.com/danmunoz/dotfiles/archive/refs/heads/main.zip](https://github.com/danmunoz/dotfiles/archive/refs/heads/main.zip) -L -o dotfiles.zip && unzip dotfiles.zip && rm -f dotfiles.zip \
&& cd dotfiles-main
```

### 2. Run the script

Once you are in the `dotfiles` directory (or `dotfiles-main` if downloaded via curl), make the `bootstrap.sh` script executable and run it:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```
The script will guide you through the setup process.

## ⚙️ Usage & Customization

The `bootstrap.sh` script is designed to be interactive, but with timeouts for convenience.

* **Prompt Behavior:** All user prompts (except for the initial environment selection) will **default to "yes"** if no input is provided within `prompt_timeout` seconds (default is 15 seconds).
* **Environment Selection:** You will be prompted to choose between a "Personal" or "Work" environment, which affects the Brewfile and Dock configuration.
* **Force Mode:** To run the script completely non-interactively without any prompts (including the initial confirmation and environment selection), use the `--force` or `-f` flag:
    ```bash
    ./bootstrap.sh --force
    ```
    In force mode, the script will proceed with the "Personal" environment configuration by default.
* **Brewfile Customization:** The script will offer you the chance to review and edit your `Brewfile` (or `Brewfile-work`) before Homebrew bundles are installed. This allows you to tailor your application and package list.

## 🔒 Private Information Customization
To keep sensitive or personal information (e.g., Git name, email, private aliases) out of a public repository, you can use the extra and run-once files located within the Scripts/dotfiles directory.

#### `extra`

The `extra` file can contain commands or aliases that will be sourced by your `.zshrc` every time a new terminal session is launched. This is ideal for frequently used private aliases or environment variables.

Example `extra` file:

```bash
# Aliases for secret projects
alias secret_project="cd /path/to/secret"
alias private_folder="cd /path/to/private"
# Private environment variables
export MY_API_KEY="your_secret_key_here"
```

#### `run-once`

The `run-once` script will be executed as part of the `bootstrap.sh` script. This is suitable for commands that only need to be run once during the initial setup, such as setting up Git credentials, SSH keys, or other one-time configurations.

Example `run-once` file:

```bash
#! /usr/bin/env bash
# Git credentials (not in the public repository)
GIT_AUTHOR_NAME="Your Name"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="your_email@example.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
# Create SSH key (if it doesn't exist)
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
fi
```

Keep in mind that the main difference between these two files is that `extra` runs with every terminal launch, while `run-once` executes only during the `bootstrap.sh` process.

## ⚠️ Troubleshooting / Common Issues

* **`sudo` Password Prompt:** While the script attempts to keep your `sudo` session active, the Homebrew installer (or other tools like `xcode-select`) may still occasionally prompt for your password if system permissions require it. To minimize prompts, you can run `sudo -v` in your terminal *before* executing `bootstrap.sh`.
* **Full Disk Access:** The script checks if your terminal application has Full Disk Access. If it doesn't, you will be prompted to grant it in "System Settings > Privacy & Security > Full Disk Access". You must restart your terminal after granting access and re-run the script.
* **"command not found: brew" after installation:** Ensure your shell configuration is reloaded. You might need to open a new terminal session or run `source ~/.zprofile` (or `source ~/.zshrc`) after the script completes.
* **Xcode Installation from App Store:** This step might require you to be logged into your Apple ID on the App Store.

## 🤝 Feedback
Suggestions and improvements are always [welcome](https://github.com/danmunoz/dotfiles/issues)! Feel free to open an issue or submit a pull request.

## 🙏 Acknowledgements

The work done here was inspired by:

* [@mathias's dotfiles](https://github.com/mathiasbynens/dotfiles)
* [@cdzombak's dotfiles](https://github.com/cdzombak/dotfiles)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.