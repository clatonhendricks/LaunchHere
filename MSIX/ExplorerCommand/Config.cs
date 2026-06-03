// Config.cs
//
// Loads commands.json from a discoverable location and exposes the parsed
// model. Mirrors the schema used by the PowerShell flavor so the same config
// works in both flavors.
//
// Lookup order:
//   1. %LOCALAPPDATA%\LaunchHere\commands.json   (user-editable, takes precedence)
//   2. <package install root>\commands.json       (default shipped with package)
//
// The handler reads config on every menu enumeration so edits are picked up
// immediately without re-registering the package.

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LaunchHere.Shell;

public sealed class CommandConfig
{
    [JsonPropertyName("menuRootLabel")] public string  MenuRootLabel { get; set; } = "Launch Here";
    [JsonPropertyName("menuRootIcon")]  public string? MenuRootIcon  { get; set; }
    [JsonPropertyName("commands")]      public List<CommandEntry> Commands { get; set; } = new();
}

public sealed class CommandEntry
{
    [JsonPropertyName("id")]       public string  Id       { get; set; } = "";
    [JsonPropertyName("label")]    public string  Label    { get; set; } = "";
    [JsonPropertyName("terminal")] public string  Terminal { get; set; } = "wt";
    [JsonPropertyName("command")]  public string  Command  { get; set; } = "";
    [JsonPropertyName("keepOpen")] public bool    KeepOpen { get; set; } = true;
    [JsonPropertyName("icon")]     public string? Icon     { get; set; }
}

[JsonSerializable(typeof(CommandConfig))]
[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    ReadCommentHandling = JsonCommentHandling.Skip,
    AllowTrailingCommas = true)]
internal partial class ConfigJsonContext : JsonSerializerContext { }

internal static class ConfigLoader
{
    private static readonly object _lock = new();
    private static CommandConfig? _cached;
    private static DateTime _cachedAt;

    public static CommandConfig Load()
    {
        lock (_lock)
        {
            if (_cached is not null && (DateTime.UtcNow - _cachedAt).TotalSeconds < 2)
                return _cached;

            foreach (var path in CandidatePaths())
            {
                try
                {
                    if (!File.Exists(path)) continue;
                    var json = File.ReadAllText(path);
                    var cfg = JsonSerializer.Deserialize(json, ConfigJsonContext.Default.CommandConfig);
                    if (cfg is null) continue;
                    _cached = cfg;
                    _cachedAt = DateTime.UtcNow;
                    return cfg;
                }
                catch
                {
                    // Swallow and try next; handler must never throw across COM boundary.
                }
            }

            _cached = new CommandConfig();
            _cachedAt = DateTime.UtcNow;
            return _cached;
        }
    }

    private static IEnumerable<string> CandidatePaths()
    {
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        if (!string.IsNullOrEmpty(localAppData))
            yield return Path.Combine(localAppData, "LaunchHere", "commands.json");

        try
        {
            var asmDir = Path.GetDirectoryName(typeof(ConfigLoader).Assembly.Location);
            if (!string.IsNullOrEmpty(asmDir))
                yield return Path.Combine(asmDir, "commands.json");
        }
        catch { /* AOT: Assembly.Location may be empty */ }
    }
}
