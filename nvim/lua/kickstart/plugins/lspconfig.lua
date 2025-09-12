return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- Mason must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
    { 'mason-org/mason.nvim', opts = {} },
    { 'mason-org/mason-lspconfig.nvim', opts = {} },

    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    -- 'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

        -- Find references for the word under your cursor.
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

        -- Auto-import helper - shows import completions for word under cursor
        map('<leader>cI', function()
          -- First try standard code actions
          vim.lsp.buf.code_action {
            context = {
              only = { 'source.organizeImports', 'quickfix' },
              diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
            },
          }
        end, '[C]ode [I]mport (Add missing)')

        -- Alternative: Jump to import area and use completion
        map('<leader>cA', function()
          local word = vim.fn.expand '<cword>'
          if word and word ~= '' then
            vim.notify('Add import for: ' .. word .. '\nUse completion at top of file: from/import ' .. word, vim.log.levels.INFO)
            -- Jump to top of file after imports
            vim.cmd 'normal! gg'
            -- Find last import line
            local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
            local last_import_line = 0
            for i, line in ipairs(lines) do
              if line:match '^%s*import ' or line:match '^%s*from ' then
                last_import_line = i
              elseif line:match '^%s*$' and last_import_line > 0 then
                -- Found empty line after imports
                break
              end
            end
            vim.api.nvim_win_set_cursor(0, { last_import_line + 1, 0 })
          end
        end, '[C]ode [A]dd import (manual)')

        -- Organize imports (Python/TypeScript) - using conform.nvim
        map('<leader>ci', function()
          require('conform').format {
            bufnr = vim.api.nvim_get_current_buf(),
            async = false,
            quiet = false,
          }
        end, '[C]ode [I]mports (Organize)')

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
        ---@param client vim.lsp.Client
        ---@param method vim.lsp.protocol.Method
        ---@param bufnr? integer some lsp support methods only in specific files
        ---@return boolean
        local function client_supports_method(client, method, bufnr)
          if vim.fn.has 'nvim-0.11' == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Diagnostic Config
    -- See :help vim.diagnostic.Opts
    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    }

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add completion plugins like Blink, they enhance these capabilities.
    --  Blink handles LSP capabilities automatically, so we use the default capabilities.
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      -- clangd = {},
      -- gopls = {},
      -- basedpyright handled automatically by nvim-lspconfig with overridden settings above
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- Vue TypeScript Language Service
      vtsls = {
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = '/usr/local/lib/node_modules/@vue/language-server',
              languages = { 'vue' },
            },
          },
        },
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      },

      -- Additional web dev servers
      html = {},
      cssls = {},
      eslint = {},

      lua_ls = {
        -- cmd = { ... },
        -- filetypes = { ... },
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in this menu.
    --
    -- `mason` had to be setup earlier: to configure its options see the
    -- `dependencies` table for `nvim-lspconfig` above.
    --
    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
      'isort', -- Python import organizer
      'black', -- Python formatter
      'basedpyright', -- Enhanced Python type checker (fork of pyright)
      'prettierd', -- Fast JavaScript/TypeScript formatter
      'vue-language-server', -- Vue language server
      'typescript-language-server', -- TypeScript language server
      'html-lsp', -- HTML language server
      'css-lsp', -- CSS language server
      'eslint-lsp', -- ESLint language server
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Function to read basedpyright settings from pyproject.toml
    local function get_basedpyright_settings(root_dir)
      local default_settings = {
        basedpyright = {
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = 'openFilesOnly',
            typeCheckingMode = 'basic',
            indexing = true,
            -- include = { 'src' },
            -- exclude = { '**/__pycache__' },
            -- executionEnvironments = { { root = 'src' } },
            autoImportCompletions = true,
            completeFunctionParens = true,
          },
        },
      }

      -- Try to read pyproject.toml
      if root_dir then
        local pyproject_path = root_dir .. '/pyproject.toml'

        local file = io.open(pyproject_path, 'r')
        if file then
          local content = file:read '*all'
          file:close()

          -- Simple parsing for [tool.basedpyright] section
          local basedpyright_section = content:match '%[tool%.basedpyright%](.-)%['
          if not basedpyright_section then
            basedpyright_section = content:match '%[tool%.basedpyright%](.*)$'
          end

          if basedpyright_section then
            -- Parse all settings from pyproject.toml and apply them directly
            -- Match string values (quoted)
            for key, value in basedpyright_section:gmatch '([%w_]+)%s*=%s*["\']([^"\']+)["\']' do
              -- Map pyproject.toml keys to basedpyright LSP config structure
              if key == 'diagnosticMode' or key == 'typeCheckingMode' then
                default_settings.basedpyright.analysis[key] = value
              elseif key:match '^report%w+' then
                -- All diagnostic settings go into diagnosticSeverityOverrides
                if not default_settings.basedpyright.analysis.diagnosticSeverityOverrides then
                  default_settings.basedpyright.analysis.diagnosticSeverityOverrides = {}
                end
                default_settings.basedpyright.analysis.diagnosticSeverityOverrides[key] = value
              end
            end

            -- Match boolean values
            for key, value in basedpyright_section:gmatch '([%w_]+)%s*=%s*(true|false)' do
              if
                key == 'autoSearchPaths'
                or key == 'useLibraryCodeForTypes'
                or key == 'indexing'
                or key == 'autoImportCompletions'
                or key == 'completeFunctionParens'
              then
                default_settings.basedpyright.analysis[key] = value == 'true'
              end
            end

            -- Match arrays for include/exclude
            for key, array_content in basedpyright_section:gmatch '([%w_]+)%s*=%s*%[([^%]]+)%]' do
              if key == 'include' or key == 'exclude' then
                local items = {}
                for item in array_content:gmatch '["\']([^"\']+)["\']' do
                  table.insert(items, item)
                end
                default_settings.basedpyright.analysis[key] = items
              end
            end
          end

          -- Auto-detect virtual environment
          local venv_paths = {
            root_dir .. '/.venv', -- Same level as pyproject.toml
            root_dir .. '/../.venv', -- One level up
            root_dir .. '/venv', -- Alternative naming
            root_dir .. '/../venv', -- Alternative naming one level up
          }

          for _, venv_path in ipairs(venv_paths) do
            local python_exe = venv_path .. (vim.fn.has 'win32' == 1 and '/Scripts/python.exe' or '/bin/python')
            if vim.fn.executable(python_exe) == 1 then
              -- Set python path at top level (legacy)
              default_settings.python = { pythonPath = python_exe }

              -- Also set in basedpyright analysis settings (recommended)
              default_settings.basedpyright.analysis.pythonPath = python_exe
              default_settings.basedpyright.analysis.venvPath = venv_path:match '(.+)/.+$' -- Parent directory of venv

              -- Update execution environment with python path
              if default_settings.basedpyright.analysis.executionEnvironments and default_settings.basedpyright.analysis.executionEnvironments[1] then
                default_settings.basedpyright.analysis.executionEnvironments[1].pythonPath = python_exe
              end
              break
            end
          end
        end
      end

      return default_settings
    end

    -- Configure basedpyright using Neovim 0.11+ native vim.lsp.config() API
    vim.lsp.config('basedpyright', {
      cmd = { 'basedpyright-langserver', '--stdio' },
      filetypes = { 'python' },
      root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
      settings = get_basedpyright_settings(vim.fs.root(0, { 'pyproject.toml', 'setup.py', '.git' })),
      capabilities = capabilities,
    })

    -- Enable basedpyright with the native API
    vim.lsp.enable 'basedpyright'

    require('mason-lspconfig').setup {
      automatic_installation = false, -- Keep this disabled since we use mason-tool-installer
      handlers = {
        function(server_name)
          -- Skip basedpyright since we're handling it with native vim.lsp.config()
          if server_name == 'basedpyright' then
            return
          end

          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for ts_ls)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }

    -- Vue.js official setup from their wiki
    local vue_language_server_path = vim.fn.expand '$HOME/.local/share/nvim/mason/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'

    local vue_plugin = {
      name = '@vue/typescript-plugin',
      location = vue_language_server_path,
      languages = { 'vue' },
      configNamespace = 'typescript',
    }

    local vtsls_config = {
      settings = {
        vtsls = {
          tsserver = {
            globalPlugins = {
              vue_plugin,
            },
          },
        },
      },
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    }

    local vue_ls_config = {
      on_init = function(client)
        client.handlers['tsserver/request'] = function(_, result, context)
          local clients = vim.lsp.get_clients { bufnr = context.bufnr, name = 'vtsls' }
          if #clients == 0 then
            vim.notify('Could not find `vtsls` lsp client, `vue_ls` would not work without it.', vim.log.levels.ERROR)
            return
          end
          local ts_client = clients[1]

          local param = unpack(result)
          local id, command, payload = unpack(param)
          ts_client:exec_cmd({
            title = 'vue_request_forward',
            command = 'typescript.tsserverRequest',
            arguments = {
              command,
              payload,
            },
          }, { bufnr = context.bufnr }, function(_, r)
            local response = r and r.body
            local response_data = { { id, response } }
            client:notify('tsserver/response', response_data)
          end)
        end
      end,
    }

    -- Setup Vue LSP (Neovim 0.11+ syntax)
    if vim.fn.has 'nvim-0.11' == 1 then
      vim.lsp.config('vtsls', vtsls_config)
      vim.lsp.config('vue_ls', vue_ls_config)
      vim.lsp.enable { 'vtsls', 'vue_ls' }
    else
      -- Fallback for older Neovim versions
      require('lspconfig').vtsls.setup(vtsls_config)
      require('lspconfig').vue_ls.setup(vue_ls_config)
    end
  end,
}
