# MSIX flavor — LaunchHere (Phase 2, scaffold/WIP)

> ⚠️ **Status: scaffold only.** This folder contains the design and source for the
> Sparse-MSIX + `IExplorerCommand` flavor of LaunchHere, which would put the menu
> on the **Windows 11 main context menu** (not under "Show more options").
>
> It has **not** been built or tested end-to-end yet. If you just want a working
> tool today, use `..\PowerShell\` — that flavor is fully working.

## Why this flavor exists

The PowerShell flavor uses legacy `HKCU\Software\Classes\...\shell\...` registry
entries. Those work everywhere, but on Windows 11 they only show up under
**Show more options** (or after running the `Enable-Win11ClassicMenu.ps1` tweak
which changes the *global* default).

The only supported way to get a custom entry into the Win11 **main** menu is:

1. A COM in-proc server implementing `IExplorerCommand`.
2. Registered through a **Sparse MSIX package** that declares the
   `windows.fileExplorerContextMenus` extension.
3. Signed with a cert the machine trusts (self-signed is fine for personal use,
   user just has to trust it once).

That's what this folder builds.

## Architecture

```
Explorer right-click
        │
        ▼
windows.fileExplorerContextMenus extension (AppxManifest.xml)
        │
        ▼   CLSID 3F2504E0-4F89-41D3-9A0C-0305E82C3301
ExplorerCommand.dll  (NativeAOT C#)
        │
        ├── RootCommand                 → "LaunchHere" top-level entry
        │      └─ EnumSubCommands       → reads commands.json
        │             └─ SubCommand[]   → one per entry
        │                    └─ Invoke  → Launcher.Launch(entry, folder)
        │
        └── Launcher.Launch             → spawns wt / cmd / pwsh / powershell
                                          via wscript.exe + VBS shim trick
                                          (same UX as PowerShell flavor)
```

Config file lookup order:

1. `%LOCALAPPDATA%\LaunchHere\commands.json`
2. `<package install root>\commands.json` (shipped fallback)

## Files

| Path | Purpose |
|------|---------|
| `ExplorerCommand\ExplorerCommand.csproj` | NativeAOT class library (`net8.0-windows`) |
| `ExplorerCommand\ComInterfaces.cs` | `IExplorerCommand`, `IShellItem`, etc. via `[GeneratedComInterface]` |
| `ExplorerCommand\Config.cs` | JSON config loader (matches PowerShell-flavor schema) |
| `ExplorerCommand\Launcher.cs` | Builds the terminal command line and spawns it |
| `ExplorerCommand\RootCommand.cs` | Top-level menu entry, owns the CLSID |
| `ExplorerCommand\SubCommand.cs` | One per `commands.json` entry; `Invoke` → `Launcher` |
| `ExplorerCommand\DllExports.cs` | `DllGetClassObject` / `DllCanUnloadNow` exports |
| `Package\AppxManifest.xml` | Sparse package manifest |
| `Package\Register-Package.ps1` | Build → cert → pack → sign → register pipeline |
| `Package\Unregister-Package.ps1` | Removes the registered sparse package |
| `Package\Assets\` | Required PNG icons for the manifest (placeholders) |
| `build.ps1` | `dotnet publish` the handler with NativeAOT |

## Open scaffold items

These are the things still to do to get this past "compiles" into "works":

- [ ] **Replace placeholder PNGs** in `Package\Assets\` (Square44x44, Square150x150,
      StoreLogo). Manifest validation rejects missing or wrong-size images.
- [ ] **Verify NativeAOT exports** — confirm that `[UnmanagedCallersOnly(EntryPoint=…)]`
      on `DllGetClassObject` actually appears in the DLL export table after
      `dotnet publish` (`dumpbin /exports`). May need `<RootAllApplicationAssemblies>`
      or a rd.xml file otherwise.
- [ ] **`IShellItemArray` wiring** — sanity-check that `GetItemAt(0)` +
      `GetDisplayName(SIGDN_FILESYSPATH)` returns the parent folder when invoked
      from `Directory\Background` (it should, but worth verifying).
- [ ] **Cert flow** — `Register-Package.ps1` generates a self-signed cert in
      `Cert:\CurrentUser\My` and copies it to `Cert:\LocalMachine\TrustedPeople`.
      That second step needs admin once. Document the prompt.
- [ ] **End-to-end test** on a clean Win11 box. Likely several iterations of
      manifest tweaks before the menu actually appears.
- [ ] **Icons in submenu** — `IExplorerCommand::GetIcon` returns a path, but it
      has to be `<dll>,-<resourceId>` or a file path the package can read. Test.

## Build + register (when ready)

```powershell
# From this folder:
.\build.ps1                     # publishes ExplorerCommand.dll
.\Package\Register-Package.ps1  # signs + registers sparse package
```

## Uninstall

```powershell
.\Package\Unregister-Package.ps1
```

## Why two flavors?

| Aspect | PowerShell flavor | MSIX flavor (this folder) |
|--------|-------------------|---------------------------|
| Win10 support | ✅ | ❌ (Win11 only) |
| Win11 main menu | ❌ (needs classic-menu tweak) | ✅ native |
| Code-signing required | ❌ | ✅ (self-signed OK) |
| Build tooling | none (just PS) | .NET 8 SDK + makeappx + signtool |
| Edit handler → no rebuild | ✅ (just edit script) | ❌ (rebuild DLL) |
| Edit `commands.json` → live | ✅ | ✅ (read each `EnumSubCommands`) |

Pick whichever fits. The PowerShell flavor is what most people should use.
