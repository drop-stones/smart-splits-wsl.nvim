-- OS detection helpers

local M = {}

---Cache: whether the current operating system is Windows.
---@type boolean
local IS_WINDOWS = vim.fn.has("win32") == 1
  or vim.fn.has("win64") == 1
  or tostring(vim.loop.os_uname().sysname or ""):lower():find("windows") ~= nil

---Check if the current operating system is Windows.
---@return boolean
function M.is_windows()
  return IS_WINDOWS
end

return M
