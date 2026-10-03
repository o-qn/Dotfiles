return {
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.json" },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              disableOrganizeImports = true, -- Ruff handles imports.
              analysis = {
                typeCheckingMode = "basic",
                diagnosticMode = "openFilesOnly",
                autoSearchPaths = true,
                diagnosticSeverityOverrides = { reportUnusedImport = "none" },
              },
            },
          },
        },
        cssls = { settings = { css = { validate = true } } },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        json = { "prettier" },
        jsonc = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "ruff",
        "json-lsp",
        "css-lsp",
        "prettier",
      },
    },
  },
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "css" } } },
}
