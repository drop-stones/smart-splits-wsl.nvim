local platform = require("smart-splits-wsl2.os")
local wsl2 = require("smart-splits-wsl2.wsl2")

local REQUIRED_NVIM_VERSION = { 0, 10, 0 }

---Check Neovim version.
local function check_nvim_version()
  local v = vim.version()
  local label = string.format("%d.%d.%d", v.major, v.minor, v.patch)

  if vim.version.cmp(v, REQUIRED_NVIM_VERSION) >= 0 then
    vim.health.ok("Neovim version: " .. label)
  else
    vim.health.warn("Neovim version is outdated: " .. label .. " (0.10+ recommended)")
  end
end

---Check if smart-splits.nvim is installed.
local function check_smart_splits()
  if pcall(require, "smart-splits") then
    vim.health.ok("smart-splits.nvim is installed")
  else
    vim.health.error("smart-splits.nvim is not installed (required)")
  end
end

---Environment and adapter checks.
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
    vim.health.ok("WSL_DISTRO_NAME is set: " .. distro)
  else
    vim.health.info("WSL_DISTRO_NAME is not set; if your environment sanitizes variables, consider exporting it.")
  end

  -- Zellij environment
  local zellij = vim.env.ZELLIJ
  local zellij_session = vim.env.ZELLIJ_SESSION_NAME
  if zellij and zellij_session then
    vim.health.ok(("Zellij session detected: ZELLIJ=%s, ZELLIJ_SESSION_NAME=%s"):format(zellij, zellij_session))
  else
    vim.health.info(
      "Zellij session variables are not set; add ZELLIJ/ZELLIJ_SESSION_NAME to WSLENV so they are passed from WSL2."
    )
    return
  end

  -- Zellij binary resolution
  local zellij_path = wsl2.resolve_cmd_in_wsl2("zellij")
  if zellij_path then
    vim.health.ok("Zellij binary resolved: " .. zellij_path)
  else
    vim.health.error(
      "Zellij binary not found in WSL2; ensure zellij is installed and available in the login shell PATH."
    )
    return
  end

  -- Adapter injection status
  local ok, mux_api = pcall(require, "smart-splits.mux")
  if ok and mux_api.__mux and mux_api.__mux.type == "zellij" then
    vim.health.ok("WSL2 Zellij adapter is injected into smart-splits.nvim")
  else
    vim.health.warn("WSL2 Zellij adapter is not yet injected; ensure setup() has been called.")
  end
end

return {
  check = function()
    vim.health.start("smart-splits-wsl2.nvim")
    check_nvim_version()
    check_smart_splits()
    check_environment()
  end,
}
