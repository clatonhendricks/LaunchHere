# LaunchHere

Right-click a folder (or inside one) in Windows Explorer and launch a configurable
command — like `copilot --yolo --experimental` — in a terminal opened at that folder.

Inspired by the classic "Open PowerShell here" entry, but for any LLM CLI (Copilot,
Claude, Aider, …) or any other command, all driven by a JSON config.

No more `cd` + typing the same command every time you want to start an LLM agent in a
project directory.

## Quick start (Phase 1 — works today on Win10 and Win11)

1. Edit `config\commands.json` and list the commands you want.
   The default already includes a Copilot YOLO entry.
2. Run the installer (no admin needed — writes to `HKCU` only):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Install-ContextMenu.ps1
   ```

3. Right-click a folder, or inside an open folder's empty space, and pick from the
   **Launch Here** submenu. A terminal opens in that folder and runs your command.

> On **Windows 11**, the entry currently appears under **"Show more options"**.
> To surface it in the **main** menu without an extra click, run:
>
> ```powershell
> powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Enable-Win11ClassicMenu.ps1 -RestartExplorer
> ```
>
> This enables the classic context menu globally (per-user, reversible with
> `Disable-Win11ClassicMenu.ps1`). A future Phase 2 — packaged Sparse MSIX +
> `IExplorerCommand` handler — would surface the entries in the Win11 modern
> menu without the global tweak; design notes live in `plan.md`.

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Uninstall-ContextMenu.ps1
```

## Config format (`config\commands.json`)

```jsonc
{
  "menuRootLabel": "Launch Here",
  "menuRootIcon": null,                       // optional .ico path
  "commands": [
    {
      "id": "copilot-yolo",                   // unique id, used internally
      "label": "Copilot (YOLO, experimental)",// shown in menu
      "terminal": "wt",                       // wt | cmd | powershell | pwsh
      "command": "copilot --yolo --experimental",
      "keepOpen": true,                       // keep terminal open after command exits
      "icon": null                            // optional per-entry .ico
    }
  ]
}
```

After editing the config, **re-run `Install-ContextMenu.ps1`** to refresh the menu.
The launcher itself reads the config every time, so changing only `command` text takes
effect immediately — but adding/removing/renaming entries requires re-running the installer.

### Terminal field

| Value | Behavior |
|-------|----------|
| `wt` | Opens Windows Terminal (`wt.exe -d <folder>`). Falls back to `cmd` if not installed. |
| `cmd` | Opens `cmd.exe` and `cd /d` to the folder. |
| `powershell` | Opens Windows PowerShell with `Set-Location` to the folder. |
| `pwsh` | Opens PowerShell 7+; falls back to Windows PowerShell if `pwsh.exe` not present. |

If `command` is empty, the terminal just opens at the folder (handy for a "PowerShell here"
entry).

## Layout

```
LLM context menu launcher\
├── config\commands.json              # your commands (gitignored if you fork this)
├── examples\commands.example.json    # reference example
├── launcher\Launch-Command.ps1       # invoked from the registry entries
├── installer\
│   ├── Install-ContextMenu.ps1
│   ├── Uninstall-ContextMenu.ps1
│   └── Common.psm1
└── README.md
```

## How it works

`Install-ContextMenu.ps1` writes a cascading-menu set of registry keys under:

- `HKCU\Software\Classes\Directory\shell\LaunchHere` (right-click on folder icon, uses `%1`)
- `HKCU\Software\Classes\Directory\Background\shell\LaunchHere` (right-click in folder, uses `%V`)

Each sub-entry's `command` runs:

```
wscript.exe "<repo>\launcher\Launch-Hidden.vbs" "<id>" "<%V or %1>"
```

`Launch-Hidden.vbs` is a tiny shim that runs `Launch-Command.ps1` hidden — using
`wscript.exe` instead of invoking `powershell.exe` directly avoids the brief PowerShell
console window that would otherwise flash before your real terminal appears.

`Launch-Command.ps1` reads the JSON, finds the entry by id, then `Start-Process`-es the
configured terminal with the right working directory and command.

## Troubleshooting

- **Menu doesn't appear**: re-run `Install-ContextMenu.ps1`. On Win11 check under
  "Show more options".
- **Nothing happens on click**: check the launcher's error popup. If it's silently failing,
  manually run `Launch-Command.ps1 -Id <id> -Path <folder>` in a terminal to see errors.
- **`wt.exe` not found warning**: install Windows Terminal, or change the entry's
  `terminal` to `cmd` / `pwsh` / `powershell`.
- **Config edits not showing up**: re-run the installer (entry add/rename/remove requires
  re-registering keys).

## Roadmap

- **Optional folder rename**: this repo currently lives in a folder named `LLM context menu launcher` for historical reasons. None of the scripts depend on the folder's name, so you can rename it to `LaunchHere` (or anything you like) any time:
  1. Run `installer\Uninstall-ContextMenu.ps1` first.
  2. Close any apps with files in the folder open (Notepad, terminals, etc.).
  3. Rename the folder in Explorer.
  4. Run `installer\Install-ContextMenu.ps1` from the new path.

- **Phase 2** (planned, not yet implemented): Sparse MSIX + `IExplorerCommand` handler
  so the menu appears in the Win11 main context menu **without** the global classic-menu
  tweak. Design notes are in `plan.md`. Until then, `Enable-Win11ClassicMenu.ps1`
  provides equivalent end-user UX.
