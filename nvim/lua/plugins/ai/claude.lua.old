return {
  'greggh/claude-code.nvim',
  enabled = false, -- Disable the Claude plugin
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required for git operations
    'folke/which-key.nvim',
  },
  config = function()
    require('claude-code').setup {
      -- Terminal window settings
      window = {
        split_ratio = 0.3, -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
        position = 'vertical', -- Position of the window: "botright", "topleft", "vertical", "rightbelow vsplit", etc.
        enter_insert = true, -- Whether to enter insert mode when opening Claude Code
        hide_numbers = true, -- Hide line numbers in the terminal window
        hide_signcolumn = true, -- Hide the sign column in the terminal window
      },
      -- File refresh settings
      refresh = {
        enable = true, -- Enable file change detection
        updatetime = 100, -- updatetime when Claude Code is active (milliseconds)
        timer_interval = 1000, -- How often to check for file changes (milliseconds)
        show_notifications = true, -- Show notification when files are reloaded
      },
      -- Git project settings
      git = {
        use_git_root = true, -- Set CWD to git root when opening Claude Code (if in git project)
      },
      -- Shell-specific settings
      shell = {
        separator = '&&', -- Command separator used in shell commands
        pushd_cmd = 'pushd', -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
        popd_cmd = 'popd', -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
      },
      -- Command settings
      command = 'claude', -- Command used to launch Claude Code
      -- Command variants
      command_variants = {
        -- Conversation management
        continue = '--continue', -- Resume the most recent conversation
        resume = '--resume', -- Display an interactive conversation picker

        -- Output options
        verbose = '--verbose', -- Enable verbose logging with full turn-by-turn output
      },
      -- Keymaps
      keymaps = {
        toggle = {
          normal = '<leader>cc', -- Normal mode keymap for toggling Claude Code, false to disable
          terminal = '<leader>ct', --'<C-/>', -- Terminal mode keymap for toggling Claude Code, false to disable
          variants = {
            continue = '<leader>cC', -- Normal mode keymap for Claude Code with continue flag
            verbose = '<leader>cV', -- Normal mode keymap for Claude Code with verbose flag
          },
        },
        window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
        scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
      },
    }

    local wk = require 'which-key'

    -- Helper function to toggle with temporary position
    local function toggle_with_position(position)
      local original_position = require('claude-code').config.window.position
      require('claude-code').config.window.position = position
      require('claude-code').toggle()
      require('claude-code').config.window.position = original_position
    end

    -- Custom keymaps for different split types
    vim.keymap.set('n', '<leader>ch', function()
      toggle_with_position 'vertical'
    end, { desc = 'Claude Code Horizontal Split' })
    vim.keymap.set('n', '<leader>cv', function()
      toggle_with_position 'rightbelow'
    end, { desc = 'Claude Code Vertical Split' })
    vim.keymap.set('n', '<leader>cr', function()
      require('claude-code').toggle { resume = true }
    end, { desc = 'Claude Code Resume' })

    wk.add {
      { '<leader>c', group = 'Claude Code' },
      { '<leader>ct', desc = 'Toggle Terminal Mode' },
      { '<leader>cC', desc = 'Continue Last' },
      { '<leader>cV', desc = 'Verbose Mode' },
      { '<leader>ch', desc = 'Horizontal Split' },
      { '<leader>cv', desc = 'Vertical Split' },
      { '<leader>cr', desc = 'Resume Picker' },
    }
  end,
}
