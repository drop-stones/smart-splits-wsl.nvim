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

Add smart-splits-wsl as a dependency of your existing smart-splits.nvim spec. The `opts = {}` triggers `setup()`, which injects the WSL2 adapter before any keybinding fires:

```lua
{
  "mrjones2014/smart-splits.nvim",
  dependencies = { { "drop-stones/smart-splits-wsl.nvim", opts = {} } },
  -- Configure keys, opts, etc. as you normally would for smart-splits.nvim.
}
```

> [!IMPORTANT]
> This plugin only needs `setup()` to run (triggered by `opts = {}`); after that, smart-splits.nvim handles everything.
> Use `require("smart-splits")` for all keybindings and API calls — not `require("smart-splits-wsl")`.

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
