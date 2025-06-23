-- Bootstrap Neovim configuration
-- This is a minimal init.lua that loads the modular configuration

-- Load core settings
require 'config.options'
require 'config.keymaps'
require 'config.autocmds'

-- Bootstrap and configure plugins
require 'config.lazy'

-- Load custom configurations
require 'custom.autocmds'
require 'custom.keymaps'
require 'custom.diagnostic'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et