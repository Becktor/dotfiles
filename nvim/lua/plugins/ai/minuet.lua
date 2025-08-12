return {
  {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('minuet').setup {
        provider = 'openai',
        notify = 'warn', -- Only show warnings and errors
        request_timeout = 3, -- Reduce timeout for faster failures
        context_window = 512, -- Smaller context = faster responses
        debounce = 300, -- Trigger completion after 300ms of inactivity (default is 500)
        provider_options = {
          openai = {
            model = 'gpt-4.1-nano',
            stream = true,
            api_key = 'OPENAI_API_KEY',
            optional = {
              max_tokens = 256, -- Limit response length for speed
              temperature = 0.3, -- Lower temperature for more focused completions
            },
          },
        },
        virtualtext = {
          auto_trigger_ft = { '.lua', '.py', '.vue', '.ts', '.js', '.jsx', '.tsx' }, -- Limit to specific file extensions
          show_on_completion_menu = true,
          keymap = {
            accept = '<A-A>', -- accept whole completion
            accept_line = '<A-a>', -- accept one line
            prev = '<A-[>', -- cycle to prev completion item
            next = '<A-]>', -- cycle to next completion item
            dismiss = '<A-e>',
          },
        },
      }

      -- Register keybindings with which-key
      local wk = require 'which-key'
      wk.add {
        { '<A-y>', desc = 'Minuet: Invoke completion', mode = { 'i' } },
        { '<A-A>', desc = 'Minuet: Accept whole completion', mode = { 'i' } },
        { '<A-a>', desc = 'Minuet: Accept one line', mode = { 'i' } },
        { '<A-z>', desc = 'Minuet: Accept n lines', mode = { 'i' } },
        { '<A-[>', desc = 'Minuet: Previous suggestion', mode = { 'i' } },
        { '<A-]>', desc = 'Minuet: Next suggestion', mode = { 'i' } },
        { '<A-e>', desc = 'Minuet: Dismiss', mode = { 'i' } },
      }

      -- Create manual trigger keybindings for virtual text
      -- Try both <A-y> and <M-y> as they can be interpreted differently
      vim.keymap.set('i', '<A-y>', function()
        vim.cmd 'Minuet virtualtext toggle'
      end, { desc = 'Minuet: Toggle virtual text completion' })
    end,
  },
}
