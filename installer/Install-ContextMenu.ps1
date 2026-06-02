<#
.SYNOPSIS
  Installs the LaunchHere context-menu entries into HKCU.

.DESCRIPTION
  Creates a cascading "Launch Here" submenu on:
    - Folders (right-click on a folder icon)
    - Folder background (right-click inside a folder)
  Each sub-entry runs Launch-Command.ps1 with the corresponding command id.

.PARAMETER ConfigPath
  Optional path to commands.json.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

$cfg = Read-LauncherConfig -Path $ConfigPath
$launchScript = Get-LaunchScriptPath
if (-not (Test-Path -LiteralPath $launchScript)) {
    throw "Launch script not found at $launchScript"
}
# .vbs shim avoids the brief PowerShell console flash that users see when the
# registry entry invokes powershell.exe directly.
$vbsShim = Join-Path (Split-Path -Parent $launchScript) 'Launch-Hidden.vbs'
if (-not (Test-Path -LiteralPath $vbsShim)) {
    throw "VBS launcher shim not found at $vbsShim"
}

$rootLabel = if ($cfg.PSObject.Properties.Name.Contains('menuRootLabel') -and $cfg.menuRootLabel) { [string]$cfg.menuRootLabel } else { 'Launch Here' }
$rootIcon  = if ($cfg.PSObject.Properties.Name.Contains('menuRootIcon')  -and $cfg.menuRootIcon)  { [string]$cfg.menuRootIcon } else { $null }

$bases = @(
    @{ Base = 'Directory';            PathToken = '%1' },
    @{ Base = 'Directory\Background'; PathToken = '%V' }
)

function New-RegKey([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [string]$Type = 'String'
    )
    New-RegKey $Path
    if ($Name -eq '(default)') {
        Set-ItemProperty -LiteralPath $Path -Name '(default)' -Value $Value
    } else {
        New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    }
}

if (-not (Get-Command 'wt.exe' -ErrorAction SilentlyContinue)) {
    Write-Warning "wt.exe (Windows Terminal) not found on PATH. Entries with terminal='wt' will fall back to cmd at runtime."
}

foreach ($b in $bases) {
    $rootKey = "HKCU:\Software\Classes\$($b.Base)\shell\LaunchHere"

    if (Test-Path -LiteralPath $rootKey) {
        Remove-Item -LiteralPath $rootKey -Recurse -Force
    }

    New-RegKey $rootKey
    Set-RegValue -Path $rootKey -Name 'MUIVerb'     -Value $rootLabel
    Set-RegValue -Path $rootKey -Name 'SubCommands' -Value ''
    if ($rootIcon) { Set-RegValue -Path $rootKey -Name 'Icon' -Value $rootIcon }

    $shellKey = Join-Path $rootKey 'shell'
    New-RegKey $shellKey

    $order = 0
    foreach ($cmd in $cfg.commands) {
        $order++
        $entryName = ('{0:D2}_{1}' -f $order, ($cmd.id -replace '[^A-Za-z0-9_-]','_'))
        $entryKey  = Join-Path $shellKey $entryName

        New-RegKey $entryKey
        Set-RegValue -Path $entryKey -Name 'MUIVerb' -Value ([string]$cmd.label)
        if ($cmd.PSObject.Properties.Name.Contains('icon') -and $cmd.icon) {
            Set-RegValue -Path $entryKey -Name 'Icon' -Value ([string]$cmd.icon)
        }

        $cmdKey = Join-Path $entryKey 'command'
        New-RegKey $cmdKey
        # wscript.exe runs the .vbs shim with no console window; the shim then
        # spawns powershell hidden. Net effect: no flashing intermediate console.
        $launchInvocation = 'wscript.exe "{0}" "{1}" "{2}"' -f $vbsShim, $cmd.id, $b.PathToken
        Set-RegValue -Path $cmdKey -Name '(default)' -Value $launchInvocation
    }

    Write-Host "Registered $($cfg.commands.Count) entries under $($b.Base)"
}

Write-Host ""
Write-Host "Done. Right-click a folder (or inside one) in Explorer to see '$rootLabel'."
Write-Host "Note: On Windows 11, look under 'Show more options' until the modern handler is installed."

