-- SECTION 1: FOUNDATION Core Neovim settings, leaders, options, basic keymaps, basic autocmds
do
  vim.loader.enable() -- Enable faster startup by caching compiled Lua modules

  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  vim.g.have_nerd_font = true

  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.mouse = 'a'
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 150
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 10

  vim.o.confirm = true

  vim.keymap.set('n', '<leader>Q', '<cmd>qa<cr>', { desc = 'Quit All' })

  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = { current_line = true }, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- SECTION 2: PLUGIN MANAGER INTRO vim.pack intro, build hooks
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
          run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
        end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

-- SECTION 3: UI / CORE UX PLUGINS guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
do
  vim.pack.add { 'https://github.com/NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- See `:help gitsigns` to understand what each configuration key does.
  vim.pack.add { 'https://github.com/lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  vim.pack.add { 'https://github.com/folke/which-key.nvim' }
  require('which-key').setup {
    delay = 100,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>d', group = '[D]ebug/Document' },
      { '<leader>g', group = '[G]it' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
      { '<leader>m', group = '[M]isc' },
      { '<leader>u', group = '[U]I' },
      { '<leader>r', group = '[R]efactor' },
    },
  }

  vim.pack.add { 'https://github.com/neanias/everforest-nvim' }
  require('everforest').setup {
    background = 'soft',
    ui_contrast = 'high',
  }
  vim.cmd.colorscheme 'everforest'

  vim.pack.add { 'https://github.com/folke/todo-comments.nvim' }
  require('todo-comments').setup {
    signs = false,

    keywords = {
      FIX = {
        icon = ' ', -- icon used for the sign, and in search results
        color = 'error', -- can be a hex color, or a named color (see below)
        alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'fix' }, -- a set of other keywords that all map to this FIX keywords
        -- signs = false, -- configure signs for some keywords individually
      },
      TODO = { icon = ' ', color = 'info', alt = { 'todo' } },
      HACK = { icon = ' ', color = 'warning', alt = { 'hack' } },
      WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX', 'warn' } },
      PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE', 'perf' } },
      NOTE = { icon = ' ', color = 'hint', alt = { 'INFO', 'info' } },
      TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED', 'test' } },
    },
  }

  vim.pack.add { 'https://github.com/nvim-mini/mini.nvim' }

  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons() -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  statusline.section_location = function() return '%2l:%-2v' end
end

-- SECTION 4: SEARCH & NAVIGATION Telescope setup, keymaps, LSP picker mappings
do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then
    table.insert(telescope_plugins, 'https://github.com/nvim-telescope/telescope-fzf-native.nvim')
  end
  vim.pack.add(telescope_plugins)
  local ignored_files = { './^.git/*', './node_modules/*', 'node_modules', '^node_modules/*', 'node_modules/*' }
  require('telescope').setup {
    defaults = {
      path_display = {
        filename_first = {
          reverse_directories = false,
        },
      },
      file_ignore_patterns = {},
    },
    pickers = {
      find_files = {
        hidden = true,
        file_ignore_patterns = ignored_files,
      },
      live_grep = {
        additional_args = function() return { '--hidden' } end,
        file_ignore_patterns = ignored_files,
      },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord or selection' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set(
    'n',
    '<leader>s.',
    function() builtin.oldfiles { only_cwd = true } end,
    { desc = '[S]earch Recent Files ("." for repeat)' }
  )
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set(
        'n',
        'gW',
        builtin.lsp_dynamic_workspace_symbols,
        { buffer = buf, desc = 'Open Workspace Symbols' }
      )
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })
  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )
  vim.keymap.set(
    'n',
    '<leader>sn',
    function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end,
    { desc = '[S]earch [N]eovim files' }
  )
end

-- SECTION 5: LSP LSP keymaps, server configuration, Mason tools installations
do
  -- [[ LSP Configuration ]]
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
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  -- Useful status updates for LSP.
  vim.pack.add { 'https://github.com/j-hui/fidget.nvim' }
  require('fidget').setup {}

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

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
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
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map(
          '<leader>th',
          function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end,
          '[T]oggle Inlay [H]ints'
        )
      end
    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    stylua = {}, -- Used to format Lua code

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if
            path ~= vim.fn.stdpath 'config'
            and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
          then
            return
          end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end

  vim.pack.add { 'https://github.com/pmizio/typescript-tools.nvim' }
  require('typescript-tools').setup {
    dependencies = { 'nvim-lua/plenary.nvim' },
  }

  vim.lsp.enable 'angularls'
  vim.lsp.enable 'cssls'
  -- TODO: Add emmet abbreviation
  vim.lsp.enable 'html'
end

-- SECTION 6: FORMATTING conform.nvim setup and keymap
do
  -- [[ Formatting ]]
  vim.pack.add { 'https://github.com/stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        lua = true,
        typescript = true,
        html = true,
        angular = true,
        scss = true,
      }

      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 1500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      lua = { 'stylua' },
      htmlangular = { 'prettierd' },
      html = { 'prettierd' },
      angular = { 'prettierd' },
      typescript = { 'prettierd', 'eslint_d' },
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  }

  require('conform').formatters.eslint_d = function()
    local util = require 'conform.util'
    ---@type conform.FileFormatterConfig

    return {
      meta = {
        url = 'https://github.com/mantoni/eslint_d.js/',
        description = 'Like ESLint, but faster.',
      },
      command = util.from_node_modules 'eslint_d',
      args = { '--fix-to-stdout', '--stdin', '--stdin-filename', '$FILENAME' },
      cwd = util.root_file {
        'package.json',
      },
    }
  end

  vim.keymap.set(
    { 'n', 'v' },
    '<leader>f',
    function() require('conform').format { async = true } end,
    { desc = '[F]ormat buffer' }
  )
end

-- SECTION 7: AUTOCOMPLETE & SNIPPETS blink.cmp and luasnip setup
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = 'https://github.com/L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  vim.pack.add { 'https://github.com/rafamadriz/friendly-snippets' }
  require('luasnip.loaders.from_vscode').lazy_load()

  vim.pack.add {
    'https://github.com/benfowler/telescope-luasnip.nvim',
  }
  require('luasnip').setup {
    module = 'telescope._extensions.luasnip', -- if you wish to lazy-load
  }
  require('telescope').load_extension 'luasnip'

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- TODO: Add "Enter as way to apply suggestion"
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'enter',

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- SECTION 8: TREESITTER Parser installation, syntax highlighting, folds, indentation
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers =
    { 'angular', 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- SECTION 9: OPTIONAL EXAMPLES / NEXT STEPS kickstart.plugins.* examples
do
  require 'custom.plugins.init'
  require 'kickstart.plugins.debug'
  require 'kickstart.plugins.indent_line'
  require 'kickstart.plugins.lint'
  require 'kickstart.plugins.autopairs'
  require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  vim.pack.add { 'https://github.com/smoka7/hop.nvim' }
  require('hop').setup {
    tag = '*', -- optional but strongly recommended
    keys = 'etovxqpdygfblzhckisuran',

    case_insensitive = false,
    uppercase_labels = true,
  }
  vim.keymap.set('n', '\\', function() require('hop').hint_words() end, { remap = true })

  vim.pack.add { 'https://github.com/folke/trouble.nvim' }
  vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
  vim.keymap.set(
    'n',
    '<leader>xX',
    '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
    { desc = 'Buffer Diagnostics (Trouble)' }
  )
  vim.keymap.set('n', '<leader>cs', '<cmd>Trouble symbols toggle focus=false<cr>', { desc = 'Symbols (Trouble)' })
  vim.keymap.set(
    'n',
    '<leader>cl',
    '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
    { desc = 'LSP Definitions / references / ... (Trouble)' }
  )
  vim.keymap.set('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>', { desc = 'Location List (Trouble)' })
  vim.keymap.set('n', '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix List (Trouble)' })

  vim.pack.add { 'https://github.com/stevearc/oil.nvim' }
  require('oil').setup {
    float = {
      border = 'single',
    },
  }
  vim.keymap.set('n', '<leader>-', '<cmd>Oil --float<CR>', { desc = 'Quit All' })

  vim.pack.add { 'https://github.com/m4xshen/hardtime.nvim' }
  require('hardtime').setup {
    dependencies = { 'MunifTanjim/nui.nvim' },
  }

  vim.pack.add { 'https://github.com/rcarriga/nvim-notify' }
  vim.o.termguicolors = true
  vim.notify = require 'notify'

  vim.pack.add { 'https://github.com/kdheepak/lazygit.nvim' }
  require('telescope').load_extension 'lazygit'
  vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<CR>', { desc = 'LazyGit' })

  vim.pack.add { 'https://github.com/NeogitOrg/neogit' }
  require('neogit').setup {
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration

      -- Only one of these is needed.
      'nvim-telescope/telescope.nvim', -- optional
      -- "ibhagwan/fzf-lua",              -- optional
      -- "nvim-mini/mini.pick",           -- optional
      'folke/snacks.nvim', -- optional
    },
    opts = { -- Disable line numbers
      disable_line_numbers = false,
      -- Disable relative line numbers
      disable_relative_line_numbers = false,
    },
  }
  vim.keymap.set('n', '<leader>gn', '<cmd>Neogit<CR>', { desc = 'Neogit' })

  vim.pack.add { 'https://github.com/FabijanZulj/blame.nvim' }
  require('blame').setup()
  vim.keymap.set('n', '<leader>gb', '<cmd>BlameToggle virtual<CR>', { desc = 'Toggle blame' })

  vim.pack.add { 'https://github.com/LunarVim/bigfile.nvim' }

  -- { -- Copilot
  --   'CopilotC-Nvim/CopilotChat.nvim',
  --   dependencies = {
  --     { 'nvim-lua/plenary.nvim', branch = 'master' },
  --   },
  --   build = 'make tiktoken',
  --   opts = {
  --     -- See Configuration section for options
  --   },
  -- },
  -- TODO: Test this one
  -- Prettier QF window
  -- { 'kevinhwang91/nvim-bqf', ft = 'qf' },
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
