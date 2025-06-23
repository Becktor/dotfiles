# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for a development environment centered around Neovim, tmux, and terminal tools. The setup is cross-platform (Linux/macOS) with automated installation and symlink management.

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
- **nvim/**: Neovim configuration based on kickstart.nvim
  - `init.lua` - Main configuration entry point
  - `lua/kickstart/` - Base kickstart plugins
  - `lua/custom/` - Custom plugins and configurations
- **tmux/**: tmux configuration with plugin management
  - `tmux.conf` - Main tmux configuration
  - `default-session.sh` - Creates default development session
  - `plugins/` - TPM-managed plugins (git submodules)
- **wezterm/**: Terminal emulator configuration
- **git/**: Git configuration and aliases
- **zshrc**: Shell configuration with Oh My Zsh integration

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
- `~/.config/nvim` → `./nvim`
- `~/.config/tmux` → `./tmux`  
- `~/.config/wezterm` → `./wezterm`
- `~/.config/ncspot` → `./ncspot`

### Key File Locations
- Neovim lazy-lock.json: `nvim/lazy-lock.json`
- tmux plugins: `tmux/plugins/` (managed by TPM)
- API keys: `~/.api_keys` (not in repo)
- Shell config: `zshrc` (symlinked to `~/.zshrc`)

## Platform-Specific Notes

### Dependencies
- **Linux**: apt packages (zsh, ninja-build, gettext, cmake, curl, build-essential, tmux, unzip, jq)
- **macOS**: Homebrew packages (zsh, ninja, gettext, cmake, curl, tmux, unzip, jq)
- **Both**: Node.js, Nerd Fonts, Oh My Zsh

### Neovim Installation
Latest stable Neovim is installed from GitHub releases to `/usr/local/nvim/` with symlink to `/usr/local/bin/nvim`.