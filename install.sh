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

# Helper to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

install_packages() {
    # Check which tools are missing
    MISSING=()
    command_exists git || MISSING+=(git)
    command_exists ninja || MISSING+=(ninja)
    command_exists cmake || MISSING+=(cmake)
    command_exists curl || MISSING+=(curl)
    command_exists tmux || MISSING+=(tmux)
    command_exists unzip || MISSING+=(unzip)
    command_exists jq || MISSING+=(jq)
    command_exists rg || MISSING+=(rg)
    command_exists fd || MISSING+=(fd)
    command_exists fzf || MISSING+=(fzf)
    command_exists tree || MISSING+=(tree)
    command_exists htop || MISSING+=(htop)

    if [ ${#MISSING[@]} -eq 0 ]; then
        echo "All required packages already installed. Skipping."
        return
    fi

    echo "Missing tools: ${MISSING[*]}"

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
                    echo "Detected Debian/Ubuntu."

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

                    # Build package list from missing tools
                    PKGS=()
                    for m in "${MISSING[@]}"; do
                        case "$m" in
                            git) PKGS+=(git) ;;
                            ninja) PKGS+=(ninja-build) ;;
                            cmake) PKGS+=(cmake) ;;
                            curl) PKGS+=(curl) ;;
                            tmux) PKGS+=(tmux) ;;
                            unzip) PKGS+=(unzip) ;;
                            jq) PKGS+=(jq) ;;
                            rg) PKGS+=(ripgrep) ;;
                            fd) PKGS+=(fd-find) ;;
                            fzf) PKGS+=(fzf) ;;
                            tree) PKGS+=(tree) ;;
                            htop) PKGS+=(htop) ;;
                        esac
                    done

                    echo "Installing: ${PKGS[*]}"
                    sudo apt-get install -y "${PKGS[@]}"
                    ;;
                arch)
                    echo "Detected Arch Linux."

                    # Build package list from missing tools
                    PKGS=()
                    for m in "${MISSING[@]}"; do
                        case "$m" in
                            git) PKGS+=(git) ;;
                            ninja) PKGS+=(ninja) ;;
                            cmake) PKGS+=(cmake) ;;
                            curl) PKGS+=(curl) ;;
                            tmux) PKGS+=(tmux) ;;
                            unzip) PKGS+=(unzip) ;;
                            jq) PKGS+=(jq) ;;
                            rg) PKGS+=(ripgrep) ;;
                            fd) PKGS+=(fd) ;;
                            fzf) PKGS+=(fzf) ;;
                            tree) PKGS+=(tree) ;;
                            htop) PKGS+=(htop) ;;
                        esac
                    done

                    echo "Installing: ${PKGS[*]}"
                    sudo pacman -Sy --needed --noconfirm "${PKGS[@]}"
                    ;;
                *)
                    echo "Unsupported Linux distribution: $DISTRO"
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            echo "Detected macOS."
            if ! command_exists brew; then
                echo "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            # Build package list from missing tools
            PKGS=()
            for m in "${MISSING[@]}"; do
                case "$m" in
                    git) PKGS+=(git) ;;
                    ninja) PKGS+=(ninja) ;;
                    cmake) PKGS+=(cmake) ;;
                    curl) PKGS+=(curl) ;;
                    tmux) PKGS+=(tmux) ;;
                    unzip) PKGS+=(unzip) ;;
                    jq) PKGS+=(jq) ;;
                    rg) PKGS+=(ripgrep) ;;
                    fd) PKGS+=(fd) ;;
                    fzf) PKGS+=(fzf) ;;
                    tree) PKGS+=(tree) ;;
                    htop) PKGS+=(htop) ;;
                esac
            done

            echo "Installing: ${PKGS[*]}"
            brew install "${PKGS[@]}"
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_neovim_from_github_release() {
    if [ -d "$HOME/.local/share/omarchy" ] && [ "$UPDATE_NVIM" = false ]; then
        echo "Omarchy manages Neovim. Skipping binary install. Use --update-neovim to force."
        return
    fi

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

    if [ -d "$HOME/.local/share/omarchy" ] && [ "$UPDATE_ALL" = false ] && [ "$UPDATE_FONTS" = false ]; then
        echo "Omarchy manages fonts. Skipping font install. Use --update-fonts to force."
        return
    fi

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

backup_existing_path() {
    local target="$1"
    if [ -L "$target" ] || [ -e "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing $target to $backup"
        mv "$target" "$backup"
    fi
}

symlink_dotfiles() {
    echo "Symlinking configuration files..."
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Files in dev-env submodule
    DEVENV_FILES=("nvim" "tmux")
    # Files directly in dotfiles root
    CONFIG_FILES=("alacritty" "ncspot" "hypr" "waybar")

    # Symlink dev-env submodule files
    for dir in "${DEVENV_FILES[@]}"; do
        TARGET="$HOME/.config/$dir"
        backup_existing_path "$TARGET"
        if [ -d "$DOTFILES_DIR/dev-env/$dir" ]; then
            ln -s "$DOTFILES_DIR/dev-env/$dir" "$TARGET"
            echo "Symlinked dev-env/$dir → $TARGET"
        else
            echo "⚠️  Skipping: $DOTFILES_DIR/dev-env/$dir does not exist"
        fi
    done

    # Symlink root config files
    for dir in "${CONFIG_FILES[@]}"; do
        TARGET="$HOME/.config/$dir"
        backup_existing_path "$TARGET"
        if [ -d "$DOTFILES_DIR/$dir" ]; then
            ln -s "$DOTFILES_DIR/$dir" "$TARGET"
            echo "Symlinked $dir → $TARGET"
        else
            echo "⚠️  Skipping: $DOTFILES_DIR/$dir does not exist"
        fi
    done

    # Symlink bashrc
    BASHRC_TARGET="$HOME/.bashrc"
    if [ -f "$DOTFILES_DIR/bash/bashrc" ]; then
        backup_existing_path "$BASHRC_TARGET"
        ln -s "$DOTFILES_DIR/bash/bashrc" "$BASHRC_TARGET"
        echo "Symlinked bash/bashrc → $BASHRC_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/bash/bashrc does not exist"
    fi

    # Symlink bash_profile
    BASH_PROFILE_TARGET="$HOME/.bash_profile"
    if [ -f "$DOTFILES_DIR/bash/bash_profile" ]; then
        backup_existing_path "$BASH_PROFILE_TARGET"
        ln -s "$DOTFILES_DIR/bash/bash_profile" "$BASH_PROFILE_TARGET"
        echo "Symlinked bash/bash_profile → $BASH_PROFILE_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/bash/bash_profile does not exist"
    fi

    # Symlink git config
    GITCONFIG_TARGET="$HOME/.gitconfig"
    if [ -f "$DOTFILES_DIR/git/gitconfig" ]; then
        backup_existing_path "$GITCONFIG_TARGET"
        ln -s "$DOTFILES_DIR/git/gitconfig" "$GITCONFIG_TARGET"
        echo "Symlinked git/gitconfig → $GITCONFIG_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/git/gitconfig does not exist"
    fi

    # Symlink pyrightconfig.json
    PYRIGHT_TARGET="$HOME/pyrightconfig.json"
    if [ -f "$DOTFILES_DIR/pyrightconfig.json" ]; then
        backup_existing_path "$PYRIGHT_TARGET"
        ln -s "$DOTFILES_DIR/pyrightconfig.json" "$PYRIGHT_TARGET"
        echo "Symlinked pyrightconfig.json → $PYRIGHT_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/pyrightconfig.json does not exist"
    fi

    # Symlink xdg-terminal-exec preference list
    XDG_TERMINALS_TARGET="$HOME/.config/xdg-terminals.list"
    if [ -f "$DOTFILES_DIR/xdg-terminals.list" ]; then
        backup_existing_path "$XDG_TERMINALS_TARGET"
        ln -s "$DOTFILES_DIR/xdg-terminals.list" "$XDG_TERMINALS_TARGET"
        echo "Symlinked xdg-terminals.list → $XDG_TERMINALS_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/xdg-terminals.list does not exist"
    fi

    # Symlink markdownlint config
    MARKDOWNLINT_TARGET="$HOME/.markdownlint-cli2.jsonc"
    if [ -f "$DOTFILES_DIR/.markdownlint-cli2.jsonc" ]; then
        backup_existing_path "$MARKDOWNLINT_TARGET"
        ln -s "$DOTFILES_DIR/.markdownlint-cli2.jsonc" "$MARKDOWNLINT_TARGET"
        echo "Symlinked .markdownlint-cli2.jsonc → $MARKDOWNLINT_TARGET"
    else
        echo "⚠️  Skipping: $DOTFILES_DIR/.markdownlint-cli2.jsonc does not exist"
    fi
}

install_omarchy_themes() {
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ ! -d "$HOME/.local/share/omarchy" ] || [ ! -d "$DOTFILES_DIR/omarchy/themes" ]; then
        return
    fi

    echo "Installing Omarchy theme overlays..."
    mkdir -p "$HOME/.config/omarchy/themes"
    cp -a "$DOTFILES_DIR/omarchy/themes/." "$HOME/.config/omarchy/themes/"

    if command_exists omarchy && [ -f "$HOME/.config/omarchy/current/theme.name" ]; then
        CURRENT_THEME=$(cat "$HOME/.config/omarchy/current/theme.name")
        if [ -d "$DOTFILES_DIR/omarchy/themes/$CURRENT_THEME" ]; then
            echo "Reapplying Omarchy theme overlay: $CURRENT_THEME"
            omarchy theme set "$CURRENT_THEME"
        fi
    fi
}

reload_hyprland() {
    if command_exists hyprctl; then
        echo "Reloading Hyprland config..."
        hyprctl reload || true
        hyprctl configerrors || true
    fi
}

setup_ssh_key() {
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo ""
        echo "🔑 SSH Key Setup"
        read -p "Would you like to generate a new SSH key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter your email for the SSH key: " email
            if [ -n "$email" ]; then
                ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519"
                echo "✅ SSH key generated at ~/.ssh/id_ed25519"
                echo "📋 Add this public key to your GitHub/GitLab account:"
                echo "   cat ~/.ssh/id_ed25519.pub"
            else
                echo "⚠️  Email required for SSH key generation. Skipping."
            fi
        fi
    else
        echo "✅ SSH key already exists."
    fi
}

init_submodules() {
    echo "Initializing git submodules..."
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
}

# Execute
init_submodules
install_packages
install_neovim_from_github_release
install_nodejs
install_tpm
install_fonts
symlink_dotfiles
install_omarchy_themes
reload_hyprland
setup_ssh_key

echo "✅ Installation and setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Restart your terminal or log out and back in"
echo "   2. In tmux, press <prefix>I to install tmux plugins"
