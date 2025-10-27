vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = vim.api.nvim_create_augroup('last_cursor_pos', { clear = true }),
  desc = 'return cursor to where it was last time closing the file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})

-- Markdown wrap at 80 characters
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('markdown_wrap', { clear = true }),
  desc = 'Enable wrap at 80 chars for markdown files',
  pattern = { 'markdown', 'md' },
  callback = function(args)
    vim.opt_local.textwidth = 80
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.colorcolumn = '80'

    -- Disable virtual_text for markdown to reduce clutter
    -- Diagnostics still visible via signs and hover (K key or mouse hover)
    vim.diagnostic.config({
      virtual_text = false,
    }, args.buf)
  end,
})
