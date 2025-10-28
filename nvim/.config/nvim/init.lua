---@diagnostic disable-next-line: undefined-global
local vim = vim

local providers = { "python3", "node", "perl", "ruby" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "<left>", "<nop>")
vim.keymap.set("n", "<right>", "<nop>")
vim.keymap.set("n", "<up>", "<nop>")
vim.keymap.set("n", "<down>", "<nop>")
vim.keymap.set("n", "<tab>", "<C-w><C-w>")
vim.keymap.set("n", "<space>r", "<cmd>restart<cr>")
vim.keymap.set("n", "<space>w", "<cmd>write<cr>")

vim.g.clipboard = {
  copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
  paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
}

vim.cmd({
  -- stylua: ignore
  args = {
    "nosc", "nosmd", "noswf", "nowb", "nowrap", "ph=10", "noru",
    "ch=0", "et", "fcs=eob:\\ ,vert:\\ ", "ic", "scs", "mouse=",
    "shm+=I", "spr", "ts=2", "cb=unnamedplus", "sw=2", "scl=no",
    "ls=0", "udf", "sb", "so=7", "ve=block", "cul"
  },
  cmd = "set",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("save_mkdir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
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
        if not is_attached then
          client:stop()
        end
      end
    end, 100)
  end,
})

local tokyopath = vim.fn.stdpath("data") .. "/lazy/tokyonight.nvim"
local tokyorepo = "https://github.com/folke/tokyonight.nvim.git"
if not (vim.uv or vim.loop).fs_stat(tokyopath) then
  vim.cmd("!git clone --filter=blob:none " .. tokyorepo .. " " .. tokyopath)
end
vim.opt.rtp:prepend(tokyopath)

---@diagnostic disable: missing-fields
require("tokyonight").setup({
  terminal_colors = false,
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
    comments = { italic = false },
    keywords = { italic = false },
  },
  style = "night",
  on_highlights = function(hl, _)
    hl.CursorLine = { bg = "#1e2232" }
  end,
})
require("tokyonight").load()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.cmd("!git clone --filter=blob:none " .. lazyrepo .. " " .. lazypath)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  rocks = { enabled = false },
  install = { colorscheme = { "tokyonight" } },
  ui = {
    size = { width = 1, height = 1 },
    icons = { loaded = "", not_loaded = "", list = { "", "", "", "" } },
  },
  change_detection = { enabled = false },
  default = { lazy = true },
  spec = {

    { "folke/tokyonight.nvim", priority = 1000 },

    {
      "folke/noice.nvim",
      dependencies = { "MunifTanjim/nui.nvim" },
      event = "VeryLazy",
      opts = {
        lsp = {
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
          },
        },
        views = {
          cmdline_popup = {
            border = "none",
            position = { row = 5, col = "50%" },
            size = { width = 60, height = "auto" },
            win_options = { winhighlight = { Normal = "Pmenu" } },
          },
          popupmenu = { enabled = false },
        },
      },
    },

    {
      "stevearc/oil.nvim",
      event = { "VimEnter */*,.*", "BufNew */*,.*" },
      cmd = "Oil",
      keys = { { "-", "<cmd>Oil<cr>" } },
      opts = {
        keymaps = { ["`"] = false },
        view_options = {
          is_always_hidden = function(name, _)
            return name == ".." or name == ".git" or name == ".venv"
          end,
          show_hidden = true,
        },
        float = { border = "single" },
        confirmation = { border = "single" },
        progress = { border = "single" },
        ssh = { border = "single" },
        keymaps_help = { border = "single" },
      },
    },

    {
      "nvim-mini/mini.surround",
      event = "VeryLazy",
      opts = {
        mappings = {
          find_left = "gsF",
          highlight = "gsh",
          add = "gsa",
          replace = "gsr",
          find = "gsf",
          delete = "gsd",
          update_n_lines = "gsn",
        },
        silent = true,
      },
    },

    { "nvim-mini/mini.ai", event = "VeryLazy", opts = { silent = true } },

    { "nvim-mini/mini.icons", event = "VeryLazy", opts = {} },

    {
      "nvim-mini/mini.splitjoin",
      event = "VeryLazy",
      opts = { mappings = { toggle = "<space>m" } },
    },

    { "nvim-mini/mini.pairs", event = "VeryLazy", opts = {} },

    { "nvim-mini/mini-git", event = "VeryLazy", main = "mini.git", opts = {} },

    {
      "lewis6991/gitsigns.nvim",
      event = "VeryLazy",
      keys = {
        {
          "<space>t",
          function()
            local has_diff = vim.wo.diff
            local target_win

            if not has_diff then
              require("gitsigns").diffthis({ split = "rightbelow" }, "")
            end

            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              local bufname = vim.api.nvim_buf_get_name(buf)
              if bufname:find("^gitsigns://") then
                target_win = win
                break
              end
            end

            if target_win then
              vim.schedule(function()
                vim.api.nvim_win_close(target_win, true)
              end)
              return ""
            end
          end,
        },
        {
          "<space>k",
          function()
            ---@diagnostic disable-next-line: param-type-mismatch
            require("gitsigns").nav_hunk("prev")
          end,
        },
        {
          "<space>j",
          function()
            ---@diagnostic disable-next-line: param-type-mismatch
            require("gitsigns").nav_hunk("next")
          end,
        },
        {
          "<space>y",
          function()
            require("gitsigns").stage_hunk()
          end,
        },
        {
          "<space>x",
          function()
            require("gitsigns").reset_hunk()
          end,
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
          pre_open = function()
            require("snacks").terminal.toggle(
              vim.o.shell .. " -il",
              { cwd = vim.uv.cwd(), count = 2424 }
            )
          end,
        },
      },
    },

    {
      "folke/snacks.nvim",
      lazy = false,
      priority = 1001,
      keys = {
        {
          "<space>b",
          function()
            require("snacks").picker.buffers()
          end,
          desc = "Buffers",
        },
        {
          "<space>h",
          function()
            require("snacks").picker.help()
          end,
          desc = "Help",
        },
        {
          "<space>q",
          function()
            require("snacks").bufdelete()
          end,
          desc = "Buffer Delete",
        },
        {
          "<space>/",
          function()
            require("snacks").picker.grep()
          end,
          desc = "Grep",
        },
        {
          "<space>s",
          function()
            require("snacks").picker()
          end,
          desc = "Snacks Biltins",
        },
        {
          "<space>e",
          function()
            require("snacks").explorer()
          end,
          desc = "File Explorer",
        },
        {
          "<space>f",
          function()
            require("snacks").picker.files()
          end,
          desc = "Find Files",
        },
        {
          "<space>c",
          function()
            require("snacks").picker.files({
              cwd = "~/src/nix",
              confirm = function(picker, item)
                picker:close()
                if item then
                  vim.cmd.cd("~/src/nix")
                  vim.schedule(function()
                    vim.cmd("edit " .. item.text)
                  end)
                end
              end,
            })
          end,
          desc = "Find Config File",
        },
        {
          "<space>v",
          function()
            require("snacks").picker.projects()
          end,
          desc = "Projects",
        },
        {
          "<space>u",
          function()
            require("snacks").picker.recent()
          end,
          desc = "Recent",
        },
        {
          "<space>g",
          function()
            if require("snacks").git.get_root(vim.uv.cwd()) == nil then
              vim.notify("not a git repo")
              return
            end
            require("snacks").lazygit()
          end,
          desc = "Lazygit",
        },
        {
          "<space>z",
          function()
            require("snacks").picker.zoxide()
          end,
          desc = "Zoxide",
        },
        {
          "<space>d",
          function()
            require("snacks").picker.diagnostics()
          end,
          desc = "Diagnostics",
        },
        {
          "`",
          function()
            require("snacks").terminal.toggle(
              vim.o.shell .. " -il",
              { cwd = vim.uv.cwd(), count = 2424 }
            )
          end,
          desc = "Toggle Terminal",
          mode = { "n", "t" },
        },
        {
          "<space>n",
          desc = "Neovim News",
          function()
            require("snacks").win({
              file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
              width = 0.6,
              height = 0.6,
              wo = {
                spell = false,
                wrap = false,
                signcolumn = "yes",
                statuscolumn = " ",
                conceallevel = 3,
                winhighlight = "Normal:Pmenu",
              },
            })
          end,
        },
      },
      opts = {
        bigfile = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        words = { enabled = true },
        lazygit = { win = { position = "float", height = 0, width = 0 } },
        terminal = { win = { position = "float", height = 0, width = 0 } },
        win = { wo = { fillchars = "eob: ,vert: " } },
        input = { enabled = true },
        explorer = { replace_netrw = true },
        styles = {
          input = { border = "none" },
          terminal = { wo = { winbar = "", winblend = 15 } },
          scratch = { border = "single" },
        },
        picker = {
          sources = {
            command_history = { layout = "dropdown" },
            lines = { layout = "right" },
            search_history = { layout = "dropdown" },
            icons = { layout = "dropdown" },
            spelling = { layout = "dropdown" },
            files = { hidden = true },
            projects = {
              dev = "~/src",
              projects = vim.tbl_filter(function(p)
                return vim.fn.isdirectory(p) == 1
              end, vim.fn.glob("~/src/*", true, true)),
              recent = false,
              confirm = function(picker)
                require("snacks").bufdelete.all()
                picker:action("load_session")
              end,
            },
            explorer = { layout = "right", focus = "input", hidden = true },
            grep = { hidden = true },
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
          layout = function()
            if vim.o.columns < 120 then
              return { cycle = true, preset = "dropdown" }
            else
              return { preset = "default" }
            end
          end,
          layouts = {
            default = {
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
              preview = "main",
              layout = {
                backdrop = false,
                width = 40,
                min_width = 40,
                height = 0,
                position = "left",
                box = "vertical",
                { win = "list" },
                { win = "input", height = 1 },
              },
            },
            select = {
              preview = false,
              layout = {
                backdrop = false,
                width = 0.5,
                min_width = 80,
                height = 0.4,
                min_height = 3,
                box = "vertical",
                border = "single",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
            },
          },
        },
      },
    },

    {
      "stevearc/conform.nvim",
      event = { "VimEnter" },
      cmd = { "ConformInfo" },
      config = function()
        require("conform").formatters = {
          stylua = {
            prepend_args = {
              "--indent-type",
              "Spaces",
              "--indent-width",
              "2",
              "--column-width",
              "100",
            },
          },
          clang_format = { prepend_args = { "--style=Google" } },
        }
        require("conform").setup({
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
            yaml = { "yamlfmt" },
            zig = { "zigfmt" },
            ["_"] = { "trim_whitespace" },
          },
        })
      end,
    },

    {
      "neovim/nvim-lspconfig",
      init = function()
        -- stylua: ignore
        vim.lsp.enable({"lua_ls", "pyright", "clangd", "gopls", "jdtls", "ts_ls", "zls", "nil_ls"})
      end,
    },

    {
      "Saghen/blink.cmp",
      version = "1.*",
      dependencies = {
        "rafamadriz/friendly-snippets",
        { "kawre/neotab.nvim", event = "InsertEnter", opts = {} },
      },
      event = "InsertEnter",
      opts = {
        appearance = { nerd_font_variant = "normal" },
        keymap = {
          preset = "enter",
          ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        },
        completion = {
          menu = {
            draw = {
              columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
            },
            border = "single",
          },
          list = { selection = { preselect = false } },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            window = { border = "single" },
          },
        },
        signature = { window = { border = "single" } },
        cmdline = { enabled = false },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          providers = {
            lsp = { fallbacks = {} },
          },
        },
      },
      init = function()
        vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      end,
    },
  },
})
