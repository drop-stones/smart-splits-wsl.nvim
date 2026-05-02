-- WSL2 Zellij adapter implementing the SmartSplitsMultiplexer interface.
-- This allows smart-splits.nvim to control Zellij running in WSL2
-- from a Windows nvim.exe.
--
-- Performance: each wsl.exe call has ~100-200ms overhead. This adapter
-- minimizes calls by batching shell commands and using a synthetic pane
-- ID counter instead of querying zellij for real pane IDs.

local wsl2 = require("smart-splits-wsl.wsl2")
local lazy = require("smart-splits.lazy")
local config = lazy.require_on_index("smart-splits.config")
local Direction = require("smart-splits.types").Direction

---Resolved absolute path of the zellij binary in WSL2.
---@type string?
local zellij_path = nil

---Ensure zellij_path is resolved, resolving it on first use.
local function ensure_zellij_path()
  if not zellij_path then
    zellij_path = wsl2.resolve_cmd_in_wsl2("zellij")
  end
  assert(zellij_path, "zellij binary not found in WSL2")
end

---Build the base zellij command prefix with --session.
---@return string[] prefix
local function zellij_prefix()
  ensure_zellij_path()
  return { zellij_path, "--session", vim.env.ZELLIJ_SESSION_NAME }
end

---Build a shell-safe zellij command string for use in sh -c scripts.
---@return string
local function zellij_shell_prefix()
  ensure_zellij_path()
  return vim.fn.shellescape(zellij_path) .. " --session " .. vim.fn.shellescape(vim.env.ZELLIJ_SESSION_NAME)
end

---Execute a zellij command in WSL2.
---@param cmd string[]
---@return string output, number exit_code
local function zellij_exec(cmd)
  local command = zellij_prefix()
  vim.list_extend(command, cmd)
  local result = wsl2.execute_in_wsl2(command)
  if result.code == 0 then
    return result.stdout or "", result.code
  else
    return result.stderr or "", result.code
  end
end

---Synthetic pane ID counter. Incremented when next_pane detects actual movement.
---The upstream only compares current_pane_id() before and after next_pane()
---to detect whether movement occurred, so a monotonic counter works correctly
---without ever querying zellij for real pane identifiers.
---@type integer
local pane_generation = 0

---@type SmartSplitsMultiplexer
local M = {} ---@diagnostic disable-line: missing-fields

M.type = "zellij"

function M.current_pane_id()
  return pane_generation
end

function M.current_pane_at_edge(_direction) ---@diagnostic disable-line: unused-local
  -- Always return false to skip expensive edge detection.
  -- The upstream move logic handles the "didn't actually move" case via
  -- pane ID comparison in move_multiplexer_inner.
  return false
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
  ensure_zellij_path()

  local action = "move-focus"
  if config.zellij_move_focus_or_tab and (direction == Direction.left or direction == Direction.right) then
    action = "move-focus-or-tab"
  end

  -- Batch: snapshot → move → snapshot → compare, all in 1 wsl.exe call.
  -- Uses full zellij path so plain sh (no login shell) suffices.
  local zj = zellij_shell_prefix()
  local script = string.format(
    "BEFORE=$(%s action list-clients 2>/dev/null); "
      .. "%s action %s %s 2>/dev/null; "
      .. "AFTER=$(%s action list-clients 2>/dev/null); "
      .. '[ "$BEFORE" != "$AFTER" ] && echo MOVED || echo SAME',
    zj,
    zj,
    action,
    direction,
    zj
  )
  local result = wsl2.execute_in_wsl2({ "sh", "-c", script })

  if vim.trim(result.stdout or "") == "MOVED" then
    pane_generation = pane_generation + 1
  end

  return true
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
