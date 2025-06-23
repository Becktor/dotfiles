return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  config = function()
    vim.keymap.set('n', '<C-h>', ':TmuxNavigateLeft<CR>', { desc = 'Navigate left (tmux-aware)' })
    vim.keymap.set('n', '<C-l>', ':TmuxNavigateRight<CR>', { desc = 'Navigate right (tmux-aware)' })
    vim.keymap.set('n', '<C-j>', ':TmuxNavigateDown<CR>', { desc = 'Navigate down (tmux-aware)' })
    vim.keymap.set('n', '<C-k>', ':TmuxNavigateUp<CR>', { desc = 'Navigate up (tmux-aware)' })
  end,
}
