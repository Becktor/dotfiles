# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for a development environment centered around Neovim, tmux, Hyprland/Omarchy, Waybar, and terminal tools. The active `chonk` setup targets Arch Linux + Omarchy; the installer still has fallback support for Debian/Ubuntu and macOS.

## Installation and Setup

### Primary Installation Command
```bash
./install.sh
```

### Installation Options
- `./install.sh --update-all` - Force update all components
- `./install.sh --update-neovim` - Update Neovim only
- `./install.sh --update-tpm` - Update tmux plugin manager
- `./install.sh --update-fonts` - Update Nerd Fonts

### Post-Installation Configuration
- API keys are configured in `~/.api_keys` (template created automatically)
- Source API keys in shell: `source ~/.api_keys`
- Configure git user details in `git/gitconfig`

## Architecture and Key Components

### Configuration Structure
- **dev-env/nvim/**: Neovim configuration based on kickstart.nvim (submodule)
- **dev-env/tmux/**: tmux configuration with plugin management (submodule)
- **hypr/**: Chonk Hyprland overrides layered on top of Omarchy defaults
- **waybar/**: Omarchy Waybar config maintained here from Omarchy's base
- **bash/**: Omarchy/bash shell configuration
- **alacritty/**: Omarchy default terminal config, maintained here from Omarchy's base
- **wezterm/**, **kitty/**: Legacy terminal emulator configs; not symlinked on Chonk
- **git/**: Git configuration and aliases
- **zshrc**: Legacy shell configuration kept for non-Omarchy machines

### Neovim Plugin Architecture
The Neovim setup uses lazy.nvim for plugin management with a modular structure:
- Kickstart plugins provide base functionality (LSP, telescope, etc.)
- Custom plugins in `lua/custom/plugins/` extend functionality
- Key custom plugins: parrot.nvim, claude.nvim, oil.nvim, tmux-navigator

### tmux Session Management
- Default session created with `dt` alias (runs `tmux/default-session.sh`)
- Session includes: nvim window, shell window, ncspot music player
- TPM plugins: sensible, yank, resurrect, vim-tmux-navigator

## Common Development Commands

### Neovim Package Management
```bash
# Update all Neovim plugins
:Lazy update

# Check plugin status
:Lazy

# Check health
:checkhealth
```

### tmux Session Management
```bash
# Create/attach to default session
dt

# Save session (custom binding)
<prefix>S

# Restore session (custom binding)  
<prefix>R

# Install/update tmux plugins
<prefix>I
```

### Font and System Setup
```bash
# Refresh font cache (Linux)
fc-cache -fv

# Install Oh My Zsh (if not present)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Configuration Management

### Symlinking Strategy
The install script creates symlinks from `~/.config/` to this repository:
- `~/.config/nvim` → `./dev-env/nvim`
- `~/.config/tmux` → `./dev-env/tmux`
- `~/.config/hypr` → `./hypr`
- `~/.config/waybar` → `./waybar`
- `~/.config/alacritty` → `./alacritty`
- `~/.config/ncspot` → `./ncspot`
- `~/.config/xdg-terminals.list` → `./xdg-terminals.list`

### Key File Locations
- Neovim lazy-lock.json: `dev-env/nvim/lazy-lock.json`
- tmux plugins: `~/.tmux/plugins/` (managed by TPM)
- API keys: `~/.api_keys` (not in repo)
- Shell config on Chonk/Omarchy: `bash/bashrc` (symlinked to `~/.bashrc`)

## Platform-Specific Notes

### Dependencies
- **Chonk / Arch + Omarchy**: pacman packages (`git`, `ninja`, `cmake`, `curl`, `tmux`, `unzip`, `jq`, `ripgrep`, `fd`, `fzf`, `tree`, `htop`) plus Omarchy-provided Hyprland tooling
- **Debian/Ubuntu fallback**: apt packages (`git`, `ninja-build`, `cmake`, `curl`, `tmux`, `unzip`, `jq`, `ripgrep`, `fd-find`, `fzf`, `tree`, `htop`)
- **macOS fallback**: Homebrew packages (`git`, `ninja`, `cmake`, `curl`, `tmux`, `unzip`, `jq`, `ripgrep`, `fd`, `fzf`, `tree`, `htop`)
- **All platforms**: Node.js. On Omarchy, fonts are managed by Omarchy; `./install.sh --update-fonts` can still force the repo font install.

### Neovim Installation
On Chonk/Omarchy, use Omarchy's installed Neovim binary (`/usr/bin/nvim`) and only manage `~/.config/nvim` via the `dev-env/nvim` symlink. `./install.sh --update-neovim` can still force the legacy GitHub-release install path when needed.
