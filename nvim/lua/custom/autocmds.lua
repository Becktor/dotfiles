vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = vim.api.nvim_create_augroup('last_cursor_pos', { clear = true }),
  desc = 'return cursor to where it was last time closing the file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})

-- Close quickfix window after selecting an item
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('quickfix_close', { clear = true }),
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>:cclose<CR>', { buffer = true, silent = true })
  end,
})
