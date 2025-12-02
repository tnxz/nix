vim.cmd([[
  set nosc nosmd noswf nowb ph=10 scl=yes noru ch=0 fcs=eob:\  sw=2 scs spr
  \ ic et shm+=I sb ts=2 nowrap ls=0 stal=0 so=7 ve=block udf nu rnu mouse=
]])

vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

local providers = { "python3", "node", "perl", "ruby" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("n", "<space><space>", "<cmd>write<cr>")
vim.keymap.set("n", "<space>r", "<cmd>restart<cr>")
local function init_project()
  local languages = {
    rust = function(_) return "cargo init" end,
    go = function(name) return "touch main.go && go mod init " .. vim.fn.shellescape(name) end,
    python = function(_) return "uv init" end,
  }
  vim.ui.select(vim.tbl_keys(languages), { prompt = "project: " }, function(lang)
    if not lang then return end
    vim.ui.input({ prompt = "New Project Name: " }, function(name)
      if not name or name == "" then return vim.notify("Empty Project Name", vim.log.levels.WARN) end
      local cwd = vim.fn.expand("~/src/" .. name)
      vim.fn.mkdir(cwd, "p")
      local cmd = languages[lang](name)
      vim.fn.jobstart("git init && " .. cmd, {
        cwd = cwd,
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            vim.notify("project created successfully", vim.log.levels.INFO)
          else
            vim.notify("Error creating project", vim.log.levels.ERROR)
          end
        end,
      })
    end)
  end)
end
vim.keymap.set("n", "<space>e", function() init_project() end)
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==")
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==")
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi")
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi")
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv")
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv")
vim.keymap.set("n", "H", "<cmd>bprevious<cr>")
vim.keymap.set("n", "L", "<cmd>bnext<cr>")
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set({ "i", "n", "s" }, "<esc>", "<cmd>noh<CR><esc>")

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("misc", { clear = true }),
  pattern = { "man", "help", "lazy" },
  callback = function()
    vim.opt_local.statuscolumn = ""
    vim.opt_local.signcolumn = "no"
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then return end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("save_mkdir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("lsp_unload", { clear = true }),
  callback = function()
    vim.defer_fn(function()
      for _, client in pairs(vim.lsp.get_clients()) do
        local is_attached = false
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.lsp.buf_is_attached(buf, client.id) then
            is_attached = true
            break
          end
        end
        if not is_attached then client:stop() end
      end
    end, 100)
  end,
})

vim.api.nvim_create_autocmd({ "TermRequest" }, {
  group = vim.api.nvim_create_augroup("term_osc7", { clear = true }),
  callback = function(ev)
    local val, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*/", "")
    if n > 0 then
      local dir = val
      if vim.fn.isdirectory(dir) == 0 then
        vim.notify("invalid dir: " .. dir)
        return
      end
      vim.b[ev.buf].osc7_dir = dir
      if vim.api.nvim_get_current_buf() == ev.buf then vim.cmd.cd(dir) end
    end
  end,
})

vim.api.nvim_create_autocmd({ "TermEnter" }, {
  group = vim.api.nvim_create_augroup("term_cwd_sync", { clear = true }),
  callback = function()
    local pids = #vim.api.nvim_get_proc_children(vim.b.terminal_job_pid)
    local shell = vim.api.nvim_get_proc(vim.b.terminal_job_pid).name
    if shell == "zsh" and pids == 0 and vim.b.osc7_dir and vim.b.osc7_dir ~= vim.uv.cwd() then
      vim.api.nvim_chan_send(vim.b.terminal_job_id, "\x1b0Dicd '" .. vim.uv.cwd() .. "'\r")
    end
  end,
})

local tokyopath = vim.fn.stdpath("data") .. "/lazy/tokyonight.nvim"
local tokyorepo = "https://github.com/folke/tokyonight.nvim.git"
if not vim.uv.fs_stat(tokyopath) then vim.cmd("!git clone --filter=blob:none " .. tokyorepo .. " " .. tokyopath) end
vim.opt.rtp:prepend(tokyopath)

---@diagnostic disable: missing-fields
require("tokyonight").setup({
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
    comments = { italic = false },
    keywords = { italic = false },
  },
  style = "night",
  on_highlights = function(hl, c)
    hl.Normal = { bg = "black", fg = c.fg }
    hl.BlinkCmpDoc = { fg = c.fg, bg = "#16161e" }
    hl.BlinkCmpMenu = { fg = c.fg, bg = "#16161e" }
    hl.BlinkCmpSignatureHelp = { fg = c.fg, bg = "#16161e" }
  end,
})
require("tokyonight").load()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"
local INSTALL = false
if not vim.uv.fs_stat(lazypath) then
  vim.cmd("!git clone --filter=blob:none " .. lazyrepo .. " " .. lazypath)
  INSTALL = true
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  rocks = { enabled = false },
  install = { colorscheme = { "retrobox" } },
  ui = { backdrop = 30, icons = { loaded = "", not_loaded = "", list = { "", "", "", "" } } },
  change_detection = { enabled = false },
  default = { lazy = true },
  spec = {

    "folke/tokyonight.nvim",

    {
      "nvim-treesitter/nvim-treesitter",
      dependencies = { "mason.nvim" },
      branch = "main",
      event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
      cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
      opts_extend = { "ensure_installed" },
      opts = { ensure_installed = { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc", "python" } },
      build = ":TSUpdate",
      config = function(_, opts)
        local TS = require("nvim-treesitter")
        local mr = require("mason-registry")
        mr.refresh(function()
          local p = mr.get_package("tree-sitter-cli")
          local is_installed = p:is_installed()
          local installed = p:get_installed_version()
          local latest = p:get_latest_version()
          if not is_installed or installed ~= latest then
            p:install(
              nil,
              vim.schedule_wrap(function(success)
                if success then
                  TS.install(opts.ensure_installed)
                else
                  vim.notify("Failed to install/update tree-sitter-cli", vim.log.levels.ERROR)
                end
              end)
            )
          else
            TS.install(opts.ensure_installed)
          end
        end)
        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("treesitter.setup", { clear = true }),
          callback = function(args)
            local ft = args.match
            local lang = vim.treesitter.language.get_lang(ft) or ft
            if not vim.treesitter.language.add(lang) then return end
            vim.treesitter.start(args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end,
        })
      end,
    },

    "MunifTanjim/nui.nvim",

    {
      "folke/noice.nvim",
      event = "VeryLazy",
      opts = {
        lsp = {
          signature = { enabled = false },
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        cmdline = {
          format = {
            cmdline = { icon = "", conceal = true },
            search_down = { icon = " /", conceal = true },
            search_up = { icon = " ?", conceal = true },
            filter = false,
            lua = false,
            help = false,
            input = { view = "cmdline_popup" },
          },
        },
        views = {
          cmdline_popup = {
            border = "none",
            position = { row = 0, col = 0 },
            size = { width = "auto", height = 1 },
          },
          popupmenu = {
            border = { style = "none", padding = { 0, 1 } },
            position = { row = 1, col = 0 },
            scrollbar = false,
            size = { width = 60, max_height = 10 },
          },
          split = { enter = true, scrollbar = false },
        },
        routes = {
          { filter = { event = "msg_show", min_height = 4 }, view = "split" },
          { filter = { event = "msg_show", any = { { find = "written" } } }, view = "mini" },
        },
      },
    },

    {
      "stevearc/oil.nvim",
      event = { "VimEnter */*,.*", "BufNew */*,.*" },
      cmd = "Oil",
      keys = { { "-", "<cmd>Oil<cr>" }, { "_", "<cmd>Oil .<cr>" } },
      opts = {
        keymaps = { ["`"] = false, ["q"] = { "actions.close", mode = "n" } },
        view_options = { show_hidden = true },
        delete_to_trash = true,
        float = { border = "single" },
        confirmation = { border = "single" },
        progress = { border = "single" },
        ssh = { border = "single" },
        keymaps_help = { border = "single" },
      },
    },

    {
      "folke/flash.nvim",
      event = "VeryLazy",
      keys = {
        { "<space>n", mode = { "n", "x", "o" }, function() require("flash").jump() end },
        { "r", mode = "o", function() require("flash").remote() end },
      },
      opts = {},
    },

    { "kawre/neotab.nvim", event = "InsertEnter", opts = {} },

    { "nvim-mini/mini.pairs", event = "VeryLazy", opts = {} },

    {
      "nvim-mini/mini.surround",
      event = "VeryLazy",
      opts = {
        mappings = { add = "za", delete = "zd", find = "zf", find_left = "zF", highlight = "zh", replace = "zr" },
      },
    },

    { "nvim-mini/mini.ai", event = "VeryLazy", opts = {} },

    { "nvim-mini/mini.splitjoin", event = "VeryLazy", opts = {} },

    { "nvim-mini/mini-git", main = "mini.git", event = "VeryLazy", opts = {} },

    {
      "lewis6991/gitsigns.nvim",
      event = "VeryLazy",
      keys = {
        {
          "<space>t",
          function()
            if not vim.wo.diff then require("gitsigns").diffthis("", { split = "rightbelow" }) end
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find("^gitsigns://") then
                return vim.schedule(function() vim.api.nvim_win_close(w, true) end)
              end
            end
          end,
        },
        { "<space>k", function() require("gitsigns").nav_hunk("prev") end },
        { "<space>j", function() require("gitsigns").nav_hunk("next") end },
        {
          "gs",
          function()
            if vim.fn.mode() == "n" then
              require("gitsigns").stage_hunk()
            else
              require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end
          end,
          mode = { "n", "v" },
        },
        {
          "gh",
          function()
            if vim.fn.mode() == "n" then
              require("gitsigns").reset_hunk()
            else
              require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end
          end,
          mode = { "n", "v" },
        },
      },
      opts = {},
    },

    { "folke/persistence.nvim", event = "BufReadPre", opts = {} },

    {
      "willothy/flatten.nvim",
      lazy = false,
      opts = {
        window = { open = "alternate" },
        hooks = {
          pre_open = function() require("snacks").terminal.toggle() end,
        },
      },
    },

    {
      "folke/snacks.nvim",
      priority = 2000,
      lazy = false,
      keys = {
        { "<space>,", function() require("snacks").picker.buffers() end },
        { "<space>-", function() require("snacks").explorer() end },
        { "<space>/", function() require("snacks").picker.grep() end },
        { "<space>D", function() require("snacks").bufdelete.all({ force = true }) end },
        { "<space>c", function() require("snacks").picker.zoxide() end },
        { "<space>d", function() require("snacks").bufdelete({ force = true }) end },
        { "<space>f", function() require("snacks").picker.files() end },
        { "<space>g", function() require("snacks").lazygit() end },
        { "<space>h", function() require("snacks").picker.help() end },
        { "<space>i", function() require("snacks").picker.icons() end },
        { "<space>s", function() require("snacks").picker() end },
        { "<space>u", function() require("snacks").picker.undo() end },
        { "<space>v", function() require("snacks").picker.projects() end },
        { "<space>x", function() require("snacks").picker.diagnostics() end },
        { mode = { "n", "t" }, "`", function() require("snacks").terminal.toggle() end },
      },
      opts = {
        bigfile = { enabled = true },
        quickfile = { enabled = true },
        indent = { enabled = true },
        statuscolumn = { enabled = true },
        dashboard = { preset = { header = "" }, sections = { { section = "header" } } },
        input = { icon = "", prompt_pos = "left", win = { border = "none", width = vim.o.co, row = 0, col = 0 } },
        explorer = { replace_netrw = true, trash = true },
        terminal = { win = { style = "minimal" } },
        lazygit = { win = { border = "single", backdrop = { blend = 20 } } },
        picker = {
          prompt = "",
          sources = {
            files = { hidden = true },
            grep = { hidden = true },
            explorer = { hidden = true, win = { list = { keys = { ["o"] = "explorer_add" } } } },
            projects = {
              dev = "~/src",
              recent = false,
              win = {
                input = {
                  keys = {
                    ["<c-x>"] = { "project_remove", mode = { "i", "n" } },
                    ["<c-n>"] = { "project_add", mode = { "i", "n" } },
                  },
                },
                list = { keys = { ["dd"] = "project_remove", ["n"] = "project_add" } },
              },
              actions = {
                project_remove = function(picker, item)
                  if not item or not item.file then return end
                  local path = item.file
                  if vim.uv.cwd() == path then return vim.notify("cwd??") end
                  if picker._project_removing then return end
                  picker._project_removing = true
                  require("snacks").picker.util.cmd({ "trash", path }, function()
                    picker._project_removing = false
                    picker:refresh()
                  end)
                end,
                project_add = function(picker)
                  picker:close()
                  init_project()
                end,
              },
            },
            zoxide = {
              win = {
                input = { keys = { ["<c-x>"] = { "zoxide_remove", mode = { "i", "n" } } } },
                list = { keys = { ["dd"] = "zoxide_remove" } },
              },
              actions = {
                zoxide_remove = function(picker, item)
                  if not item or not item.file then return end
                  local path = item.file
                  if picker._zoxide_removing then return end
                  picker._zoxide_removing = true
                  require("snacks").picker.util.cmd({ "zoxide", "remove", path }, function()
                    picker._zoxide_removing = false
                    picker:refresh()
                  end)
                end,
              },
            },
          },
          win = {
            input = {
              keys = {
                ["<Tab>"] = { "list_down", mode = { "i", "n" } },
                ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
              },
            },
            list = { keys = { ["<Tab>"] = "list_down", ["<S-Tab>"] = "list_up" } },
          },
          previewers = { diff = { style = "syntax", wo = { wrap = false } } },
          layouts = {
            default = {
              cycle = true,
              layout = {
                width = 0.8,
                min_width = 120,
                height = 0.8,
                box = "horizontal",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
                { win = "preview", border = "single", width = 0.5 },
              },
            },
            dropdown = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            sidebar = {
              cycle = true,
              preview = "main",
              layout = {
                width = 40,
                min_width = 40,
                height = 0,
                position = "right",
                box = "vertical",
                { win = "list" },
                { win = "input", height = 1 },
                { win = "preview" },
              },
            },
            select = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                border = "single",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
            },
            telescope = {
              cycle = true,
              reverse = false,
              layout = {
                width = 0.8,
                min_width = 120,
                height = 0.8,
                box = "horizontal",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
                { win = "preview", title = "", border = "single", width = 0.5 },
              },
            },
            ivy = {
              cycle = true,
              layout = {
                box = "vertical",
                height = 0.4,
                position = "bottom",
                { win = "input", height = 1 },
                { box = "horizontal", { win = "list" }, { win = "preview", width = 0.6 } },
              },
            },
            ivy_split = {
              preview = "main",
              cycle = true,
              layout = {
                width = 0,
                height = 0.4,
                position = "bottom",
                box = "vertical",
                { win = "input", height = 1 },
                { win = "list" },
                { win = "preview" },
              },
            },
            vscode = {
              cycle = true,
              hidden = { "preview" },
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            vertical = {
              cycle = true,
              layout = {
                preview = false,
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
          },
        },
      },
      config = function(_, opts)
        require("snacks").terminal.tid = function(cmd, opt)
          return vim.inspect({
            cmd = type(cmd) == "table" and cmd or { cmd },
            env = opt.env,
            count = opt.count or vim.v.count1,
          })
        end
        require("snacks").setup(opts)
      end,
    },

    {
      "mason-org/mason.nvim",
      priority = 1000,
      cmd = "Mason",
      keys = { { "<space>m", "<cmd>Mason<cr>" } },
      build = ":MasonUpdate",
      opts = {
        lua = { "lua-language-server", "stylua" },
        c = { "clangd", "clang-format" },
        go = { "gopls", "gofumpt", "goimports" },
        java = { "jdtls", "google-java-format" },
        nix = { "alejandra" },
        python = { "pyright", "ruff" },
        rust = { "rust-analyzer" },
        ts = { "typescript-language-server" },
        zig = { "zls" },
      },
      config = function(_, opts)
        local tools = {}
        for _, tool in pairs(opts) do
          vim.list_extend(tools, tool)
        end
        require("mason").setup()
        local mr = require("mason-registry")
        mr:on("package:install:success", function()
          vim.defer_fn(
            function()
              require("lazy.core.handler.event").trigger({
                event = "FileType",
                buf = vim.api.nvim_get_current_buf(),
              })
            end,
            100
          )
        end)
        mr.refresh(function()
          for _, tool in ipairs(tools) do
            local p = mr.get_package(tool)
            local is_installed = p:is_installed()
            local installed = p:get_installed_version()
            local latest = p:get_latest_version()
            if not is_installed or installed ~= latest then p:install({ version = nil }) end
          end
        end)
      end,
    },

    {
      "neovim/nvim-lspconfig",
      dependencies = { "mason.nvim" },
      init = function()
        vim.lsp.enable({ "lua_ls", "pyright", "clangd", "gopls", "jdtls", "rust_analyzer", "ts_ls", "zls" })
        for lsp, settings in pairs({
          lua_ls = { settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } } },
          pyright = { settings = { python = { pythonPath = ".venv/bin/python" } } },
        }) do
          vim.lsp.config[lsp] = settings
        end
      end,
    },

    {
      "stevearc/conform.nvim",
      dependencies = { "mason.nvim" },
      event = { "BufWritePost" },
      cmd = { "ConformInfo" },
      opts = {
        format_after_save = { lsp_format = "fallback" },
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          go = { "gofumpt" },
          java = { "google-java-format" },
          json = { "jq" },
          lua = { "stylua" },
          nix = { "alejandra" },
          python = { "ruff", "ruff_fix", "ruff_format", "ruff_organize_imports" },
          rust = { "rustfmt" },
          zig = { "zigfmt" },
          ["_"] = { "trim_whitespace" },
        },
        formatters = {
          stylua = {
            prepend_args = {
              "--indent-type",
              "Spaces",
              "--indent-width",
              "2",
              "--column-width",
              "120",
              "--collapse-simple-statement",
              "Always",
            },
          },
          clang_format = { prepend_args = { "--style=Google" } },
        },
      },
    },

    {
      "Saghen/blink.cmp",
      version = "*",
      dependencies = { "rafamadriz/friendly-snippets" },
      event = "InsertEnter",
      opts = {
        appearance = { nerd_font_variant = "normal" },
        keymap = {
          preset = "default",
          ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
          ["<CR>"] = {
            function(cmp)
              if cmp.is_menu_visible() then
                if cmp.get_selected_item() then
                  return cmp.accept()
                else
                  return cmp.cancel()
                end
              end
            end,
            "fallback",
          },
        },
        completion = {
          menu = { draw = { columns = { { "label", gap = 1 }, { "kind_icon", "kind" } } } },
          list = { selection = { preselect = false } },
          documentation = { auto_show = true, auto_show_delay_ms = 0, window = { scrollbar = false } },
        },
        cmdline = { enabled = false },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          providers = { lsp = { fallbacks = {} } },
        },
        signature = { enabled = true },
      },
      init = function() vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() }) end,
    },
  },
})

if INSTALL then vim.cmd("helptags ALL || restart") end
