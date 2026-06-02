<#
.SYNOPSIS
  (Optional) Enable the classic Windows 11 context menu globally.

.DESCRIPTION
  Windows 11 hides legacy registry-based context menu entries (including this
  launcher's) under "Show more options". Adding this CLSID stub makes Explorer
  show the full classic menu by default, so the LaunchHere submenu appears
  in the main right-click menu without an extra click.

  This is a documented, reversible per-user tweak. No admin rights required.
  Affects ALL classic context menu entries, not just this launcher.

  Restart Explorer (or sign out / reboot) for the change to take effect.

.NOTES
  Reverse with Disable-Win11ClassicMenu.ps1.
#>
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'

if (-not (Test-Path -LiteralPath $key)) {
    New-Item -Path $key -Force | Out-Null
}
Set-ItemProperty -LiteralPath $key -Name '(default)' -Value ''

Write-Host "Classic Win11 context menu enabled (per-user)."

if ($RestartExplorer) {
    Write-Host "Restarting Explorer..."
    Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.Id -Force }
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
    Write-Host "Done."
} else {
    Write-Host "Restart Explorer to apply: pass -RestartExplorer, or sign out / reboot."
}
