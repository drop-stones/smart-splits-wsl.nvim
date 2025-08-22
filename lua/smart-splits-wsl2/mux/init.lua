-- Auto-resolve and return the best multiplexer adapter
-- This module returns the adapter table directly (or nil if disabled/unavailable)
-- Adding a new adapter only requires adding a file under: smart-splits-wsl2/mux/<name>.lua

local smart_splits = require("smart-splits-wsl2.smart_splits")

---Discover adapter module names under smart-splits-wsl2/mux/.
---@return table<string, boolean>
local function list_adapter_names()
  local ignore = {
    init = true,
    interface = true,
  }

  local files = vim.api.nvim_get_runtime_file("lua/smart-splits-wsl2/mux/*.lua", true)

  local adapters = {}
  for _, path in ipairs(files) do
    local basename = path:match("([^/\\]+)%.lua$")
    if basename and not ignore[basename] then
      adapters[basename] = true
    end
  end
  return adapters
end

---Resolves and returns the best available multiplexer adapter.
---@return SmartSplitsWsl2MuxAdapter?
local function resolve_adapter()
  ---Helper to "require" and validate an adapter module.
  ---@param adapter string
  ---@return SmartSplitsWsl2MuxAdapter?
  local function load_and_accept(adapter)
    local mod = require("smart-splits-wsl2.mux." .. adapter)
    if mod.detect() and mod.is_available() then
      return mod
    end
    return nil
  end

  local adapters = list_adapter_names()
  assert(next(adapters) ~= nil, "No mux adapters found in smart-splits-wsl2/mux/")

  local upstream = smart_splits.config.multiplexer_integration
  if upstream == false then
    return nil
  elseif type(upstream) == "string" and upstream ~= "" then
    if adapters[upstream] == true then
      return load_and_accept(upstream)
    else
      return nil
    end
  end

  for adapter, _ in pairs(adapters) do
    local mod = load_and_accept(adapter)
    if mod then
      return mod
    end
  end
  return nil
end

---Cache: the resolved adapter for later use
---@type SmartSplitsWsl2MuxAdapter?
local adapter = resolve_adapter()

local M = {}

---Returns the adapter instance.
---@return SmartSplitsWsl2MuxAdapter?
function M.get()
  return adapter
end

---Checks if a valid adapter is available.
---@return boolean
function M.available()
  return adapter ~= nil
end

return M
