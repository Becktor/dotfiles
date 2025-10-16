# Dotfiles Merge TODO

Merging personal dotfiles with fresh omarchy install.

## Phase 1: Copy Omarchy Configs to Dotfiles

- [x] 1. Backup current dotfiles hypr directory
- [x] 2. Copy omarchy's hyprland config → `~/git/dotfiles/hypr/`
- [x] 3. Modify `hypr/input.conf` to set caps lock as control
- [x] 4. Backup current dotfiles waybar directory
- [x] 5. Copy omarchy's waybar config → `~/git/dotfiles/waybar/`

## Phase 2: Keep Your Personal Configs

- [x] 6. Keep your neovim config (already in dotfiles)
- [x] 7. Keep your kitty config (already in dotfiles)
- [x] 8. Keep your tmux config (already in dotfiles)
- [x] 9. Keep your git config (already in dotfiles)
- [x] 10. Keep other tools (ncspot, wezterm, etc.)

## Phase 3: Update Install Script

- [x] 11. Review and update `install.sh` for proper symlink creation
- [x] 12. Ensure install.sh handles hypr, waybar, nvim, kitty, etc.

## Phase 4: Deploy Configs

- [x] 13. Run `install.sh` to create symlinks from dotfiles to ~/.config/
- [x] 14. Verify all symlinks are correct
- [x] 15. Test Hyprland reload
- [x] 16. Test waybar
- [x] 17. Test neovim

## Notes
- Keeping: omarchy's hyprland, omarchy's waybar, walker launcher
- Replacing: neovim with personal config
- Using: personal kitty, tmux, git, and other tool configs
- Theme: Tokyo Night (both systems already use it!)

---

## ✅ MERGE COMPLETE!

All tasks completed successfully:
- Omarchy's Hyprland config copied to dotfiles (with caps lock → control fix)
- Omarchy's waybar copied to dotfiles
- Your neovim, kitty, tmux, and other configs preserved
- All configs symlinked from ~/git/dotfiles/ to ~/.config/
- Hyprland reloaded successfully
- Waybar restarted successfully
- Neovim installing plugins correctly
- Caps lock confirmed working as control modifier
- Tmux config updated to work with both bash and zsh (uses $SHELL)
