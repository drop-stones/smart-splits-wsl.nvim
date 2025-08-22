-- Window resize actions for smart-splits-wsl2.

local mux = require("smart-splits-wsl2.mux")
local smart_splits = require("smart-splits-wsl2.smart_splits")
local window = require("smart-splits-wsl2.window")

local M = {}

---Resizes the current window in the given direction using mux if available, otherwise fallback.
---@param direction SmartSplitsDirection
---@param amount? number
local function resize(direction, amount)
  amount = amount or smart_splits.config.default_amount

  if
    mux.available()
    and (
      ((direction == smart_splits.Direction.left or direction == smart_splits.Direction.right) and window.is_full_width())
      or ((direction == smart_splits.Direction.up or direction == smart_splits.Direction.down) and window.is_full_height())
    )
  then
    mux.get().resize(direction, amount)
  else
    smart_splits.call("resize", direction)
  end
end

-- Assign resize functions for each direction to the module table.
for _, direction in pairs(smart_splits.Direction) do
  M[smart_splits.api_name("resize", direction)] = function(amount)
    resize(direction, amount)
  end
end

return M
