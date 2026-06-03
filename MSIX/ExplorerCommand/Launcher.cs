// Launcher.cs
//
// In-process equivalent of the PowerShell flavor's Launch-Command.ps1.
// Spawns the configured terminal (wt / cmd / powershell / pwsh) at the
// target folder and runs the configured command.

using System;
using System.Diagnostics;
using System.IO;

namespace LaunchHere.Shell;

internal static class Launcher
{
    public static void Launch(CommandEntry entry, string targetFolder)
    {
        if (string.IsNullOrWhiteSpace(targetFolder) || !Directory.Exists(targetFolder)) return;

        // Trim trailing backslash so quoted paths don't escape their closing quote.
        targetFolder = targetFolder.TrimEnd('\\');

        var terminal = (entry.Terminal ?? "wt").ToLowerInvariant();
        var command  = entry.Command  ?? "";
        var keepOpen = entry.KeepOpen;

        if (terminal == "wt" && !ExecutableExists("wt.exe"))
            terminal = "cmd";

        ProcessStartInfo psi;
        switch (terminal)
        {
            case "wt":
            {
                var shellExe = ExecutableExists("pwsh.exe") ? "pwsh.exe" : "powershell.exe";
                var args = $"-d {Quote(targetFolder)} {shellExe} -NoProfile";
                if (keepOpen) args += " -NoExit";
                if (!string.IsNullOrEmpty(command)) args += $" -Command {Quote(command)}";
                psi = new ProcessStartInfo("wt.exe", args) { UseShellExecute = true, WorkingDirectory = targetFolder };
                break;
            }
            case "cmd":
            {
                var flag = keepOpen ? "/k" : "/c";
                var inner = $"cd /d {Quote(targetFolder)}";
                if (!string.IsNullOrEmpty(command)) inner += $" && {command}";
                psi = new ProcessStartInfo("cmd.exe", $"{flag} {Quote(inner)}") { UseShellExecute = true, WorkingDirectory = targetFolder };
                break;
            }
            case "powershell":
            case "pwsh":
            {
                var exe = (terminal == "pwsh" && ExecutableExists("pwsh.exe")) ? "pwsh.exe" : "powershell.exe";
                var script = $"Set-Location -LiteralPath '{targetFolder.Replace("'", "''")}'";
                if (!string.IsNullOrEmpty(command)) script += $"; {command}";
                var args = "-NoProfile";
                if (keepOpen) args += " -NoExit";
                args += $" -Command {Quote(script)}";
                psi = new ProcessStartInfo(exe, args) { UseShellExecute = true, WorkingDirectory = targetFolder };
                break;
            }
            default:
                return;
        }

        try { Process.Start(psi); } catch { /* swallow; never throw across COM */ }
    }

    private static string Quote(string s)
    {
        if (string.IsNullOrEmpty(s)) return "\"\"";
        if (s.IndexOfAny(new[] { ' ', '\t', '"' }) < 0) return s;
        return "\"" + s.Replace("\"", "\\\"") + "\"";
    }

    private static bool ExecutableExists(string exe)
    {
        var pathEnv = Environment.GetEnvironmentVariable("PATH");
        if (string.IsNullOrEmpty(pathEnv)) return false;
        foreach (var dir in pathEnv.Split(Path.PathSeparator))
        {
            try { if (File.Exists(Path.Combine(dir, exe))) return true; } catch { }
        }
        return false;
    }
}
