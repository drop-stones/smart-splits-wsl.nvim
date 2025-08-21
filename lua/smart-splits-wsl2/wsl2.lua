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

---Cache: whether the given command exists in the WSL2 environment
---@type table<string, boolean>
local CMD_EXISTS_IN_WSL2 = {}

---Check whether the given command exists in the WSL2 environment
---@param cmd string
---@return boolean
function M.cmd_exists_in_wsl2(cmd)
  if (not M.invoked_from_wsl2()) or (type(cmd) ~= "string") or (cmd == "") then
    return false
  end

  -- cache check
  local cached = CMD_EXISTS_IN_WSL2[cmd]
  if cached ~= nil then
    return cached
  end

  local shcmd = { "sh", "-lc", "command -v " .. vim.fn.shellescape(cmd) .. " >/dev/null 2>&1" }
  local result = M.execute_in_wsl2(shcmd)
  local exist = (result.code == 0)

  -- save to cache
  CMD_EXISTS_IN_WSL2[cmd] = exist

  return exist
end

return M
