<#
.SYNOPSIS
    Builds the LaunchHere ExplorerCommand handler DLL with NativeAOT.

.DESCRIPTION
    Wraps `dotnet publish` so the rest of the registration scripts have a
    predictable output location. NativeAOT is required because Explorer loads
    this in-process and we don't want to drag a managed runtime along.

    Output: MSIX\ExplorerCommand\bin\publish\ExplorerCommand.dll
#>
[CmdletBinding()]
param(
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

$root    = Split-Path -Parent $PSCommandPath
$proj    = Join-Path $root 'ExplorerCommand\ExplorerCommand.csproj'
$publish = Join-Path $root 'ExplorerCommand\bin\publish'

Write-Host "[LaunchHere] Publishing $proj ($Configuration, win-x64, NativeAOT)..."
& dotnet publish $proj `
    -c $Configuration `
    -r win-x64 `
    -o $publish `
    --self-contained true `
    /p:PublishAot=true
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed ($LASTEXITCODE)." }

$dll = Join-Path $publish 'ExplorerCommand.dll'
if (-not (Test-Path $dll)) {
    throw "Expected output not found: $dll"
}
Write-Host "[LaunchHere] OK: $dll"
