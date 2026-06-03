// RootCommand.cs
//
// Top-level "Launch Here" menu entry. Returns ECF_HASSUBCOMMANDS and
// EnumSubCommands yields one SubCommand per entry in commands.json.

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.Marshalling;
using LaunchHere.Shell.Interop;

namespace LaunchHere.Shell;

// CLSID must match Package\AppxManifest.xml AND DllExports.cs.
[Guid("3F2504E0-4F89-41D3-9A0C-0305E82C3301")]
[GeneratedComClass]
public partial class RootCommand : IExplorerCommand
{
    public int GetTitle(IShellItemArray? psiItemArray, out IntPtr ppszName)
    {
        var label = ConfigLoader.Load().MenuRootLabel ?? "Launch Here";
        ppszName = Marshal.StringToCoTaskMemUni(label);
        return HResult.S_OK;
    }

    public int GetIcon(IShellItemArray? psiItemArray, out IntPtr ppszIcon)
    {
        var icon = ConfigLoader.Load().MenuRootIcon;
        if (string.IsNullOrEmpty(icon)) { ppszIcon = IntPtr.Zero; return HResult.E_NOTIMPL; }
        ppszIcon = Marshal.StringToCoTaskMemUni(icon);
        return HResult.S_OK;
    }

    public int GetToolTip(IShellItemArray? psiItemArray, out IntPtr ppszInfotip)
    {
        ppszInfotip = IntPtr.Zero; return HResult.E_NOTIMPL;
    }

    public int GetCanonicalName(out Guid pguidCommandName) { pguidCommandName = Guid.Empty; return HResult.S_OK; }

    public int GetState(IShellItemArray? psiItemArray, bool fOkToBeSlow, out EXPCMDSTATE pCmdState)
    {
        pCmdState = EXPCMDSTATE.ECS_ENABLED; return HResult.S_OK;
    }

    public int Invoke(IShellItemArray? psiItemArray, IntPtr pbc) => HResult.S_OK;

    public int GetFlags(out EXPCMDFLAGS pFlags)
    {
        pFlags = EXPCMDFLAGS.ECF_HASSUBCOMMANDS; return HResult.S_OK;
    }

    public int EnumSubCommands(out IEnumExplorerCommand ppEnum)
    {
        var entries = ConfigLoader.Load().Commands ?? new List<CommandEntry>();
        var subs = new List<IExplorerCommand>(entries.Count);
        foreach (var e in entries) subs.Add(new SubCommand(e));
        ppEnum = new SubCommandEnumerator(subs);
        return HResult.S_OK;
    }
}
