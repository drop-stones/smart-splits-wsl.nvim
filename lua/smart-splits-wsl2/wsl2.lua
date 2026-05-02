-- WSL2 helpers

local platform = require("smart-splits-wsl2.os")

local M = {}

---Cache: whether this Windows nvim.exe was invoked from WSL2 (env propagated)
---@type boolean
local INVOKED_FROM_WSL2 = platform.is_windows() and vim.env.WSL_DISTRO_NAME ~= ""

---Check whether this Windows nvim.exe was invoked from WSL2 (env propagated)
---@return boolean
function M.invoked_from_wsl2()
  return INVOKED_FROM_WSL2
end

---Execute the given command in the WSL2 environment
---@param cmd string[]
---@return vim.SystemCompleted
function M.execute_in_wsl2(cmd)
  if not M.invoked_from_wsl2() then
    return { code = 1, signal = 0, stdout = nil, stderr = nil }
  end

  local wsl2_cmd = { "wsl.exe", "--distribution", vim.env.WSL_DISTRO_NAME, "--exec" }
  vim.list_extend(wsl2_cmd, cmd)
  return vim.system(wsl2_cmd, { text = true }):wait()
end

---Cache: resolved absolute paths for commands in WSL2
---@type table<string, string|false>
local RESOLVED_CMD_PATHS = {}

---Resolve the absolute path of a command in the WSL2 environment.
---Returns the cached absolute path, or nil if the command is not found.
---@param cmd string
---@return string?
function M.resolve_cmd_in_wsl2(cmd)
  if (not M.invoked_from_wsl2()) or (type(cmd) ~= "string") or (cmd == "") then
    return nil
  end

  local cached = RESOLVED_CMD_PATHS[cmd]
  if cached ~= nil then
    return cached or nil -- false → nil
  end

  local shcmd = { "sh", "-lc", "command -v " .. vim.fn.shellescape(cmd) }
  local result = M.execute_in_wsl2(shcmd)

  if result.code == 0 and result.stdout and result.stdout ~= "" then
    local path = vim.trim(result.stdout)
    RESOLVED_CMD_PATHS[cmd] = path
    return path
  end

  RESOLVED_CMD_PATHS[cmd] = false
  return nil
end

return M
