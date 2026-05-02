local platform = require("smart-splits-wsl2.os")
local wsl2 = require("smart-splits-wsl2.wsl2")

---@class NeovimVersion
---@field major integer
---@field minor integer
---@field patch integer

---Checks if the current Neovim version is greater or equal to the given version.
---@param required_version NeovimVersion
local function check_nvim_version(required_version)
  local version = vim.version()
  local nvim_version = string.format("%d.%d.%d", version.major, version.minor, version.patch)

  if
    version.major > required_version.major
    or (version.major == required_version.major and version.minor > required_version.minor)
    or (version.major == required_version.major and version.minor == required_version.minor and version.patch >= required_version.patch)
  then
    vim.health.ok("Neovim version: " .. nvim_version)
  else
    vim.health.warn("Neovim version is outdated: " .. nvim_version .. " (0.10+ recommended)")
  end
end

---Checks if a plugin is installed and reports its status.
---@param plugin_name string
---@param require_name string
---@param is_required boolean
local function check_plugin(plugin_name, require_name, is_required)
  local ok, _ = pcall(require, require_name)
  if ok then
    vim.health.ok(plugin_name .. " is installed")
  else
    if is_required then
      vim.health.error(plugin_name .. " is not installed (required)")
    else
      vim.health.warn(plugin_name .. " is not installed (optional)")
    end
  end
end

---Environment checks
local function check_environment()
  if not platform.is_windows() then
    vim.health.info("OS is not Windows; smart-splits-wsl2 is disabled in this environment.")
    return
  end

  if not wsl2.invoked_from_wsl2() then
    vim.health.info("Neovim (nvim.exe) was not launched from WSL2; smart-splits-wsl2 is disabled.")
    return
  end

  local distro = vim.env.WSL_DISTRO_NAME
  if distro and #distro > 0 then
    vim.health.ok("WSL_DISTRO_NAME is set: " .. tostring(distro))
  else
    vim.health.info("WSL_DISTRO_NAME is not set; if your environment sanitizes variables, consider exporting it.")
  end

  -- Zellij environment
  local zellij = vim.env.ZELLIJ
  local zellij_session = vim.env.ZELLIJ_SESSION_NAME
  if zellij and zellij_session then
    vim.health.ok(("Zellij session detected: ZELLIJ=%s, ZELLIJ_SESSION_NAME=%s"):format(tostring(zellij), tostring(zellij_session)))
  else
    vim.health.info(
      "Zellij session variables are not set; Add ZELLIJ/ZELLIJ_SESSION_NAME to WSLENV so they are passed from WSL2."
    )
    return
  end

  -- Zellij binary resolution
  local zellij_path = wsl2.resolve_cmd_in_wsl2("zellij")
  if zellij_path then
    vim.health.ok("Zellij binary resolved: " .. zellij_path)
  else
    vim.health.error("Zellij binary not found in WSL2; ensure zellij is installed and available in the login shell PATH.")
    return
  end

  -- Adapter injection status
  local mux_api_ok, mux_api = pcall(require, "smart-splits.mux")
  if mux_api_ok and mux_api.__mux and mux_api.__mux.type == "zellij" then
    vim.health.ok("WSL2 Zellij adapter is injected into smart-splits.nvim")
  else
    vim.health.warn("WSL2 Zellij adapter is not yet injected; ensure setup() has been called.")
  end
end

return {
  check = function()
    vim.health.start("smart-splits-wsl2.nvim")
    check_nvim_version({ major = 0, minor = 10, patch = 0 })
    check_plugin("smart-splits.nvim", "smart-splits", true)
    check_environment()
  end,
}
