-- Main entry point for smart-splits-wsl2 plugin.

local smart_splits = require("smart-splits-wsl2.smart_splits")

local M = {}

function M.setup() end

-- Dynamically assign move and resize functions for each direction.
for _, direction in pairs(smart_splits.Direction) do
  local move_key = smart_splits.api_name("move_cursor", direction)
  M[move_key] = require("smart-splits-wsl2.actions.move_cursor")[move_key]

  local resize_key = smart_splits.api_name("resize", direction)
  M[resize_key] = require("smart-splits-wsl2.actions.resize")[resize_key]
end

return M
