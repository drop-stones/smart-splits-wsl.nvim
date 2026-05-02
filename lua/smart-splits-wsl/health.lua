local platform = require("smart-splits-wsl.os")
local wsl2 = require("smart-splits-wsl.wsl2")

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
    vim.health.info("OS is not Windows; smart-splits-wsl is disabled in this environment.")
    return
  end

  -- WSL_DISTRO_NAME (required)
  local distro = vim.env.WSL_DISTRO_NAME
  if distro and #distro > 0 then
    vim.health.ok("WSL_DISTRO_NAME is set: " .. distro)
  else
    vim.health.info("WSL_DISTRO_NAME is not set; add it to WSLENV so it is passed from WSL2.")
    return
  end

  -- ZELLIJ + ZELLIJ_SESSION_NAME (required)
  local zellij = vim.env.ZELLIJ
  local zellij_session = vim.env.ZELLIJ_SESSION_NAME
  if zellij and zellij_session then
    vim.health.ok(("Zellij session detected: ZELLIJ=%s, ZELLIJ_SESSION_NAME=%s"):format(zellij, zellij_session))
  else
    vim.health.info(
      "ZELLIJ/ZELLIJ_SESSION_NAME are not set; add them to WSLENV so they are passed from WSL2."
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
    vim.health.start("smart-splits-wsl.nvim")
    check_nvim_version()
    check_smart_splits()
    check_environment()
  end,
}
