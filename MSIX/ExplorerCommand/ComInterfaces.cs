// ComInterfaces.cs
//
// Minimal COM interop definitions for the shell interfaces we need to
// implement a Win11 right-click context menu handler:
//
//   - IExplorerCommand        : the per-menu-entry contract
//   - IEnumExplorerCommand    : enumerator for sub-entries (used by submenu)
//   - IShellItemArray         : the selection passed to Invoke / GetState
//   - IShellItem              : individual selected item (folder)
//
// Uses .NET 8 source-generated COM interop via [GeneratedComInterface] for
// NativeAOT compatibility.

using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.Marshalling;

namespace LaunchHere.Shell.Interop;

[Flags]
public enum EXPCMDFLAGS : uint
{
    ECF_DEFAULT          = 0x00000000,
    ECF_HASSUBCOMMANDS   = 0x00000001,
    ECF_HASSPLITBUTTON   = 0x00000002,
    ECF_HIDELABEL        = 0x00000004,
    ECF_ISSEPARATOR      = 0x00000008,
    ECF_HASLUASHIELD     = 0x00000010,
    ECF_SEPARATORBEFORE  = 0x00000020,
    ECF_SEPARATORAFTER   = 0x00000040,
    ECF_ISDROPDOWN       = 0x00000080,
    ECF_TOGGLEABLE       = 0x00000100,
    ECF_AUTOMENUICONS    = 0x00000200,
}

public enum EXPCMDSTATE : uint
{
    ECS_ENABLED    = 0x00000000,
    ECS_DISABLED   = 0x00000001,
    ECS_HIDDEN     = 0x00000002,
    ECS_CHECKBOX   = 0x00000004,
    ECS_CHECKED    = 0x00000008,
    ECS_RADIOCHECK = 0x00000010,
}

public enum SIGDN : uint
{
    NORMALDISPLAY               = 0x00000000,
    PARENTRELATIVEPARSING       = 0x80018001,
    DESKTOPABSOLUTEPARSING      = 0x80028000,
    PARENTRELATIVEEDITING       = 0x80031001,
    DESKTOPABSOLUTEEDITING      = 0x8004C000,
    FILESYSPATH                 = 0x80058000,
    URL                         = 0x80068000,
    PARENTRELATIVEFORADDRESSBAR = 0x8007C001,
    PARENTRELATIVE              = 0x80080001,
    PARENTRELATIVEFORUI         = 0x80094001,
}

[GeneratedComInterface]
[Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE")]
public partial interface IShellItem
{
    int BindToHandler(IntPtr pbc, in Guid bhid, in Guid riid, out IntPtr ppv);
    int GetParent(out IShellItem ppsi);
    [PreserveSig]
    int GetDisplayName(SIGDN sigdnName, out IntPtr ppszName);
    int GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
    int Compare(IShellItem psi, uint hint, out int piOrder);
}

[GeneratedComInterface]
[Guid("B63EA76D-1F85-456F-A19C-48159EFA858B")]
public partial interface IShellItemArray
{
    int BindToHandler(IntPtr pbc, in Guid bhid, in Guid riid, out IntPtr ppvOut);
    int GetPropertyStore(uint flags, in Guid riid, out IntPtr ppv);
    int GetPropertyDescriptionList(IntPtr keyType, in Guid riid, out IntPtr ppv);
    int GetAttributes(uint AttribFlags, uint sfgaoMask, out uint psfgaoAttribs);
    [PreserveSig]
    int GetCount(out uint pdwNumItems);
    [PreserveSig]
    int GetItemAt(uint dwIndex, out IShellItem ppsi);
    int EnumItems(out IntPtr ppenumShellItems);
}

[GeneratedComInterface]
[Guid("a08ce4d0-fa25-44ab-b57c-c7b1c323e0b9")]
public partial interface IExplorerCommand
{
    [PreserveSig] int GetTitle(IShellItemArray? psiItemArray, out IntPtr ppszName);
    [PreserveSig] int GetIcon(IShellItemArray? psiItemArray, out IntPtr ppszIcon);
    [PreserveSig] int GetToolTip(IShellItemArray? psiItemArray, out IntPtr ppszInfotip);
    [PreserveSig] int GetCanonicalName(out Guid pguidCommandName);
    [PreserveSig] int GetState(IShellItemArray? psiItemArray, [MarshalAs(UnmanagedType.Bool)] bool fOkToBeSlow, out EXPCMDSTATE pCmdState);
    [PreserveSig] int Invoke(IShellItemArray? psiItemArray, IntPtr pbc);
    [PreserveSig] int GetFlags(out EXPCMDFLAGS pFlags);
    [PreserveSig] int EnumSubCommands(out IEnumExplorerCommand ppEnum);
}

[GeneratedComInterface]
[Guid("a88826f8-186f-4987-aade-ea0cef8fbfe8")]
public partial interface IEnumExplorerCommand
{
    [PreserveSig] int Next(uint celt, [Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 0)] IExplorerCommand[] pUICommand, out uint pceltFetched);
    [PreserveSig] int Skip(uint celt);
    [PreserveSig] int Reset();
    [PreserveSig] int Clone(out IEnumExplorerCommand ppenum);
}

internal static class HResult
{
    public const int S_OK         = 0;
    public const int S_FALSE      = 1;
    public const int E_NOTIMPL    = unchecked((int)0x80004001);
    public const int E_FAIL       = unchecked((int)0x80004005);
    public const int E_NOINTERFACE = unchecked((int)0x80004002);
}
