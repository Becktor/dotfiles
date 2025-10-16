#!/bin/bash
set -e

echo "Installing only missing components for omarchy system..."
echo "(Omarchy uses bash, so skipping zsh components)"

# Install tmux if missing
if ! command -v tmux &>/dev/null; then
    echo "Installing tmux..."
    sudo pacman -S --needed --noconfirm tmux
else
    echo "✓ tmux already installed"
fi

# Install TPM (tmux plugin manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "✓ TPM already installed"
fi

# Install Nerd Fonts
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [ ! -f "$FONT_DIR/0xProto Nerd Font Complete.ttf" ]; then
    echo "Installing Nerd Fonts..."
    curl -L -o "/tmp/nerdfonts.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/0xProto.zip"
    unzip -o "/tmp/nerdfonts.zip" -d "$FONT_DIR"
    fc-cache -fv
else
    echo "✓ Nerd Fonts already installed"
fi

# Create API keys file
CONFIG_FILE="$HOME/.api_keys"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating API keys template..."
    cat <<EOF > "$CONFIG_FILE"
# API keys (edit these)
export OPENAI_API_KEY=""
export GEMINI_API_KEY=""
export ANTHROPIC_API_KEY=""
EOF
    chmod 600 "$CONFIG_FILE"
    echo "✓ Created $CONFIG_FILE"
else
    echo "✓ API keys file already exists"
fi

echo ""
echo "✅ Missing components installed!"
echo ""
echo "Next steps:"
echo "  1. In tmux, press <prefix>I to install tmux plugins"
echo "  2. Edit ~/.api_keys to add your API keys"
echo "  3. Omarchy is using bash - your zshrc won't be used unless you switch shells"
