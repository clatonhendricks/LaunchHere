# LaunchHere

Right-click any folder in Windows Explorer and launch a configurable command — like
`copilot --yolo --experimental`, `claude`, `aider`, `npm run dev`, anything — in a terminal
opened at that folder. Driven by a simple JSON config. No admin, no installers, no DLLs.

Inspired by the classic *"Open PowerShell here"* entry, generalized to any command and any
terminal (`wt` / `cmd` / `powershell` / `pwsh`).

## Two installation paths

LaunchHere ships in two flavors so you can pick the trade-off that fits your environment:

| | [**PowerShell**](./PowerShell/) (Preview mode) | [**MSIX**](./MSIX/) (Phase 2 - In progress) |
|---|---|---|
| **Status** | ✅ Stable | 🧪 Scaffold / WIP |
| **Install method** | Registry under `HKCU` (no admin) | Sparse MSIX + signed COM handler |
| **Win11 main menu** | Under "Show more options" (or enable classic menu globally) | ✅ Native, in the main right-click menu |
| **Win10 support** | ✅ | N/A (Win11-only feature) |
| **Build deps** | None — pure PowerShell + .vbs + .reg | .NET 8 SDK + Windows 10 SDK 10.0.19041+ |
| **Trust prompt** | None | One-time self-signed cert trust |
| **Time to first menu entry** | ~10 seconds | ~5 minutes (build + sign + register) |

Both flavors read **the same `commands.json`** format, so you can author your command list
once and use either install path.

## Recommended path

- **Just want it to work today** → [PowerShell](./PowerShell/) flavor. ~10 second install.
- **Want it in the Win11 main menu without enabling the classic menu globally** →
  [MSIX](./MSIX/) flavor. Requires building a small C# COM handler (scaffold provided).
- **Locked-down corporate machine where MSIX/cert installs are blocked** →
  [PowerShell](./PowerShell/) flavor.

## Repository layout

```
LaunchHere/
├── README.md                           # ← you are here
├── LICENSE
├── PowerShell/                         # Phase 1: registry-based install
│   ├── README.md
│   ├── config/commands.json            # Your command list (shared schema)
│   ├── examples/commands.example.json
│   ├── installer/                      # Install / Uninstall / Win11 classic-menu helpers
│   └── launcher/                       # Launch-Command.ps1 + Launch-Hidden.vbs shim
└── MSIX/                               # Phase 2: Sparse MSIX + IExplorerCommand handler
    ├── README.md
    ├── ExplorerCommand/                # C# class library implementing IExplorerCommand
    ├── Package/                        # AppxManifest.xml, register/unregister scripts
    └── build.ps1
```

## Config schema (shared)

```jsonc
{
  "menuRootLabel": "Launch Here",
  "commands": [
    {
      "id": "copilot-yolo",
      "label": "Copilot (YOLO, experimental)",
      "terminal": "wt",                    // wt | cmd | powershell | pwsh
      "command": "copilot --yolo --experimental",
      "keepOpen": true
    }
  ]
}
```

See [PowerShell/README.md](./PowerShell/README.md) for full schema docs.

## License

[MIT](./LICENSE)
