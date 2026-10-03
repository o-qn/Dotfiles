local M = {}
local palette_file = vim.fn.stdpath("config") .. "/lua/noctalia_palette.lua"
local watcher

function M.apply()
  local chunk = loadfile(palette_file)
  if not chunk then
    vim.cmd.colorscheme("habamax")
    return
  end
  local palette = chunk()
  local color = palette.base00:gsub("#", "")
  local r, g, b = tonumber(color:sub(1, 2), 16), tonumber(color:sub(3, 4), 16), tonumber(color:sub(5, 6), 16)
  vim.o.background = (0.2126 * r + 0.7152 * g + 0.0722 * b) > 128 and "light" or "dark"
  require("base16-colorscheme").setup(palette)
  vim.g.colors_name = "noctalia"
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "noctalia" })
end

function M.watch()
  if watcher then
    return
  end
  watcher = assert(vim.uv.new_fs_poll())
  watcher:start(
    palette_file,
    1000,
    vim.schedule_wrap(function(err)
      if not err then
        local ok, message = pcall(M.apply)
        if not ok then
          vim.notify("Noctalia palette: " .. tostring(message), vim.log.levels.WARN)
        end
      end
    end)
  )
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      watcher:stop()
      watcher:close()
    end,
    once = true,
  })
end

return M
