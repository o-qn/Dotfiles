-- LazyVim handles completion and formatting; these are personal defaults.
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.opt.spelllang = { "en" }
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 6
vim.opt.confirm = true

-- Keep Mason package caches inside Neovim’s XDG cache directory.
vim.env.npm_config_cache = vim.env.npm_config_cache or (vim.fn.stdpath("cache") .. "/npm")
vim.env.PIP_CACHE_DIR = vim.env.PIP_CACHE_DIR or (vim.fn.stdpath("cache") .. "/pip")
-- Find user-installed tools even when the desktop launcher has a minimal PATH.
vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. vim.env.PATH

-- JSON with comments uses the JSON5 grammar.
vim.treesitter.language.register("json5", "jsonc")
