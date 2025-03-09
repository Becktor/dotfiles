#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting installation..."

# Detect OS (Linux or macOS)
OS="$(uname -s)"

install_packages() {
    case "$OS" in
        Linux)
            echo "Detected Linux. Installing prerequisites..."
            sudo apt-get update
            sudo apt-get install -y ninja-build gettext cmake curl build-essential tmux
            ;;
        Darwin)
            echo "Detected macOS. Installing prerequisites..."
            if ! command -v brew &>/dev/null; then
                echo "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install ninja gettext cmake curl tmux
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_packages

# Clone or update Neovim
NEOVIM_DIR="$HOME/neovim"
if [ -d "$NEOVIM_DIR" ]; then
    echo "Neovim directory already exists. Pulling latest changes..."
    git -C "$NEOVIM_DIR" pull origin master
else
    echo "Cloning Neovim repository..."
    git clone https://github.com/neovim/neovim.git "$NEOVIM_DIR"
fi

# Build and install Neovim
cd "$NEOVIM_DIR"
make CMAKE_BUILD_TYPE=Release
sudo make install

# Symlink configuration files
echo "Symlinking configuration files..."
DOTFILES_DIR="$(pwd)"  # Assuming script is run from dotfiles repo

declare -A CONFIG_DIRS=(
    ["nvim"]="$HOME/.config/nvim"
    ["tmux"]="$HOME/.config/tmux"
    ["wezterm"]="$HOME/.config/wezterm"
    ["ncspot"]="$HOME/.config/ncspot"
)

for dir in "${!CONFIG_DIRS[@]}"; do
    TARGET="${CONFIG_DIRS[$dir]}"
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        echo "Skipping $dir: symlink already exists at $TARGET"
    else
        ln -s "$DOTFILES_DIR/$dir" "$TARGET"
        echo "Symlinked $dir → $TARGET"
    fi
done

echo "Installation and setup complete."

