-- WSL2 Zellij adapter implementing the SmartSplitsMultiplexer interface.
-- This allows smart-splits.nvim to control Zellij running in WSL2
-- from a Windows nvim.exe.

local wsl2 = require("smart-splits-wsl2.wsl2")
local lazy = require("smart-splits.lazy")
local config = lazy.require_on_index("smart-splits.config")
local Direction = require("smart-splits.types").Direction

---Resolved absolute path of the zellij binary in WSL2.
---@type string?
local zellij_path = nil

---Execute a zellij command in WSL2, resolving the binary path on first use.
---@param cmd string[]
---@return string output, number exit_code
local function zellij_exec(cmd)
  if not zellij_path then
    zellij_path = wsl2.resolve_cmd_in_wsl2("zellij")
  end
  assert(zellij_path, "zellij binary not found in WSL2")

  local command = vim.deepcopy(cmd)
  table.insert(command, 1, zellij_path)
  local result = wsl2.execute_in_wsl2(command)
  if result.code == 0 then
    return result.stdout or "", result.code
  else
    return result.stderr or "", result.code
  end
end

local directions_reverse = {
  [Direction.left] = Direction.right,
  [Direction.right] = Direction.left,
  [Direction.up] = Direction.down,
  [Direction.down] = Direction.up,
}

---@type SmartSplitsMultiplexer
local M = {} ---@diagnostic disable-line: missing-fields

M.type = "zellij"

function M.current_pane_id()
  local output_raw, code = zellij_exec({ "action", "list-clients" })
  if code ~= 0 then
    return nil
  end
  local output = vim.split(output_raw, "\n", { trimempty = true })
  if not output[2] then
    return nil
  end
  local pane_id = string.match(output[2], "%S+%s+%w+_(%d+)")
  return pane_id
end

function M.current_pane_at_edge(direction)
  local pane_id = M.current_pane_id()
  if pane_id == nil then
    return false
  end
  zellij_exec({ "action", "move-focus", direction })
  local new_pane_id = M.current_pane_id()
  if new_pane_id == nil then
    return false
  end
  -- move back to original pane
  zellij_exec({ "action", "move-focus", directions_reverse[direction] })
  return pane_id == new_pane_id
end

function M.is_in_session()
  return vim.env.ZELLIJ ~= nil and vim.env.ZELLIJ_SESSION_NAME ~= nil
end

function M.current_pane_is_zoomed()
  return false
end

function M.next_pane(direction)
  if not M.is_in_session() then
    return false
  end
  local action = "move-focus"
  if config.zellij_move_focus_or_tab and (direction == Direction.left or direction == Direction.right) then
    action = "move-focus-or-tab"
  end
  local _, code = zellij_exec({ "action", action, direction })
  return code == 0
end

-- amount is not supported on zellij
function M.resize_pane(direction, _amount) ---@diagnostic disable-line: unused-local
  if not M.is_in_session() then
    return false
  end
  local _, code = zellij_exec({ "action", "resize", "increase", direction })
  return code == 0
end

-- size is not supported on zellij
function M.split_pane(direction, _size) ---@diagnostic disable-line: unused-local
  -- zellij only splits right and down; for the others,
  -- we must split right and down then swap the panes
  local args = { "action", "new-pane" }
  local need_swap
  if direction == Direction.left then
    table.insert(args, "right")
    need_swap = "right"
  elseif direction == Direction.up then
    table.insert(args, "down")
    need_swap = "down"
  else
    table.insert(args, direction)
  end
  local _, split_code = zellij_exec(args)
  if need_swap ~= nil then
    local _, swap_code = zellij_exec({ "action", "move-pane", need_swap })
    M.update_mux_layout_details()
    return split_code == 0 and swap_code == 0
  end
  M.update_mux_layout_details()
  return split_code == 0
end

function M.update_mux_layout_details()
  -- Not implemented yet
end

return M
