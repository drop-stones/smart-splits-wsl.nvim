# smart-splits-wsl2

Bridge Windows Neovim (nvim.exe) with a multiplexer inside WSL2 for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim).  
This plugin is a lightweight wrapper: when a multiplexer is available it forwards window navigation/resize through it; when not, it safely falls back to normal smart-splits behavior.

## ✨ Features

- Connects Windows Neovim (nvim.exe) to a WSL2 multiplexer for pane-aware navigation and resizing
- Safe fallback when the environment or multiplexer is not available

> [!NOTE]
> 🧭 Target scenario (non-blocking)
>
> This plugin bridges Windows Neovim (nvim.exe) launched from WSL2 to a multiplexer inside WSL2.  
> Outside that scenario it safely falls back to normal smart-splits behavior, so you can keep it installed everywhere without harm.

## ⚡️ Requirements

- Neovim >= **0.10.0**
- A terminal multiplexer running inside WSL2
- [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)

## 📦 Installation

Install the plugin with your preferred package manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mrjones2014/smart-splits.nvim",
  opts = { ... },
  keys = { ... },
},
{
  "drop-stones/smart-splits-wsl2.nvim",
  event = "VeryLazy",
  opts = {},
  keys = { ... },
}
```

## 🚀 Usage

If you are using the Windows build of Neovim launched from WSL2, the following functions will route through the multiplexer; otherwise they behave like upstream smart-splits.

### Lua API

```lua
-- moving between splits (same as smart-splits.nvim)
require("smart-splits-wsl2").move_cursor_up()
require("smart-splits-wsl2").move_cursor_down()
require("smart-splits-wsl2").move_cursor_left()
require("smart-splits-wsl2").move_cursor_right()

-- resizing splits (same as smart-splits.nvim)
require("smart-splits-wsl2").resize_up(amount)
require("smart-splits-wsl2").resize_down(amount)
require("smart-splits-wsl2").resize_left(amount)
require("smart-splits-wsl2").resize_right(amount)
```

### ⌨️ Key Mappings Example

```lua
{
  "drop-stones/smart-splits-wsl2.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    -- moving between splits
    { "<c-h>", function() require("smart-splits-wsl2").move_cursor_left()  end, mode = { "n", "t" }, desc = "Go to Left Window" },
    { "<c-j>", function() require("smart-splits-wsl2").move_cursor_down()  end, mode = { "n", "t" }, desc = "Go to Lower Window" },
    { "<c-k>", function() require("smart-splits-wsl2").move_cursor_up()    end, mode = { "n", "t" }, desc = "Go to Upper Window" },
    { "<c-l>", function() require("smart-splits-wsl2").move_cursor_right() end, mode = { "n", "t" }, desc = "Go to Right Window" },

    -- resizing splits
    { "<c-left>",  function() require("smart-splits-wsl2").resize_left()  end, mode = { "n", "t" }, desc = "Resize Window Left" },
    { "<c-right>", function() require("smart-splits-wsl2").resize_right() end, mode = { "n", "t" }, desc = "Resize Window Right" },
    { "<c-up>",    function() require("smart-splits-wsl2").resize_up()    end, mode = { "n", "t" }, desc = "Resize Window Up" },
    { "<c-down>",  function() require("smart-splits-wsl2").resize_down()  end, mode = { "n", "t" }, desc = "Resize Window Down" },
  },
}
```

## 🔌 Multiplexer Integration

To make multiplexer/session details visible to nvim.exe on Windows, propagate environment variables from WSL2 using `WSLENV`.  
Append to `WSLENV` in your WSL shell profile (e.g. `~/.bashrc`, `~/.zshrc`) so it persists.

### 🧱 Baseline environment (all users)

`WSL_DISTRO_NAME` is usually set automatically by WSL2. Ensure it is propagated to Windows processes:

```bash
# in WSL shell
export WSLENV=$WSLENV:WSL_DISTRO_NAME/w
```

> [!TIP]
> Verify inside Windows Neovim:
>
> ```vim
> :echo $WSL_DISTRO_NAME
> ```

### 🧩 Multiplexer-specific setup

#### Zellij

If you use [Zellij](https://github.com/zellij-org/zellij), ensure that `ZELLIJ` and `ZELLIJ_SESSION_NAME` are visible to nvim.exe.

Propagate them via `WSLENV`:

```bash
# in WSL shell
export WSLENV=$WSLENV:ZELLIJ/w:ZELLIJ_SESSION_NAME/w
```

> [!NOTE]
> These variables are set by Zellij when Neovim is launched from inside a Zellij session.  
> The `/w` flag ensures the variables are exported to Windows processes started from WSL (such as nvim.exe).

> [!TIP]
> Verify inside Windows Neovim:
>
> ```vim
> :echo $ZELLIJ
> :echo $ZELLIJ_SESSION_NAME
> ```

### 🔧 Other Multiplexers

The currently implemented adapter targets Zellij. The code is structured to allow additional multiplexers.  
Contributions are welcome. See `lua/smart-splits-wsl2/mux/zellij.lua` as a reference implementation.

## 🩺 Troubleshooting

Run `:checkhealth smart-splits-wsl2` if you run into any issues.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
