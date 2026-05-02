# smart-splits-wsl

WSL2 multiplexer adapter for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim).

This plugin injects a WSL2-aware multiplexer backend into smart-splits.nvim, enabling seamless pane navigation and resizing between Windows Neovim (nvim.exe) and a multiplexer running inside WSL2.

## How it works

smart-splits.nvim has a pluggable multiplexer backend system. This plugin implements that interface and injects it at setup time, so all upstream logic, settings, and keybindings work transparently — no wrapper API or separate keybindings required.

```
nvim.exe (Windows) → smart-splits.nvim → smart-splits-wsl adapter → wsl.exe --exec → zellij (WSL2)
```

> [!NOTE]
> This plugin only activates when Windows Neovim is launched from WSL2 with a supported multiplexer.
> Outside that scenario, smart-splits.nvim behaves normally.

## Requirements

- Neovim >= **0.10.0**
- [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
- A terminal multiplexer running inside WSL2 (currently [Zellij](https://github.com/zellij-org/zellij))

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

Add smart-splits-wsl as a dependency of smart-splits.nvim. The `opts = {}` triggers `setup()`, which injects the WSL2 adapter before any keybinding fires:

```lua
{
  "mrjones2014/smart-splits.nvim",
  dependencies = { { "drop-stones/smart-splits-wsl.nvim", opts = {} } },
  -- stylua: ignore
  keys = {
    -- moving between splits
    { "<C-h>", function() require("smart-splits").move_cursor_left()  end, mode = { "n", "t" }, desc = "Move to Left Window" },
    { "<C-j>", function() require("smart-splits").move_cursor_down()  end, mode = { "n", "t" }, desc = "Move to Lower Window" },
    { "<C-k>", function() require("smart-splits").move_cursor_up()    end, mode = { "n", "t" }, desc = "Move to Upper Window" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "t" }, desc = "Move to Right Window" },
    -- resizing splits
    { "<C-Left>",  function() require("smart-splits").resize_left()  end, mode = { "n", "t" }, desc = "Resize Window Left" },
    { "<C-Right>", function() require("smart-splits").resize_right() end, mode = { "n", "t" }, desc = "Resize Window Right" },
    { "<C-Up>",    function() require("smart-splits").resize_up()    end, mode = { "n", "t" }, desc = "Resize Window Up" },
    { "<C-Down>",  function() require("smart-splits").resize_down()  end, mode = { "n", "t" }, desc = "Resize Window Down" },
  },
}
```

> [!IMPORTANT]
> Keybindings call `require("smart-splits")` directly — not `require("smart-splits-wsl")`.
> This plugin only needs `setup()` to run (triggered by `opts = {}`); after that, smart-splits.nvim handles everything.

## WSL2 Environment Setup

To make multiplexer and session details visible to nvim.exe on Windows, propagate environment variables from WSL2 using `WSLENV`.
Add the following to your WSL2 shell profile (e.g. `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`):

### Baseline (all users)

`WSL_DISTRO_NAME` is set automatically by WSL2. Ensure it is propagated to Windows processes:

```bash
export WSLENV=$WSLENV:WSL_DISTRO_NAME/w
```

> [!TIP]
> Verify inside Windows Neovim: `:echo $WSL_DISTRO_NAME`

### Zellij

Propagate `ZELLIJ` and `ZELLIJ_SESSION_NAME`:

```bash
export WSLENV=$WSLENV:ZELLIJ/w:ZELLIJ_SESSION_NAME/w
```

> [!NOTE]
> These variables are set by Zellij when Neovim is launched from inside a Zellij session.
> The `/w` flag ensures the variables are exported to Windows processes started from WSL.

> [!TIP]
> Verify inside Windows Neovim: `:echo $ZELLIJ` and `:echo $ZELLIJ_SESSION_NAME`

## Supported Multiplexers

| Multiplexer | Status |
|-------------|--------|
| [Zellij](https://github.com/zellij-org/zellij) | Supported |
| tmux | Not yet |
| WezTerm | Not yet |

Contributions for additional multiplexers are welcome. See `lua/smart-splits-wsl/mux/zellij.lua` as a reference.

## Troubleshooting

Run `:checkhealth smart-splits-wsl` to diagnose issues.

## License

MIT — see [LICENSE](LICENSE) for details.
