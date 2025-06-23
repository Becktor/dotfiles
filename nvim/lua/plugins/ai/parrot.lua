return {
  'frankroeder/parrot.nvim',
  dependencies = {
    'ibhagwan/fzf-lua',
    'nvim-lua/plenary.nvim',
    'folke/which-key.nvim',
  },
  config = function()
    local parrot = require 'parrot'
    local hook = require 'plugins.ai.hooks.parrot_hooks'

    parrot.setup {
      providers = {
        openai = {
          name = 'openai',
          api_key = os.getenv 'OPENAI_API_KEY',
          endpoint = 'https://api.openai.com/v1/chat/completions',
          params = {
            chat = { temperature = 1.1, top_p = 1 },
            command = { temperature = 1.1, top_p = 1 },
          },
          topic = {
            model = 'gpt-4.1-nano',
            params = { max_completion_tokens = 64 },
          },
          models = {
            'gpt-4o',
            'o4-mini',
            'gpt-4.1-nano',
          },
        },
        anthropic = {
          name = 'anthropic',
          endpoint = 'https://api.anthropic.com/v1/messages',
          model_endpoint = 'https://api.anthropic.com/v1/models',
          api_key = os.getenv 'ANTHROPIC_API_KEY',
          params = {
            chat = { max_tokens = 4096 },
            command = { max_tokens = 4096 },
          },
          topic = {
            model = 'claude-3-5-haiku-latest',
            params = { max_tokens = 32 },
          },
          headers = function(self)
            return {
              ['Content-Type'] = 'application/json',
              ['x-api-key'] = self.api_key,
              ['anthropic-version'] = '2023-06-01',
            }
          end,
          models = {
            'claude-sonnet-4-20250514',
            'claude-3-7-sonnet-20250219',
            'claude-3-5-sonnet-20241022',
            'claude-3-5-haiku-20241022',
          },
          preprocess_payload = function(payload)
            for _, message in ipairs(payload.messages) do
              message.content = message.content:gsub('^%s*(.-)%s*$', '%1')
            end
            if payload.messages[1] and payload.messages[1].role == 'system' then
              payload.system = payload.messages[1].content
              table.remove(payload.messages, 1)
            end
            return payload
          end,
        },
      },
      hooks = hook,
    }

    local wk = require 'which-key'

    wk.add {
      { '<C-g>c', '<cmd>PrtChatNew<cr>', mode = { 'n', 'i' }, desc = 'New Chat' },
      { '<C-g>c', ":<C-u>'<,'>PrtChatNew<cr>", mode = { 'v' }, desc = 'Visual Chat New' },
      { '<C-g>t', '<cmd>PrtChatToggle<cr>', mode = { 'n', 'i' }, desc = 'Toggle Popup Chat' },
      { '<C-g>f', '<cmd>PrtChatFinder<cr>', mode = { 'n', 'i' }, desc = 'Chat Finder' },
      { '<C-g>r', '<cmd>PrtRewrite<cr>', mode = { 'n', 'i' }, desc = 'Inline Rewrite' },
      { '<C-g>r', ":<C-u>'<,'>PrtRewrite<cr>", mode = { 'v' }, desc = 'Visual Rewrite' },
      { '<C-g>j', '<cmd>PrtRetry<cr>', mode = { 'n' }, desc = 'Retry rewrite/append/prepend command' },
      { '<C-g>a', '<cmd>PrtAppend<cr>', mode = { 'n', 'i' }, desc = 'Append' },
      { '<C-g>a', ":<C-u>'<,'>PrtAppend<cr>", mode = { 'v' }, desc = 'Visual Append' },
      { '<C-g>o', '<cmd>PrtPrepend<cr>', mode = { 'n', 'i' }, desc = 'Prepend' },
      { '<C-g>o', ":<C-u>'<,'>PrtPrepend<cr>", mode = { 'v' }, desc = 'Visual Prepend' },
      { '<C-g>e', ":<C-u>'<,'>PrtEnew<cr>", mode = { 'v' }, desc = 'Visual Enew' },
      { '<C-g>s', '<cmd>PrtStop<cr>', mode = { 'n', 'i', 'v', 'x' }, desc = 'Stop' },
      { '<C-g>i', ":<C-u>'<,'>PrtComplete<cr>", mode = { 'n', 'i', 'v', 'x' }, desc = 'Complete visual selection' },
      { '<C-g>x', '<cmd>PrtContext<cr>', mode = { 'n' }, desc = 'Open context file' },
      { '<C-g>n', '<cmd>PrtModel<cr>', mode = { 'n' }, desc = 'Select model' },
      { '<C-g>p', '<cmd>PrtProvider<cr>', mode = { 'n' }, desc = 'Select provider' },
      { '<C-g>q', '<cmd>PrtAsk<cr>', mode = { 'n' }, desc = 'Ask a question' },
    }
  end,
}
