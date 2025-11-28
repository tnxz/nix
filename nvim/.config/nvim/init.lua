local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"
if not vim.uv.fs_stat(lazypath) then
	vim.cmd("!git clone --filter=blob:none " .. lazyrepo .. " " .. lazypath)
end
vim.opt.rtp:prepend(lazypath)

vim.g.lazyvim_json = vim.fn.stdpath("state") .. "/lazyvim.json"

require("lazy").setup({
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
	rocks = { enabled = false },
	install = { colorscheme = { "tokyonight" } },
	ui = { backdrop = 30, icons = { loaded = "", not_loaded = "", list = { "", "", "", "" } } },
	change_detection = { enabled = false },
	default = { lazy = true },
	spec = {

		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		{ import = "lazyvim.plugins.extras.lang.go" },
		{ import = "lazyvim.plugins.extras.lang.python" },
		{ import = "lazyvim.plugins.extras.lang.rust" },
		{ import = "lazyvim.plugins.extras.editor.harpoon2" },

		{ "nvim-lualine/lualine.nvim", enabled = false },
		{ "folke/which-key.nvim", enabled = true },

		{ "akinsho/bufferline.nvim", opts = { options = { indicator = { style = "none" } } } },

		{
			"folke/tokyonight.nvim",
			opts = {
				terminal_colors = false,
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
			},
		},

		{
			"folke/noice.nvim",
			opts = {
				presets = { command_palette = false },
				lsp = { signature = { enabled = false } },
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

		{ "kawre/neotab.nvim", event = "InsertEnter", opts = {} },

		{ "nvim-mini/mini.splitjoin", event = "VeryLazy", opts = {} },

		{ "nvim-mini/mini-git", main = "mini.git", event = "VeryLazy", opts = {} },

		{
			"lewis6991/gitsigns.nvim",
			opts = function(_, opts)
				local _on_attach = opts.on_attach
				opts.on_attach = function(buffer)
					_on_attach(buffer)
					local gs = package.loaded.gitsigns
					vim.keymap.set("n", "<space>t", function()
						if not vim.wo.diff then
							gs.diffthis("", { split = "rightbelow" })
						end
						for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
							if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find("^gitsigns://") then
								return vim.schedule(function()
									vim.api.nvim_win_close(w, true)
								end)
							end
						end
					end)
					vim.keymap.set("n", "<space>k", function()
						gs.nav_hunk("prev")
					end)
					vim.keymap.set("n", "<space>j", function()
						gs.nav_hunk("next")
					end)
					vim.keymap.set({ "n", "v" }, "gs", function()
						if vim.fn.mode() == "n" then
							gs.stage_hunk()
						else
							gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
						end
					end)
					vim.keymap.set({ "n", "v" }, "gh", function()
						if vim.fn.mode() == "n" then
							gs.reset_hunk()
						else
							gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
						end
					end)
				end
				return opts
			end,
		},

		{
			"willothy/flatten.nvim",
			lazy = false,
			opts = {
				window = { open = "alternate" },
				hooks = {
					pre_open = function()
						require("snacks").terminal.toggle()
					end,
				},
			},
		},

		{
			"folke/snacks.nvim",
			keys = {
				--   { "<space>,", function() require("snacks").picker.buffers() end },
				--   { "<space>-", function() require("snacks").explorer() end },
				--   { "<space>/", function() require("snacks").picker.grep() end },
				--   { "<space>D", function() require("snacks").bufdelete.all({ force = true }) end },
				--   { "<space>c", function() require("snacks").picker.zoxide() end },
				--   { "<space>d", function() require("snacks").bufdelete({ force = true }) end },
				--   {
				--     "<space>f",
				--     function()
				--       local buf_path = vim.api.nvim_buf_get_name(0)
				--       local real_path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) or buf_path
				--       local root = require("snacks").git.get_root(real_path)
				--       if not root then root = vim.uv.cwd() end
				--       require("snacks").picker.files({ cwd = root })
				--     end,
				--   },
				--   {
				--     "<space>g",
				--     function()
				--       local buf_path = vim.api.nvim_buf_get_name(0)
				--       local real_path = vim.uv.fs_realpath(buf_path) or buf_path
				--       local root = require("snacks").git.get_root(real_path)
				--       if not root then return vim.notify("NO VCS", vim.log.levels.ERROR) end
				--       require("snacks").lazygit({ cwd = root })
				--     end,
				--   },
				--   { "<space>h", function() require("snacks").picker.help() end },
				--   { "<space>i", function() require("snacks").picker.icons() end },
				--   { "<space>s", function() require("snacks").picker() end },
				--   { "<space>u", function() require("snacks").picker.undo() end },
				--   { "<space>v", function() require("snacks").picker.projects() end },
				--   { "<space>x", function() require("snacks").picker.diagnostics() end },
				{
					"`",
					function()
						require("snacks").terminal.toggle()
					end,
					mode = { "n", "t" },
				},
			},
			opts = {
				-- dashboard = { preset = { header = "" }, sections = { { section = "header" } } },
				input = {
					icon = "",
					prompt_pos = "left",
					win = { border = "none", width = vim.o.co, row = 0, col = 0 },
				},
				explorer = { replace_netrw = true, trash = true },
				terminal = { win = { position = "float", height = 0, width = 0 } },
				notifier = { enabled = false },
				picker = {
					prompt = "",
					sources = {
						files = { hidden = true },
						grep = { hidden = true },
						explorer = {
							hidden = true,
							win = { list = { keys = { ["o"] = "explorer_add" } } },
						},
						projects = {
							dev = "~/src",
							recent = false,
							win = { input = { keys = { ["<c-x>"] = { "project_remove", mode = { "i", "n" } } } } },
							actions = {
								project_remove = function(picker, item)
									if not item or not item.file then
										return
									end
									local path = item.file
									if picker._project_removing then
										return
									end
									picker._project_removing = true
									local cwd = vim.uv.cwd()
									if cwd and cwd:match("^" .. vim.pesc(path)) then
										vim.cmd("cd ~/src/")
									end
									local ok, err = require("snacks.explorer.actions").trash(path)
									if ok then
										if cwd == path then
											require("snacks").bufdelete.all({ force = true })
										end
										picker:refresh()
										vim.notify("Project deleted: " .. path)
									else
										vim.notify("Failed to delete project:\n" .. err, vim.log.levels.ERROR)
									end
									picker._project_removing = false
								end,
							},
						},
						zoxide = {
							win = { input = { keys = { ["<c-x>"] = { "zoxide_remove", mode = { "i", "n" } } } } },
							actions = {
								zoxide_remove = function(picker, item)
									if not item or not item.file then
										return
									end
									local path = item.file
									if picker._zoxide_removing then
										return
									end
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
				vim.api.nvim_create_autocmd("WinLeave", {
					group = vim.api.nvim_create_augroup("toggle_snacks_terminal", { clear = true }),
					callback = function(args)
						if vim.bo[args.buf].filetype == "snacks_terminal" then
							require("snacks").terminal.toggle()
						end
					end,
				})
			end,
		},

		{ "neovim/nvim-lspconfig", opts = { inlay_hints = { enabled = false } } },

		{
			"saghen/blink.cmp",
			version = "*",
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
		},
	},
})

-- vim.cmd([[set nosc nosmd noswf nowb ph=10 scl=yes noru ch=0 fcs=eob:\ ,vert:\  sw=2
-- \ ic scs et shm+=I sb ts=2 nowrap ls=0 stal=0 spr so=7 ve=block udf nu rnu mouse=]])
vim.cmd([[set ls=0]])

local providers = { "python3", "node", "perl", "ruby" }
for _, provider in ipairs(providers) do
	vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("misc", { clear = true }),
	pattern = { "man", "help", "lazy" },
	callback = function()
		vim.opt_local.statuscolumn = ""
		vim.opt_local.signcolumn = "no"
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
				vim.api.nvim_chan_send(
					id,
					"\x1b"
						.. "0D"
						.. "i"
						.. vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
						.. vim.api.nvim_replace_termcodes("<C-u>", true, false, true)
						.. "cd '"
						.. cwd
						.. "'\r"
				)
			end)
			::continue::
		end
	end,
})

vim.keymap.set("n", "<space><space>", "<cmd>write<cr>")
vim.keymap.set("n", "<tab>", "<C-w><C-w>")
vim.keymap.set("n", "<space>r", "<cmd>restart<cr>")
vim.keymap.set("n", "<space>e", function()
	local languages = {
		rust = function(_)
			return "cargo init"
		end,
		go = function(name)
			return "touch main.go && go mod init " .. vim.fn.shellescape(name)
		end,
		python = function(_)
			return "uv init"
		end,
	}
	vim.ui.select(vim.tbl_keys(languages), { prompt = "project: " }, function(lang)
		if not lang then
			return
		end
		vim.ui.input({ prompt = "New Project Name: " }, function(name)
			if not name or name == "" then
				return vim.notify("Empty Project Name", vim.log.levels.WARN)
			end
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
end)
