<#
.SYNOPSIS
  Removes the LaunchHere context-menu entries from HKCU.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Include legacy keys so older installs (LLMLauncher, PromptHere) are cleaned up after rename to LaunchHere.
$keys = @(
    'HKCU:\Software\Classes\Directory\shell\LaunchHere',
    'HKCU:\Software\Classes\Directory\Background\shell\LaunchHere',
    'HKCU:\Software\Classes\Directory\shell\PromptHere',
    'HKCU:\Software\Classes\Directory\Background\shell\PromptHere',
    'HKCU:\Software\Classes\Directory\shell\LLMLauncher',
    'HKCU:\Software\Classes\Directory\Background\shell\LLMLauncher'
)

foreach ($k in $keys) {
    if (Test-Path -LiteralPath $k) {
        Remove-Item -LiteralPath $k -Recurse -Force
        Write-Host "Removed $k"
    } else {
        Write-Host "Not present: $k"
    }
}

Write-Host "Uninstall complete."
