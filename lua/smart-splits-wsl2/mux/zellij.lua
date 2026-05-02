-- Zellij adapter (implements MuxAdapter)

local interface = require("smart-splits-wsl2.mux.interface")
local wsl2 = require("smart-splits-wsl2.wsl2")

---Cache: resolved absolute path of the zellij binary in WSL2
---@type string?
local zellij_path = nil

---Send action to zellij in the WSL2 environment.
---@param action string[]
local function zellij_action(action)
  assert(zellij_path, "zellij path not resolved; call is_available() first")
  local zellij_cmd = { zellij_path, "--session", vim.env.ZELLIJ_SESSION_NAME, "action" }
  vim.list_extend(zellij_cmd, action)
  wsl2.execute_in_wsl2(zellij_cmd)
end

---Adapter for controlling Zellij via WSL2.
---@class SmartSplitsWsl2MuxAdapter
local ZellijAdapter = {
  name = "zellij",
  detect = function()
    return (vim.env.ZELLIJ ~= nil) and (vim.env.ZELLIJ_SESSION_NAME ~= nil)
  end,
  is_available = function()
    if not wsl2.invoked_from_wsl2() then
      return false
    end
    zellij_path = wsl2.resolve_cmd_in_wsl2("zellij")
    return zellij_path ~= nil
  end,
  move_focus = function(direction)
    zellij_action({ "move-focus", direction })
  end,
  resize = function(direction, _)
    zellij_action({ "resize", "increase", direction })
  end,
}

return interface.validate(ZellijAdapter)
