#!/bin/bash
set -e

echo "Starting installation..."

# Parse flags
UPDATE_ALL=false
UPDATE_NVIM=false
UPDATE_TPM=false
UPDATE_FONTS=false

for arg in "$@"; do
    case "$arg" in
        --update-all)
            UPDATE_ALL=true
            ;;
        --update-neovim)
            UPDATE_NVIM=true
            ;;
        --update-tpm)
            UPDATE_TPM=true
            ;;
        --update-fonts)
            UPDATE_FONTS=true
            ;;
    esac
done

OS="$(uname -s)"

install_packages() {
    case "$OS" in
        Linux)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
            elif [ -f /etc/debian_version ]; then
                DISTRO="debian"
            elif [ -f /etc/arch-release ]; then
                DISTRO="arch"
            else
                echo "Unable to detect Linux distribution"
                exit 1
            fi

            case "$DISTRO" in
                debian|ubuntu)
                    echo "Detected Debian/Ubuntu. Checking for recent apt update..."

                    # Only update if last update was more than 6 hours ago
                    UPDATE_STAMP="/var/lib/apt/periodic/update-success-stamp"
                    NEED_UPDATE=true
                    if [ -f "$UPDATE_STAMP" ]; then
                        LAST_UPDATE=$(stat -c %Y "$UPDATE_STAMP")
                        NOW=$(date +%s)
                        SIX_HOURS_AGO=$((NOW - 6 * 3600))

                        if [ "$LAST_UPDATE" -gt "$SIX_HOURS_AGO" ]; then
                            echo "apt-get update was run recently. Skipping."
                            NEED_UPDATE=false
                        fi
                    fi

                    if [ "$NEED_UPDATE" = true ]; then
                        echo "Running apt-get update..."
                        sudo apt-get update
                    fi

                    echo "Installing prerequisites..."
                    sudo apt-get install -y zsh ninja-build gettext cmake curl build-essential tmux unzip jq
                    ;;
                arch)
                    echo "Detected Arch Linux. Installing prerequisites..."
                    sudo pacman -Sy --needed --noconfirm zsh ninja gettext cmake curl base-devel tmux unzip jq
                    ;;
                *)
                    echo "Unsupported Linux distribution: $DISTRO"
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            echo "Detected macOS. Installing prerequisites..."
            if ! command -v brew &>/dev/null; then
                echo "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install zsh ninja gettext cmake curl tmux unzip jq
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_neovim_from_github_release() {
    if command -v nvim &>/dev/null && [ "$UPDATE_ALL" = false ] && [ "$UPDATE_NVIM" = false ]; then
        echo "Neovim already installed. Skipping."
        return
    fi

    echo "Fetching latest Neovim release from GitHub..."

    ARCH=$(uname -m)
    OS=$(uname -s)

    case "$OS" in
        Linux)
            if [[ "$ARCH" == "x86_64" ]]; then
                PLATFORM="linux-x86_64"
            elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
                PLATFORM="linux-arm64"
            else
                echo "Unsupported Linux arch: $ARCH"
                exit 1
            fi
            ;;
        Darwin)
            if [[ "$ARCH" == "x86_64" ]]; then
                PLATFORM="macos-x86_64"
            elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
                PLATFORM="macos-arm64"
            else
                echo "Unsupported macOS arch: $ARCH"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    TMP_DIR=$(mktemp -d)
    pushd "$TMP_DIR" > /dev/null

    echo "Resolving latest release asset for platform: $PLATFORM"

    # Query latest release info
    RELEASE_API="https://api.github.com/repos/neovim/neovim/releases/latest"
    ASSET_URL=$(curl -s "$RELEASE_API" | jq -r '.assets[] | select(.name | test("nvim-'"$PLATFORM"'\\.tar\\.gz")) | .browser_download_url')

    if [[ -z "$ASSET_URL" ]]; then
        echo "❌ Could not find Neovim release asset for platform: $PLATFORM"
        echo "Debug: Listing all asset names from latest release:"
        curl -s "$RELEASE_API" | jq -r ".assets[].name"
        exit 1
    fi

    echo "Downloading from: $ASSET_URL"
    curl -LO "$ASSET_URL"
    tar xzf "nvim-${PLATFORM}.tar.gz"
    echo "Installing Neovim to /usr/local/nvim"
    sudo rm -rf /usr/local/nvim
    sudo mkdir -p /usr/local/nvim

    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "nvim-*" | head -n 1)
    cd "$EXTRACTED_DIR"

    sudo cp -r ./* /usr/local/nvim/
    cd ..
    sudo ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh already installed. Skipping."
    else
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

set_zsh_as_default() {
    ZSH_PATH="$(command -v zsh)"
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        echo "Setting Zsh as the default shell..."
        if ! grep -qx "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
    else
        echo "Zsh is already the default shell."
    fi
}

install_nodejs() {
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo "Node.js and npm are already installed. Skipping."
        return
    fi

    case "$OS" in
        Linux)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
            elif [ -f /etc/debian_version ]; then
                DISTRO="debian"
            elif [ -f /etc/arch-release ]; then
                DISTRO="arch"
            else
                echo "Unable to detect Linux distribution"
                exit 1
            fi

            case "$DISTRO" in
                debian|ubuntu)
                    echo "Installing Node.js via NodeSource..."
                    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                    sudo apt-get install -y nodejs
                    ;;
                arch)
                    echo "Installing Node.js via pacman..."
                    sudo pacman -S --needed --noconfirm nodejs npm
                    ;;
                *)
                    echo "Unsupported Linux distribution for Node.js installation: $DISTRO"
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            echo "Installing Node.js via Homebrew..."
            brew install node
            ;;
        *)
            echo "Unsupported OS for Node.js installation: $OS"
            exit 1
            ;;
    esac

    echo "Installed Node.js version: $(node -v)"
    echo "Installed npm version: $(npm -v)"
}

install_tpm() {
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ -d "$TPM_DIR" ]; then
        if [ "$UPDATE_ALL" = true ] || [ "$UPDATE_TPM" = true ]; then
            echo "Updating TPM..."
            git -C "$TPM_DIR" pull
        else
            echo "TPM already installed. Skipping."
        fi
    else
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi
}

install_fonts() {
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    if [ "$UPDATE_ALL" = false ] && [ "$UPDATE_FONTS" = false ] && [ -f "$FONT_DIR/0xProto Nerd Font Complete.ttf" ]; then
        echo "Fonts already installed. Skipping."
        return
    fi

    echo "Installing Nerd Fonts and DevIcons..."
    curl -L -o "/tmp/devicons.zip" "https://github.com/vorillaz/devicons/archive/master.zip"
    unzip -o "/tmp/devicons.zip" -d "$FONT_DIR"

    curl -L -o "/tmp/nerdfonts.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/0xProto.zip"
    unzip -o "/tmp/nerdfonts.zip" -d "$FONT_DIR"

    if command -v fc-cache &>/dev/null; then
        fc-cache -fv
    fi
}

create_api_config() {
    CONFIG_FILE="$HOME/.api_keys"
    ZSHRC="$HOME/.zshrc"

    echo "Creating API key config file at $CONFIG_FILE..."

    # Create file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat <<EOF > "$CONFIG_FILE"
# API keys (edit these)
export OPENAI_API_KEY=""
export GEMINI_API_KEY=""
export ANTHROPIC_API_KEY=""
EOF
        chmod 600 "$CONFIG_FILE"
        echo "Created template API key file at $CONFIG_FILE."
    else
        echo "API key config file already exists. Skipping creation."
    fi

    # Ensure it's sourced in .zshrc
    if ! grep -q "source \$HOME/.api_keys" "$ZSHRC"; then
        echo "source \$HOME/.api_keys" >> "$ZSHRC"
        echo "Added API config sourcing to .zshrc."
    else
        echo "API config already sourced in .zshrc."
    fi
}


symlink_dotfiles() {
    echo "Symlinking configuration files..."
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILES=("nvim" "tmux" "wezterm" "ncspot" "hypr" "waybar" "rofi")

    for dir in "${CONFIG_FILES[@]}"; do
        TARGET="$HOME/.config/$dir"
        if [ -L "$TARGET" ] || [ -d "$TARGET" ]; then
            echo "Removing existing $TARGET"
            rm -rf "$TARGET"
        fi
        if [ -d "$DOTFILES_DIR/$dir" ]; then
            ln -s "$DOTFILES_DIR/$dir" "$TARGET"
            echo "Symlinked $dir → $TARGET"
        else
            echo "⚠️  Skipping: $DOTFILES_DIR/$dir does not exist"
        fi
    done

    # Symlink zshrc
    ZSHRC_TARGET="$HOME/.zshrc"
    if [ -f "$DOTFILES_DIR/zshrc" ]; then
        if [ -L "$ZSHRC_TARGET" ] || [ -f "$ZSHRC_TARGET" ]; then
            echo "Backing up existing $ZSHRC_TARGET to $ZSHRC_TARGET.backup"
            mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup"
        fi
        ln -s "$DOTFILES_DIR/zshrc" "$ZSHRC_TARGET"
        echo "Symlinked zshrc → $ZSHRC_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/zshrc does not exist"
    fi
}

# Execute
install_packages
install_neovim_from_github_release
install_oh_my_zsh
set_zsh_as_default
install_nodejs
install_tpm
install_fonts
create_api_config
symlink_dotfiles

echo "Installation and setup complete. Please restart your terminal or log out and back in."
