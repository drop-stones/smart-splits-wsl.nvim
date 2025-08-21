-- Multiplexer adapter interface (duck-typed)
-- Define modules under mux/<name>.lua that return a table implementing this shape

---@class SmartSplitsWsl2MuxAdapter
---@field name string adapter name
---@field detect fun(): boolean lightweight detection if the current session is in the mux
---@field is_available fun(): boolean whether this mux is usable in current env
---@field move_focus fun(direction: SmartSplitsDirection) move focus
---@field resize fun(direction: SmartSplitsDirection, amount: number) resize pane

local M = {}

-- Required fields for a valid mux adapter.
local required = { "name", "detect", "is_available", "move_focus", "resize" }

---Validate a candidate adapter at runtime (cheap, once at load time)
---@param adapter table
---@return SmartSplitsWsl2MuxAdapter
function M.validate(adapter)
  assert(type(adapter) == "table", "mux adapter must be a table")
  for _, field in ipairs(required) do
    assert(adapter[field] ~= nil, ("mux adapter missing field: %s"):format(field))
  end
  assert(type(adapter.name) == "string", "mux adapter 'name' must be a string")
  assert(type(adapter.detect) == "function", "mux adapter 'detect' must be a function")
  assert(type(adapter.is_available) == "function", "mux adapter 'is_available' must be a function")
  assert(type(adapter.move_focus) == "function", "mux adapter 'move_focus' must be a function")
  assert(type(adapter.resize) == "function", "mux adapter 'resize' must be a function")
  return adapter
end

return M
