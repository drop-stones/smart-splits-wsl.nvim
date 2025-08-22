-- Centralized wrappers for smart-splits.nvim

local smart_splits = require("smart-splits")

local M = {}

-- Direction constants for window navigation.
M.Direction = require("smart-splits.types").Direction

-- smart-splits.nvim config
M.config = require("smart-splits.config")

---Returns the name of the smart-splits.nvim action for the given action and direction
---@param action string
---@param direction SmartSplitsDirection
function M.api_name(action, direction)
  return action .. "_" .. direction
end

---Call smart-splits.nvim action
---@param action string
---@param direction SmartSplitsDirection
---@param ... any parameters to pass to the action
function M.call(action, direction, ...)
  local name = M.api_name(action, direction)
  local fn = smart_splits[name]
  assert(type(fn) == "function", ("smart-splits.nvim action not found: %s"):format(name))
  fn(...)
end

return M
