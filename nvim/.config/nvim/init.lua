local providers = { "python3", "node", "perl", "ruby" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.keymap.set({ "i", "n", "s" }, "<esc>", "<cmd>noh<CR><esc>")
vim.keymap.set({ "n", "v", "t" }, "<left>", "<nop>")
vim.keymap.set({ "n", "v", "t" }, "<right>", "<nop>")
vim.keymap.set({ "n", "v", "t" }, "<up>", "<nop>")
vim.keymap.set({ "n", "v", "t" }, "<down>", "<nop>")
vim.keymap.set("n", "<tab>", "<C-w><C-w>")
vim.keymap.set("n", "<space>r", "<cmd>restart<cr>")
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==")
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==")
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi")
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi")
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv")
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv")
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>")
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>")
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set({ "i", "x", "n", "s" }, "<D-s>", "<cmd>w<cr><esc>")
vim.keymap.set("x", "<", "<gv")
vim.keymap.set("x", ">", ">gv")
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>")
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>")

vim.diagnostic.config({ virtual_text = true })

vim.cmd({
  -- stylua: ignore
  args = {
    "nosc", "nosmd", "noswf", "nowb", "nowrap", "ph=10", "noru",
    "ch=0", "et", "fcs=eob:\\ ,vert:\\ ", "ic", "scs", "mouse=",
    "shm+=I", "sb", "ts=2", "sw=2", "scl=yes", "ls=0", "stal=0",
    "spr", "so=7", "ve=block", "cul", "udf", "nu", "rnu"
  },
  cmd = "set",
})

vim.g.clipboard = "pbcopy"

vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("checktime", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("misc", { clear = true }),
  pattern = { "man", "help" },
  callback = function()
    vim.opt_local.signcolumn = "no"
    vim.opt_local.statuscolumn = ""
    vim.keymap.set("n", "q", function()
      if #vim.api.nvim_list_wins() > 1 then
        vim.cmd("quit")
      else
        vim.cmd("bdelete")
      end
    end, { buffer = true })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
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

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("term_esc", { clear = true }),
  callback = function()
    local esc_timer
    vim.keymap.set("t", "<esc>", function()
      esc_timer = esc_timer or vim.uv.new_timer()
      if esc_timer == nil then
        return
      end
      if esc_timer:is_active() then
        esc_timer:stop()
        return [[<c-\><c-n>]]
      else
        esc_timer:start(200, 0, function() end)
        return "<esc>"
      end
    end, { expr = true })
  end,
})

vim.api.nvim_create_autocmd({ "TermRequest" }, {
  group = vim.api.nvim_create_augroup("term_osc7", { clear = true }),
  callback = function(ev)
    local val, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*", "")
    if n > 0 then
      local dir = val
      if vim.fn.isdirectory(dir) == 0 then
        vim.notify("invalid dir: " .. dir)
        return
      end
      vim.b[ev.buf].osc7_dir = dir
      if vim.api.nvim_get_current_buf() == ev.buf then
        vim.cmd.cd(dir)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("term_cwd_sync", { clear = true }),
  callback = function()
    local cwd = (vim.uv or vim.loop).cwd()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if not vim.api.nvim_buf_is_loaded(buf) then
        goto continue
      end
      if vim.bo[buf].buftype ~= "terminal" then
        goto continue
      end
      local id = vim.b[buf].terminal_job_id
      local pid = vim.b[buf].terminal_job_pid
      if not id or not pid then
        goto continue
      end
      if vim.fn.jobwait({ id }, 0)[1] ~= -1 then
        goto continue
      end
      local parent_cmd = vim.trim(vim.fn.system("ps -p " .. pid .. " -o comm="))
      if not parent_cmd:match("zsh") then
        goto continue
      end
      local child_pids = vim.fn.systemlist("pgrep -P " .. pid)
      if #child_pids == 1 and child_pids[1] == "" then
        child_pids = {}
      end
      if #child_pids > 0 then
        goto continue
      end
      vim.schedule(function()
        vim.api.nvim_chan_send(id, "\x1b")
        vim.api.nvim_chan_send(id, "0D")
        vim.api.nvim_chan_send(id, "i")
        vim.api.nvim_chan_send(id, vim.api.nvim_replace_termcodes("<C-e>", true, false, true))
        vim.api.nvim_chan_send(id, vim.api.nvim_replace_termcodes("<C-u>", true, false, true))
        vim.api.nvim_chan_send(id, "cd '" .. cwd .. "'\r")
      end)
      ::continue::
    end
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
    hl.CursorLine = { bg = "#16161e" }
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
            input = { view = "cmdline_popup" },
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
      keys = { { "-", "<cmd>Oil<cr>" }, { "_", "<cmd>Oil .<cr>" } },
      opts = {
        keymaps = { ["`"] = false, ["q"] = { "actions.close", mode = "n" } },
        view_options = {
          is_always_hidden = function(name, _)
            return name == ".." or name == ".git" or name == ".venv"
          end,
          show_hidden = true,
        },
        delete_to_trash = true,
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

    {
      "folke/flash.nvim",
      event = "VeryLazy",
      keys = {
        {
          "<space>n",
          mode = { "n", "x", "o" },
          function()
            require("flash").jump()
          end,
        },
        {
          "<space>,",
          mode = { "n", "x", "o" },
          function()
            require("flash").treesitter()
          end,
        },
        {
          "r",
          mode = "o",
          function()
            require("flash").remote()
          end,
        },
      },
      opts = {},
    },

    { "nvim-mini/mini.ai", event = "VeryLazy", opts = { silent = true } },

    { "nvim-mini/mini.icons", event = "VeryLazy", opts = {} },

    {
      "nvim-mini/mini.splitjoin",
      event = "VeryLazy",
      opts = { mappings = { toggle = "<space>m" } },
    },

    {
      "nvim-mini/mini.pairs",
      event = "VeryLazy",
      opts = {
        modes = { insert = true, command = true, terminal = false },
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_ts = { "string" },
        skip_unbalanced = true,
        markdown = true,
      },
    },

    { "nvim-mini/mini-git", event = "VeryLazy", main = "mini.git", opts = {} },

    {
      "lewis6991/gitsigns.nvim",
      event = "VeryLazy",
      keys = {
        {
          "<space>t",
          function()
            if not vim.wo.diff then
              require("gitsigns").diffthis("", { split = "rightbelow" })
            end
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find("^gitsigns://") then
                return vim.schedule(function()
                  vim.api.nvim_win_close(w, true)
                end)
              end
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
            if vim.fn.mode() == "n" then
              require("gitsigns").stage_hunk()
            else
              require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end
          end,
          mode = { "n", "v" },
        },
        {
          "<space>d",
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
      "folke/snacks.nvim",
      lazy = false,
      priority = 1001,
      keys = {
        {
          "<space>h",
          function()
            require("snacks").picker.help()
          end,
        },
        {
          "<space>/",
          function()
            require("snacks").picker.grep()
          end,
        },
        {
          "<space>s",
          function()
            require("snacks").picker()
          end,
        },
        {
          "<space>f",
          function()
            require("snacks").picker.files()
          end,
        },
        {
          "<space>c",
          function()
            if vim.uv.cwd() == vim.fs.normalize("~/src/nix") then
              require("snacks").picker.files()
            else
              require("snacks").picker.files({
                cwd = "~/src/nix",
                confirm = function(picker, item)
                  picker:close()
                  if item then
                    require("snacks").bufdelete.all({ force = true })
                    vim.cmd.cd("~/src/nix")
                    vim.schedule(function()
                      vim.cmd("edit " .. item.text)
                    end)
                  end
                end,
              })
            end
          end,
        },
        {
          "<space>e",
          function()
            require("snacks").picker.init_project()
          end,
        },
        {
          "<space>v",
          function()
            require("snacks").picker.projects()
          end,
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
        },
        {
          "<space>i",
          function()
            require("snacks").picker.icons()
          end,
        },
        {
          "<space>u",
          function()
            require("snacks").picker.undo()
          end,
        },
      },
      opts = {
        bigfile = { enabled = true },
        quickfile = { enabled = true },
        words = { enabled = true },
        statuscolumn = { enabled = true },
        lazygit = { win = { position = "float", height = 0, width = 0 } },
        terminal = { win = { position = "float", height = 0, width = 0 }, shell = "/bin/zsh -il" },
        notifier = {
          enabled = true,
          style = "minimal",
          icons = { error = "", warn = "", info = "", debug = "", trace = "" },
        },
        explorer = { replace_netrw = true },
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
              recent = false,
              confirm = function(picker)
                require("snacks").bufdelete.all({ force = true })
                picker:action("load_session")
              end,
              win = {
                input = {
                  keys = {
                    ["n"] = { "picker_init_project", mode = { "n" } },
                    ["<c-n>"] = { "picker_init_project", mode = { "i", "n" } },
                    ["<c-x>"] = { "project_delete", mode = { "i", "n" } },
                  },
                },
                list = {
                  keys = {
                    ["dd"] = "project_delete",
                  },
                },
              },
              actions = {
                picker_init_project = { action = "picker", source = "init_project" },
                project_delete = function(picker, item)
                  local path = item.file
                  if vim.uv.cwd() == path then
                    vim.notify("🟥 Trash aborted : " .. path, vim.log.levels.ERROR)
                    return
                  end
                  vim.fn.system({ "trash", vim.fn.fnameescape(path) })
                  vim.notify(
                    (vim.v.shell_error == 0 and "🗑️ Trashed: " or "🟥 Trash aborted: ")
                      .. path,
                    vim.v.shell_error == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
                  )
                  picker:refresh()
                end,
              },
            },
            init_project = {
              items = {
                { text = "rust" },
                { text = "python" },
                { text = "go" },
              },
              format = "text",
              layout = "dropdown",
              confirm = function(picker, item)
                picker:close()
                if not item then
                  return
                end
                local lang = type(item) == "table" and (item.text or item[1]) or tostring(item)
                vim.ui.input({ prompt = "󱏒  " }, function(name)
                  if not name or name == "" then
                    vim.notify("Cancelled: no name provided", vim.log.levels.WARN)
                    return
                  end
                  local proj = vim.fs.normalize("~/src/" .. name)
                  vim.uv.fs_mkdir(vim.fs.normalize("~/src"), tonumber("755", 8))
                  vim.uv.fs_mkdir(proj, tonumber("755", 8))
                  local cmds = {
                    rust = "cargo init",
                    go = string.format(
                      "go mod init %s && git init",
                      vim.fn.fnamemodify(proj, ":t")
                    ),
                    python = "uv init && uv venv",
                  }
                  local function run(cmd, cwd)
                    local full_cmd = string.format("cd %s && %s", vim.fn.fnameescape(cwd), cmd)
                    vim.fn.system(full_cmd)
                    return vim.v.shell_error == 0
                  end
                  local ok = run(cmds[lang], proj)
                  if ok then
                    vim.notify(lang .. " project initialized successfully!")
                    vim.cmd("cd " .. vim.fn.fnameescape(proj))
                    require("snacks").bufdelete.all({ force = true })
                    if lang == "go" then
                      local main_go = proj .. "/main.go"
                      local fd = vim.uv.fs_open(main_go, "w", 420)
                      if not fd then
                        return
                      end
                      vim.uv.fs_write(
                        fd,
                        'package main; import "fmt"; func main() { fmt.Println("src") }'
                      )
                      vim.uv.fs_close(fd)
                    end
                    if lang == "python" then
                      local envrc = proj .. "/.envrc"
                      local fd = vim.uv.fs_open(envrc, "w", 420)
                      if not fd then
                        return
                      end
                      vim.uv.fs_write(fd, "layout uv-venv")
                      vim.uv.fs_close(fd)
                    end
                    local files = {
                      rust = proj .. "/src/main.rs",
                      go = proj .. "/main.go",
                      python = proj .. "/main.py",
                    }
                    local path = files[lang]
                    if path and vim.fn.filereadable(path) == 1 then
                      vim.cmd("edit " .. vim.fn.fnameescape(path))
                    end
                  else
                    vim.notify("Initialization failed!", vim.log.levels.ERROR)
                  end
                end)
              end,
            },
            explorer = { layout = "right", hidden = true },
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
      "willothy/flatten.nvim",
      dependencies = { "akinsho/toggleterm.nvim" },
      lazy = false,
      opts = {
        window = { open = "alternate" },
        hooks = {
          pre_open = function()
            vim.cmd.ToggleTerm()
          end,
        },
      },
    },

    {
      "akinsho/toggleterm.nvim",
      cmd = "ToggleTerm",
      keys = { "`" },
      opts = {
        open_mapping = [[`]],
        direction = "tab",
        shell = vim.o.shell .. " -il",
      },
    },

    {
      "folke/trouble.nvim",
      cmd = "Trouble",
      keys = { { "<space>x", "<cmd>Trouble diagnostics toggle<cr>" } },
      opts = {},
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
        vim.lsp.enable({"clangd", "gopls", "jdtls", "lua_ls", "pyright", "rust_analyzer", "ts_ls", "zls"})
        vim.lsp.config("lua_ls", {
          settings = {
            Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } },
          },
        })
        vim.lsp.config("pyright", { settings = { python = { pythonPath = ".venv/bin/python" } } })
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
