<#
.SYNOPSIS
    Builds, signs, and registers the LaunchHere sparse MSIX package.

.DESCRIPTION
    End-to-end pipeline:
        1. Build the handler DLL via ..\build.ps1.
        2. Stage build output + AppxManifest.xml + Assets into a layout folder.
        3. Generate a self-signed cert (CN=LaunchHere Dev) if one doesn't exist,
           and trust it in Cert:\LocalMachine\TrustedPeople (needs admin once).
        4. Pack with makeappx.exe, sign with signtool.exe.
        5. Register with Add-AppxPackage -ExternalLocation against the layout
           folder so future handler-DLL changes don't require a re-pack.

    Heavy on TODOs — see ..\README.md "Open scaffold items".
#>
[CmdletBinding()]
param(
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

$here       = Split-Path -Parent $PSCommandPath
$msixRoot   = Split-Path -Parent $here
$layout     = Join-Path $msixRoot 'staging'
$manifest   = Join-Path $here 'AppxManifest.xml'
$assets     = Join-Path $here 'Assets'
$publishDir = Join-Path $msixRoot 'ExplorerCommand\bin\publish'
$msixOut    = Join-Path $msixRoot 'LaunchHere.msix'
$pfxPath    = Join-Path $msixRoot 'LaunchHereDev.pfx'
$certSubject = 'CN=LaunchHere Dev'

# ---- 1. Build handler DLL --------------------------------------------------
& (Join-Path $msixRoot 'build.ps1') -Configuration $Configuration

# ---- 2. Stage layout -------------------------------------------------------
if (Test-Path $layout) { Remove-Item $layout -Recurse -Force }
New-Item -ItemType Directory -Path $layout | Out-Null
Copy-Item $manifest $layout
Copy-Item (Join-Path $publishDir 'ExplorerCommand.dll') $layout
Copy-Item (Join-Path $msixRoot 'Stub\bin\publish\LaunchHereStub.exe') $layout
Copy-Item $assets (Join-Path $layout 'Assets') -Recurse

# Ship a default commands.json. Prefer any existing config the user already uses
# from the PowerShell flavor; fall back to its example template.
$repoRoot      = Split-Path -Parent $msixRoot
$psFlavorCfg   = Join-Path $repoRoot 'PowerShell\config\commands.json'
$psFlavorEx    = Join-Path $repoRoot 'PowerShell\examples\commands.example.json'
$cfgSource = if (Test-Path $psFlavorCfg) { $psFlavorCfg }
             elseif (Test-Path $psFlavorEx) { $psFlavorEx }
             else { $null }
if ($cfgSource) {
    Copy-Item $cfgSource (Join-Path $layout 'commands.json')
    Write-Host "[LaunchHere] Bundled config from $cfgSource"
} else {
    Write-Warning "[LaunchHere] No commands.json found — menu will be empty until %LOCALAPPDATA%\LaunchHere\commands.json exists."
}

# ---- 3. Cert ---------------------------------------------------------------
$cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Subject -eq $certSubject } |
    Select-Object -First 1
if (-not $cert) {
    Write-Host "[LaunchHere] Creating self-signed cert $certSubject..."
    $cert = New-SelfSignedCertificate -Type CodeSigningCert `
        -Subject $certSubject `
        -KeyUsage DigitalSignature `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
}

if (-not (Test-Path $pfxPath)) {
    $pwd = ConvertTo-SecureString -String 'launchhere' -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pwd | Out-Null
}

# Trust the cert machine-wide so AppX accepts the signed package.
# Requires admin. If we're not elevated, tell the user and bail.
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$trusted = Get-ChildItem Cert:\LocalMachine\TrustedPeople -ErrorAction SilentlyContinue |
    Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $trusted) {
    if (-not $isAdmin) {
        throw "Need admin to trust cert in Cert:\LocalMachine\TrustedPeople. Re-run elevated."
    }
    Write-Host "[LaunchHere] Trusting cert in LocalMachine\TrustedPeople..."
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store `
        'TrustedPeople', 'LocalMachine'
    $store.Open('ReadWrite')
    $store.Add($cert)
    $store.Close()
}

# ---- 4. Pack + sign --------------------------------------------------------
$sdkRoot = 'C:\Program Files (x86)\Windows Kits\10\bin'
$makeappx = Get-ChildItem $sdkRoot -Recurse -Filter 'makeappx.exe' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match 'x64' } | Select-Object -First 1
$signtool = Get-ChildItem $sdkRoot -Recurse -Filter 'signtool.exe' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match 'x64' } | Select-Object -First 1
if (-not $makeappx -or -not $signtool) {
    throw "makeappx.exe / signtool.exe not found. Install Windows 10/11 SDK."
}

if (Test-Path $msixOut) { Remove-Item $msixOut -Force }
& $makeappx.FullName pack /d $layout /p $msixOut /nv
if ($LASTEXITCODE -ne 0) { throw "makeappx failed ($LASTEXITCODE)" }

& $signtool.FullName sign /fd SHA256 /a /f $pfxPath /p 'launchhere' $msixOut
if ($LASTEXITCODE -ne 0) { throw "signtool failed ($LASTEXITCODE)" }

# ---- 5. Register sparse package --------------------------------------------
# ExternalLocation lets us iterate on the handler DLL without re-packing.
Write-Host "[LaunchHere] Registering sparse package at $layout..."
Add-AppxPackage -Path $msixOut -ExternalLocation $layout -AllowUnsigned:$false

# Explorer caches COM activation tables — must be restarted to pick up the
# newly-registered shell extension. Documented limitation of MSIX shell exts.
Write-Host "[LaunchHere] Restarting File Explorer..."
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer.exe
}

Write-Host "[LaunchHere] Done. Right-click a folder in Explorer to test."
