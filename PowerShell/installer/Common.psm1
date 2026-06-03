# Common.psm1 - Shared helpers for the LLM context menu launcher.

Set-StrictMode -Version Latest

function Get-LauncherRoot {
    $here = Split-Path -Parent $PSCommandPath
    return (Resolve-Path (Join-Path $here '..')).Path
}

function Get-DefaultConfigPath {
    $root = Get-LauncherRoot
    $cfg = Join-Path $root 'config\commands.json'
    if (Test-Path -LiteralPath $cfg) { return $cfg }
    $example = Join-Path $root 'examples\commands.example.json'
    return $example
}

function Read-LauncherConfig {
    param(
        [string]$Path
    )
    if (-not $Path) { $Path = Get-DefaultConfigPath }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    try {
        $cfg = $raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse JSON config '$Path': $($_.Exception.Message)"
    }
    if (-not $cfg.commands -or $cfg.commands.Count -eq 0) {
        throw "Config '$Path' has no 'commands' array."
    }
    foreach ($c in $cfg.commands) {
        foreach ($req in 'id','label','terminal') {
            if (-not $c.PSObject.Properties.Name.Contains($req) -or [string]::IsNullOrWhiteSpace($c.$req)) {
                throw "Command entry missing required field '$req': $($c | ConvertTo-Json -Compress)"
            }
        }
    }
    return $cfg
}

function Get-RootKeyForBase {
    param([Parameter(Mandatory)][string]$Base)
    return "HKCU:\Software\Classes\$Base\shell\LaunchHere"
}

function Get-LaunchScriptPath {
    return (Join-Path (Get-LauncherRoot) 'launcher\Launch-Command.ps1')
}

Export-ModuleMember -Function Get-LauncherRoot, Get-DefaultConfigPath, Read-LauncherConfig, Get-RootKeyForBase, Get-LaunchScriptPath

