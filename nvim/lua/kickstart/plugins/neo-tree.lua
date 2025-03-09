-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
local function sources()
  return {
    'filesystem',
    'buffers',
    'git_status',
    'document_symbols',
    'netman.ui.neo-tree', -- The one you really care about 😉
  }
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
    'miversen33/netman.nvim',
  },

  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    sources(),
    close_if_last_window = true,
    source_selector = {
      winbar = true,
      sources = {
        { source = 'filesystem', display_name = ' 󰉓 File ' },
        { source = 'git_status', display_name = ' 󰊢 Git ' },
        { source = 'buffers', display_name = ' 󰓩 Buf ' },
        { source = 'netman.ui.neo-tree', display_name = ' 󰉓 Remote ' },
      },
      content_layout = 'center',
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
