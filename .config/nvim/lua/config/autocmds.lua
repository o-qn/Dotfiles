local group = vim.api.nvim_create_augroup("desktop_editing", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.colorcolumn = "88"
    vim.keymap.set("n", "<leader>cp", function()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then
        return vim.notify("Save this Python file first", vim.log.levels.WARN)
      end
      vim.cmd.update()
      local root = LazyVim.root.get()
      local python = vim.fn.exepath("python3")
      local candidates = {
        vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or "",
        root .. "/.venv/bin/python",
        root .. "/venv/bin/python",
      }
      for _, candidate in ipairs(candidates) do
        if candidate ~= "" and vim.fn.executable(candidate) == 1 then
          python = candidate
          break
        end
      end
      Snacks.terminal({ python, file }, { cwd = root, win = { position = "bottom", height = 0.35 } })
    end, { buffer = true, desc = "Run Python file" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "text", "markdown", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.conceallevel = 0
    vim.opt_local.textwidth = 0
    -- Preserve prose on save; Space c f still formats Markdown explicitly.
    vim.b.autoformat = false
  end,
})
