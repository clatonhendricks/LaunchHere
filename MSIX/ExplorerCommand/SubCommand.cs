// SubCommand.cs
//
// One menu entry per command in commands.json. Implements IExplorerCommand
// and dispatches Invoke to Launcher.Launch with the selected folder.

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.Marshalling;
using LaunchHere.Shell.Interop;

namespace LaunchHere.Shell;

[GeneratedComClass]
internal partial class SubCommand : IExplorerCommand
{
    private readonly CommandEntry _entry;
    public SubCommand(CommandEntry entry) { _entry = entry; }

    public int GetTitle(IShellItemArray? psiItemArray, out IntPtr ppszName)
    {
        ppszName = Marshal.StringToCoTaskMemUni(_entry.Label ?? _entry.Id ?? "(unnamed)");
        return HResult.S_OK;
    }

    public int GetIcon(IShellItemArray? psiItemArray, out IntPtr ppszIcon)
    {
        if (string.IsNullOrEmpty(_entry.Icon)) { ppszIcon = IntPtr.Zero; return HResult.E_NOTIMPL; }
        ppszIcon = Marshal.StringToCoTaskMemUni(_entry.Icon);
        return HResult.S_OK;
    }

    public int GetToolTip(IShellItemArray? psiItemArray, out IntPtr ppszInfotip) { ppszInfotip = IntPtr.Zero; return HResult.E_NOTIMPL; }
    public int GetCanonicalName(out Guid pguidCommandName) { pguidCommandName = Guid.Empty; return HResult.S_OK; }

    public int GetState(IShellItemArray? psiItemArray, bool fOkToBeSlow, out EXPCMDSTATE pCmdState)
    {
        pCmdState = EXPCMDSTATE.ECS_ENABLED; return HResult.S_OK;
    }

    public int Invoke(IShellItemArray? psiItemArray, IntPtr pbc)
    {
        try
        {
            var folder = ResolveFolder(psiItemArray);
            if (!string.IsNullOrEmpty(folder)) Launcher.Launch(_entry, folder!);
        }
        catch { /* never throw across COM */ }
        return HResult.S_OK;
    }

    public int GetFlags(out EXPCMDFLAGS pFlags) { pFlags = EXPCMDFLAGS.ECF_DEFAULT; return HResult.S_OK; }

    public int EnumSubCommands(out IEnumExplorerCommand ppEnum) { ppEnum = null!; return HResult.E_NOTIMPL; }

    private static string? ResolveFolder(IShellItemArray? items)
    {
        if (items is null) return null;
        if (items.GetCount(out var count) != 0 || count == 0) return null;
        if (items.GetItemAt(0, out var item) != 0 || item is null) return null;

        IntPtr pStr = IntPtr.Zero;
        try
        {
            int hr = item.GetDisplayName(SIGDN.FILESYSPATH, out pStr);
            if (hr != 0 || pStr == IntPtr.Zero) return null;
            return Marshal.PtrToStringUni(pStr);
        }
        finally
        {
            if (pStr != IntPtr.Zero) Marshal.FreeCoTaskMem(pStr);
        }
    }
}

[GeneratedComClass]
internal partial class SubCommandEnumerator : IEnumExplorerCommand
{
    private readonly IReadOnlyList<IExplorerCommand> _items;
    private int _pos;

    public SubCommandEnumerator(IReadOnlyList<IExplorerCommand> items) { _items = items; }

    public unsafe int Next(uint celt, IntPtr* pUICommand, out uint pceltFetched)
    {
        pceltFetched = 0;
        if (pUICommand == null || celt == 0) return HResult.S_FALSE;
        var iid = typeof(IExplorerCommand).GUID;
        while (pceltFetched < celt && _pos < _items.Count)
        {
            var item = _items[_pos++];
            var unk = DllExports.Wrappers.GetOrCreateComInterfaceForObject(item, CreateComInterfaceFlags.None);
            try
            {
                if (Marshal.QueryInterface(unk, in iid, out var ptr) == 0)
                {
                    pUICommand[pceltFetched++] = ptr;
                }
            }
            finally
            {
                if (unk != IntPtr.Zero) Marshal.Release(unk);
            }
        }
        return pceltFetched == celt ? HResult.S_OK : HResult.S_FALSE;
    }

    public int Skip(uint celt) { _pos = Math.Min(_items.Count, _pos + (int)celt); return HResult.S_OK; }
    public int Reset() { _pos = 0; return HResult.S_OK; }

    public int Clone(out IEnumExplorerCommand ppenum)
    {
        var c = new SubCommandEnumerator(_items) { _pos = _pos };
        ppenum = c;
        return HResult.S_OK;
    }
}
