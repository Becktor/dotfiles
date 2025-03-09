 #!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Install prerequisites
echo "Installing prerequisites..."
#sudo apt-get update
#sudo apt-get install -y ninja-build gettext cmake curl build-essential tmux

# Clone Neovim into home directory
NEOVIM_DIR="$HOME/neovim"
if [ -d "$NEOVIM_DIR" ]; then
    echo "Neovim directory already exists. Pulling latest changes."
    cd "$NEOVIM_DIR" && git pull origin master
else
    echo "Cloning Neovim repository..."
    git clone https://github.com/neovim/neovim.git "$NEOVIM_DIR"
fi

# Build Neovim
cd "$NEOVIM_DIR"
make CMAKE_BUILD_TYPE=Release
sudo make install

# Symlink configuration files
echo "Symlinking configuration files..."
DOTFILES_DIR=$(PWD)
# Symlink neovim
ln -s "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
# Symlink tmux
ln -s "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
echo "Installation and setup complete."

