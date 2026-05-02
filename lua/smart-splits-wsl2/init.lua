-- Main entry point for smart-splits-wsl2 plugin.
-- Detects the WSL2 + multiplexer environment and injects a mux adapter
-- into smart-splits.nvim so that all upstream logic and settings apply.

local M = {}

---Set up smart-splits-wsl2.
---Detects the environment and, if applicable,
---injects the WSL2 mux adapter into smart-splits.nvim.
---
---This must run before the first smart-splits action is triggered.
---Declare smart-splits.nvim as a dependency so it loads first,
---then call this setup() synchronously.
function M.setup()
  local platform = require("smart-splits-wsl2.os")
  local wsl2 = require("smart-splits-wsl2.wsl2")

  if not platform.is_windows() or not wsl2.invoked_from_wsl2() then
    return
  end

  -- Currently only Zellij is supported
  if not vim.env.ZELLIJ or not vim.env.ZELLIJ_SESSION_NAME then
    return
  end

  -- Inject the WSL2 Zellij adapter into smart-splits.nvim.
  -- The zellij binary path is resolved lazily on first use,
  -- so this injection is lightweight (no wsl.exe call here).
  local adapter = require("smart-splits-wsl2.mux.zellij")
  require("smart-splits.mux").__mux = adapter
end

return M
