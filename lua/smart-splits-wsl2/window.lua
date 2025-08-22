-- Nvim window helpers

---@alias SmartSplitsWsl2MovementKey "h"|"j"|"k"|"l"

local M = {}

---@type table<SmartSplitsDirection, SmartSplitsWsl2MovementKey>
local keys = {
  left = "h",
  right = "l",
  up = "k",
  down = "j",
}

---Direction keys mapping
---@param direction SmartSplitsDirection
---@return SmartSplitsWsl2MovementKey
local function direction_to_key(direction)
  return keys[direction]
end

---Check whether the current window is at the edge in the given direction.
---@param direction SmartSplitsDirection
---@return boolean
function M.at_edge(direction)
  local key = direction_to_key(direction)
  local cur_win = vim.fn.winnr()
  local new_win = vim.fn.winnr(key)
  return cur_win == new_win
end

---Calculates the effective window height accounting for command line, status line, and tab line.
---@return integer
local function get_effective_window_height()
  -- Calculate the available height for windows, excluding the command line.
  local height = vim.o.lines - vim.o.cmdheight

  -- Adjust for status line if visible.
  if (vim.o.laststatus == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1) or vim.o.laststatus > 1 then
    height = height - 1
  end

  -- Adjust for tab line if visible.
  if (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) or vim.o.showtabline == 2 then
    height = height - 1
  end

  return height
end

---Checks if the specified window occupies the full vertical height of the Neovim UI.
---@param win integer?
---@return boolean
function M.is_full_height(win)
  return vim.api.nvim_win_get_height(win or 0) == get_effective_window_height()
end

---Checks if the specified window occupies the full horizontal width of the Neovim UI.
---@param win integer?
---@return boolean
function M.is_full_width(win)
  return vim.api.nvim_win_get_width(win or 0) == vim.o.columns
end

return M
