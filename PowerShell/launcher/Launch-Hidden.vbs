' Launch-Hidden.vbs
'
' Tiny shim that runs Launch-Command.ps1 with no console flash.
' Invoked from the registry context-menu entries instead of powershell.exe
' directly, so users don't see a black PowerShell window appear and disappear
' before their actual terminal opens.
'
' Args:  <Id>  <Path>
' Both args are passed straight through to Launch-Command.ps1.

Option Explicit

Dim shell, fso, scriptDir, ps1Path, id, targetPath, cmd

If WScript.Arguments.Count < 2 Then
    WScript.Quit 1
End If

id         = WScript.Arguments(0)
targetPath = WScript.Arguments(1)

Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path   = fso.BuildPath(scriptDir, "Launch-Command.ps1")

' Quote helper: wrap in double-quotes and escape any embedded ones.
Function Q(s)
    Q = """" & Replace(s, """", """""") & """"
End Function

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden " & _
      "-File " & Q(ps1Path) & " -Id " & Q(id) & " -Path " & Q(targetPath)

Set shell = CreateObject("WScript.Shell")
' Run with windowStyle = 0 (hidden) and bWaitOnReturn = False (don't block).
shell.Run cmd, 0, False
