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
$stub    = Join-Path $root 'Stub\Stub.csproj'
$publish = Join-Path $root 'ExplorerCommand\bin\publish'
$stubPub = Join-Path $root 'Stub\bin\publish'

Write-Host "[LaunchHere] Publishing $proj ($Configuration, win-x64, NativeAOT)..."
& dotnet publish $proj `
    -c $Configuration `
    -r win-x64 `
    -o $publish `
    /p:PublishAot=true
if ($LASTEXITCODE -ne 0) { throw "dotnet publish (handler) failed ($LASTEXITCODE)." }

Write-Host "[LaunchHere] Publishing $stub ($Configuration, win-x64, NativeAOT)..."
& dotnet publish $stub `
    -c $Configuration `
    -r win-x64 `
    -o $stubPub `
    /p:PublishAot=true
if ($LASTEXITCODE -ne 0) { throw "dotnet publish (stub) failed ($LASTEXITCODE)." }

$dll = Join-Path $publish 'ExplorerCommand.dll'
$exe = Join-Path $stubPub 'LaunchHereStub.exe'
foreach ($p in @($dll, $exe)) {
    if (-not (Test-Path $p)) { throw "Expected output not found: $p" }
}
Write-Host "[LaunchHere] OK: $dll"
Write-Host "[LaunchHere] OK: $exe"
