<#
.SYNOPSIS
  Launches a configured command in a terminal at a target folder.

.PARAMETER Id
  Command id from commands.json.

.PARAMETER Path
  Target folder (from %V or %1 in registry).

.PARAMETER ConfigPath
  Optional explicit path to commands.json.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][string]$Path,
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '..\installer\Common.psm1') -Force

function Show-Error([string]$Message) {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Message, 'LaunchHere error', 'OK', 'Error') | Out-Null
    } catch {
        Write-Error $Message
    }
}

try {
    $cfg = Read-LauncherConfig -Path $ConfigPath
    $entry = $cfg.commands | Where-Object { $_.id -eq $Id } | Select-Object -First 1
    if (-not $entry) { throw "No command with id '$Id' in config." }

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Target folder does not exist: $Path"
    }

    $terminal = ([string]$entry.terminal).ToLowerInvariant()
    $command  = if ($entry.PSObject.Properties.Name.Contains('command') -and $entry.command) { [string]$entry.command } else { '' }
    $keepOpen = $false
    if ($entry.PSObject.Properties.Name.Contains('keepOpen') -and $null -ne $entry.keepOpen) { $keepOpen = [bool]$entry.keepOpen }

    # Helper: quote an argument for the Windows command-line so spaces survive.
    function QuoteArg([string]$s) {
        if ($null -eq $s) { return '""' }
        if ($s -match '[\s"]') {
            return '"' + ($s -replace '"','\"') + '"'
        }
        return $s
    }

    # Trim trailing backslash on $Path -- a path like "C:\foo\" becomes "C:\foo\"" once
    # quoted, and the backslash escapes the closing quote, breaking wt.exe's parser.
    $safePath = $Path.TrimEnd('\')

    if ($terminal -eq 'wt') {
        if (-not (Get-Command 'wt.exe' -ErrorAction SilentlyContinue)) {
            $terminal = 'cmd'  # fallback
        }
    }

    switch ($terminal) {
        'wt' {
            $shell = if (Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
            # Build a single quoted command-line string. wt.exe's command-line parser
            # treats everything after the shell name as args to that shell.
            $parts = @('-d', (QuoteArg $safePath), $shell, '-NoProfile')
            if ($keepOpen) { $parts += '-NoExit' }
            if ($command)  { $parts += @('-Command', (QuoteArg $command)) }
            $argLine = ($parts -join ' ')
            Start-Process -FilePath 'wt.exe' -ArgumentList $argLine -WorkingDirectory $safePath | Out-Null
        }
        'cmd' {
            $flag = if ($keepOpen) { '/k' } else { '/c' }
            $inner = 'cd /d ' + (QuoteArg $safePath)
            if ($command) { $inner += " && $command" }
            # Pass /k|/c and the inner command as a single string to avoid PS array-quoting issues.
            $argLine = "$flag " + (QuoteArg $inner)
            Start-Process -FilePath 'cmd.exe' -ArgumentList $argLine -WorkingDirectory $safePath | Out-Null
        }
        { $_ -in @('powershell','pwsh') } {
            $exe = if ($terminal -eq 'pwsh') {
                if (Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
            } else { 'powershell.exe' }
            $sqPath = "'" + ($safePath -replace "'", "''") + "'"
            $script = "Set-Location -LiteralPath $sqPath"
            if ($command) { $script += "; $command" }
            $parts = @('-NoProfile')
            if ($keepOpen) { $parts += '-NoExit' }
            $parts += @('-Command', (QuoteArg $script))
            $argLine = ($parts -join ' ')
            Start-Process -FilePath $exe -ArgumentList $argLine -WorkingDirectory $safePath | Out-Null
        }
        default {
            throw "Unknown terminal '$terminal' for command '$Id'. Use wt, cmd, powershell, or pwsh."
        }
    }
}
catch {
    Show-Error $_.Exception.Message
    exit 1
}
