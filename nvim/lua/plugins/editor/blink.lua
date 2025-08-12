return {
  'saghen/blink.cmp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',
  build = 'cargo build --release',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },
    appearance = {
      nerd_font_variant = 'mono',
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    completion = {
      trigger = { prefetch_on_insert = false },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    fuzzy = { 
      prebuilt_binaries = {
        download = true,
      },
    },
  },
}
