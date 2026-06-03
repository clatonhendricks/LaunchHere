// DllExports.cs
//
// Native exports the OS COM activation layer needs to find when loading this
// in-process server:
//
//   - DllGetClassObject : returns an IClassFactory for our CLSID.
//   - DllCanUnloadNow   : refcount check.
//
// Uses [UnmanagedCallersOnly] for direct native-export emission under
// NativeAOT — no extra .def file or hosting layer needed.

using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.Marshalling;
using LaunchHere.Shell.Interop;

namespace LaunchHere.Shell;

internal static class ClsidGuids
{
    // Must match RootCommand's [Guid] and the Class Id in AppxManifest.xml.
    public static readonly Guid RootCommandClsid =
        new Guid("3F2504E0-4F89-41D3-9A0C-0305E82C3301");

    public static readonly Guid IID_IClassFactory =
        new Guid("00000001-0000-0000-C000-000000000046");

    public static readonly Guid IID_IUnknown =
        new Guid("00000000-0000-0000-C000-000000000046");
}

[GeneratedComInterface]
[Guid("00000001-0000-0000-C000-000000000046")]
internal partial interface IClassFactory
{
    [PreserveSig] int CreateInstance(IntPtr pUnkOuter, in Guid riid, out IntPtr ppvObject);
    [PreserveSig] int LockServer([MarshalAs(UnmanagedType.Bool)] bool fLock);
}

[GeneratedComClass]
internal partial class RootClassFactory : IClassFactory
{
    public int CreateInstance(IntPtr pUnkOuter, in Guid riid, out IntPtr ppvObject)
    {
        ppvObject = IntPtr.Zero;
        if (pUnkOuter != IntPtr.Zero) return unchecked((int)0x80040110); // CLASS_E_NOAGGREGATION
        try
        {
            var obj = new RootCommand();
            var unk = DllExports.Wrappers.GetOrCreateComInterfaceForObject(obj, CreateComInterfaceFlags.None);
            try
            {
                return Marshal.QueryInterface(unk, in riid, out ppvObject);
            }
            finally
            {
                if (unk != IntPtr.Zero) Marshal.Release(unk);
            }
        }
        catch
        {
            return HResult.E_FAIL;
        }
    }

    public int LockServer(bool fLock) => HResult.S_OK;
}

internal static class DllExports
{
    internal static readonly StrategyBasedComWrappers Wrappers = new();

    [UnmanagedCallersOnly(EntryPoint = "DllGetClassObject")]
    public static unsafe int DllGetClassObject(Guid* rclsid, Guid* riid, IntPtr* ppv)
    {
        if (ppv == null) return HResult.E_FAIL;
        *ppv = IntPtr.Zero;

        if (rclsid == null || *rclsid != ClsidGuids.RootCommandClsid)
            return unchecked((int)0x80040154); // CLASS_E_CLASSNOTAVAILABLE

        try
        {
            var factory = new RootClassFactory();
            var unk = Wrappers.GetOrCreateComInterfaceForObject(factory, CreateComInterfaceFlags.None);
            try
            {
                return Marshal.QueryInterface(unk, in *riid, out *ppv);
            }
            finally
            {
                if (unk != IntPtr.Zero) Marshal.Release(unk);
            }
        }
        catch
        {
            return HResult.E_FAIL;
        }
    }

    [UnmanagedCallersOnly(EntryPoint = "DllCanUnloadNow")]
    public static int DllCanUnloadNow() => HResult.S_FALSE;
}
