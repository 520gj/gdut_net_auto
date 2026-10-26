' ============================================================
'  AutoDial.vbs - dial a PPPoE / dial-up connection at logon
'
'  Usage:
'    1. Put this file in your Startup folder (Win+R -> shell:startup)
'    2. Edit CONN below to match your connection name (see "rasdial")
'    3. Make sure the password is saved in Windows ("Remember me"
'       checkbox in the dial-up dialog), otherwise error 691
'
'  Runs hidden, retries every 15s up to 40 times, and does nothing
'  if the connection is already up.
' ============================================================
Option Explicit

' ---------------- settings ----------------
Const CONN       = "kdlink"   ' dial-up connection name (see: rasdial)
Const USERNAME   = ""         ' blank = use credentials saved by Windows
Const PASSWORD   = ""         ' blank = use credentials saved by Windows
Const MAXTRY     = 40         ' max dial attempts
Const WAITSEC    = 15         ' seconds to wait between attempts
Const STARTDELAY = 8          ' seconds to wait for the NIC at logon
' ------------------------------------------

Dim sh, fso, logPath, i, rc
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
logPath = fso.GetSpecialFolder(2).Path & "\autodial.log"

Sub Log(msg)
    On Error Resume Next
    Dim f
    Set f = fso.OpenTextFile(logPath, 8, True)
    f.WriteLine Now & "  " & msg
    f.Close
    On Error GoTo 0
End Sub

' run a command hidden, return its exit code and capture its output
Function RunHidden(cmd, outText)
    Dim tmp, rc2
    tmp = fso.GetSpecialFolder(2).Path & "\autodial_" & CStr(Int(Timer * 1000)) & ".tmp"
    rc2 = sh.Run("cmd.exe /c " & cmd & " > """ & tmp & """ 2>&1", 0, True)
    outText = ""
    On Error Resume Next
    If fso.FileExists(tmp) Then
        outText = fso.OpenTextFile(tmp, 1, False).ReadAll
        fso.DeleteFile tmp, True
    End If
    On Error GoTo 0
    RunHidden = rc2
End Function

' "rasdial" with no arguments lists the connections that are up
Function IsUp()
    Dim o
    RunHidden "rasdial", o
    IsUp = (InStr(1, LCase(o), LCase(CONN), 1) > 0)
End Function

' dial, return the rasdial exit code
Function Dial()
    Dim r
    If USERNAME <> "" Then
        r = sh.Run("rasdial """ & CONN & """ """ & USERNAME & """ """ & PASSWORD & """", 0, True)
    Else
        r = sh.Run("rasdial """ & CONN & """", 0, True)
    End If
    Dial = r
End Function

Log "---------- start ----------"
WScript.Sleep STARTDELAY * 1000

If IsUp() Then
    Log "already connected to " & CONN & ", nothing to do"
    WScript.Quit 0
End If

For i = 1 To MAXTRY
    rc = Dial()
    Log "attempt " & i & ": exit=" & rc

    If rc = 0 Then
        Log "connected"
        WScript.Quit 0
    End If

    ' 691 / 623: no usable credentials -> show the dial dialog once
    If rc = 691 Or rc = 623 Then
        Log "no saved credentials (error " & rc & "), opening the dial dialog"
        sh.Run "rasphone.exe -d """ & CONN & """", 1, False
        WScript.Quit 1
    End If

    WScript.Sleep WAITSEC * 1000

    If IsUp() Then
        Log "connection detected, done"
        WScript.Quit 0
    End If
Next

Log "gave up after " & MAXTRY & " attempts"
WScript.Quit 1
