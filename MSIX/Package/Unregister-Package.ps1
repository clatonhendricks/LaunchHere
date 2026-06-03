<#
.SYNOPSIS
    Removes the registered LaunchHere sparse MSIX package.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$pkg = Get-AppxPackage -Name 'LaunchHere.Shell' -ErrorAction SilentlyContinue
if (-not $pkg) {
    Write-Host "[LaunchHere] Not registered. Nothing to do."
    return
}
Write-Host "[LaunchHere] Removing $($pkg.PackageFullName)..."
Remove-AppxPackage -Package $pkg.PackageFullName
Write-Host "[LaunchHere] Done."
