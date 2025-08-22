-- Cursor movement actions for smart-splits-wsl2.

local mux = require("smart-splits-wsl2.mux")
local smart_splits = require("smart-splits-wsl2.smart_splits")
local window = require("smart-splits-wsl2.window")

local M = {}

---Moves the cursor in the given direction using mux if at edge and available, otherwise fallback.
---@param direction SmartSplitsDirection
local function move_cursor(direction)
  if mux.available() and window.at_edge(direction) then
    mux.get().move_focus(direction)
  else
    smart_splits.call("move_cursor", direction)
  end
end

-- Assign move_cursor functions for each direction to the module table.
for _, direction in pairs(smart_splits.Direction) do
  M[smart_splits.api_name("move_cursor", direction)] = function()
    move_cursor(direction)
  end
end

return M
