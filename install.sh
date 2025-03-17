#!/bin/bash
set -e  # Exit immediately if a command fails

echo "Starting installation..."

# Detect OS (Linux or macOS)
OS="$(uname -s)"

install_packages() {
    case "$OS" in
        Linux)
            echo "Detected Linux. Installing prerequisites..."
            sudo apt-get update
            sudo apt-get install -y zsh ninja-build gettext cmake curl build-essential tmux unzip

            # Install Neovim if not installed
            if ! command -v nvim &>/dev/null; then
                echo "Neovim not found. Installing via package manager..."
                sudo apt-get install -y neovim || {
                    echo "Neovim not found in package manager. Cloning and building from source..."
                    install_neovim_from_source
                }
            fi
            ;;
        Darwin)
            echo "Detected macOS. Installing prerequisites..."
            if ! command -v brew &>/dev/null; then
                echo "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install zsh ninja gettext cmake curl tmux unzip

            # Install Neovim if not installed
            if ! command -v nvim &>/dev/null; then
                echo "Neovim not found. Installing via Homebrew..."
                brew install neovim || {
                    echo "Neovim installation failed. Cloning and building from source..."
                    install_neovim_from_source
                }
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_neovim_from_source() {
    NEOVIM_DIR="$HOME/neovim"
    if [ -d "$NEOVIM_DIR" ]; then
        echo "Neovim directory already exists. Pulling latest changes from v0.10.4 branch..."
        git -C "$NEOVIM_DIR" fetch
        git -C "$NEOVIM_DIR" checkout v0.10.4
        git -C "$NEOVIM_DIR" pull origin v0.10.4
    else
        echo "Cloning Neovim v0.10.4 branch..."
        git clone --branch v0.10.4 https://github.com/neovim/neovim.git "$NEOVIM_DIR"
    fi

    # Build and install Neovim
    cd "$NEOVIM_DIR"
    make CMAKE_BUILD_TYPE=Release
    sudo make install
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh is already installed. Skipping..."
    else
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

set_zsh_as_default() {
    ZSH_PATH="$(command -v zsh)"

    if [ "$SHELL" != "$ZSH_PATH" ]; then
        echo "Setting Zsh as the default shell..."
        
        # Ensure the Zsh path is in /etc/shells
        if ! grep -qx "$ZSH_PATH" /etc/shells; then
            echo "Adding $ZSH_PATH to /etc/shells"
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi

        # Change the default shell
        chsh -s "$ZSH_PATH"
    else
        echo "Zsh is already the default shell."
    fi
}

install_tpm() {
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ -d "$TPM_DIR" ]; then
        echo "TPM (Tmux Plugin Manager) is already installed. Updating..."
        git -C "$TPM_DIR" pull
    else
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi
}

install_fonts() {
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    echo "Downloading DevIcons font..."
    curl -L -o "/tmp/devicons.zip" "https://github.com/vorillaz/devicons/archive/master.zip"
    unzip -o "/tmp/devicons.zip" -d "$FONT_DIR"

    echo "Downloading Nerd Fonts..."
    curl -L -o "/tmp/nerdfonts.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/0xProto.zip"
    unzip -o "/tmp/nerdfonts.zip" -d "$FONT_DIR"

    echo "Updating font cache..."
    if command -v fc-cache &>/dev/null; then
        fc-cache -fv
    else
        echo "fc-cache not found. Please restart your system for font updates to take effect."
    fi
}

# Install necessary packages
install_packages

# Ensure Neovim is installed after package installation
if ! command -v nvim &>/dev/null; then
    echo "Neovim installation failed. Cloning and building from source..."
    install_neovim_from_source
fi

# Install Oh My Zsh
install_oh_my_zsh

# Set Zsh as the default shell
set_zsh_as_default

# Install Tmux Plugin Manager (TPM)
install_tpm

# Install Nerd Fonts and DevIcons
install_fonts

# Symlink configuration files, removing existing ones first
echo "Symlinking configuration files..."
DOTFILES_DIR="$(pwd)"  # Assuming script is run from dotfiles repo

CONFIG_FILES=("nvim" "tmux" "wezterm" "ncspot")

for dir in "${CONFIG_FILES[@]}"; do
    TARGET="$HOME/.config/$dir"
    
    # Remove existing symlink or directory
    if [ -L "$TARGET" ] || [ -d "$TARGET" ]; then
        echo "Removing existing symlink or directory: $TARGET"
        rm -rf "$TARGET"
    fi

    # Create new symlink
    ln -s "$DOTFILES_DIR/$dir" "$TARGET"
    echo "Symlinked $dir → $TARGET"
done

echo "Installation and setup complete. Please restart your terminal or log out and back in."

echo "Installation and setup complete."

