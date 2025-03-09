return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  config = function()
    vim.keymap.set('n', 'C-h', ':TmuxNavigateLeft<CR>', { desc = 'Window left' })
    vim.keymap.set('n', 'C-l', ':TmuxNavigateRight<CR>', { desc = 'Window right' })
    vim.keymap.set('n', 'C-j', ':TmuxNavigateDown<CR>', { desc = 'Window down' })
    vim.keymap.set('n', 'C-k', ':TmuxNavigateUp<CR>', { desc = 'Window up' })
  end,
}
