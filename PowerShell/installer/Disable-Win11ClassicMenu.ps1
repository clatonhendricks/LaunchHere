<#
.SYNOPSIS
  Reverts Enable-Win11ClassicMenu.ps1 — restores the default Win11 menu where
  legacy entries live under "Show more options".
#>
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'

if (Test-Path -LiteralPath $key) {
    Remove-Item -LiteralPath $key -Recurse -Force
    Write-Host "Classic Win11 menu override removed."
} else {
    Write-Host "Override not present; nothing to do."
}

if ($RestartExplorer) {
    Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.Id -Force }
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
}
