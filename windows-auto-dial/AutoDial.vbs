' ============================================================
'  AutoDial.vbs - dial a PPPoE / dial-up connection at logon
'
'  Usage:
'    1. Put this file in your Startup folder (Win+R -> shell:startup)
'    2. Edit CONN below to match your connection name (see "rasdial")
'    3. Keep the network cable plugged in: PPPoE runs over a wired
'       link, Wi-Fi / phone hotspot cannot replace it
'    4. Make sure the password is saved in Windows ("Remember me"
'       checkbox in the dial-up dialog), otherwise error 691
'
'  Runs hidden, only one copy at a time, retries with backoff, and
'  does nothing if the connection is already up.
' ============================================================
Option Explicit

' ---------------- settings ----------------
Const CONN       = "kdlink"   ' dial-up connection name (see: rasdial)
Const USERNAME   = ""         ' blank = use credentials saved by Windows
Const PASSWORD   = ""         ' blank = use credentials saved by Windows
Const MAXTRY     = 40         ' max dial attempts
Const WAITSEC    = 15         ' seconds to wait after a normal failure
Const NOLINKWAIT = 60         ' seconds to wait when the port is unusable
Const STARTDELAY = 8          ' seconds to wait for the NIC at logon
Const LOCKSTALE  = 120        ' a lock older than this is considered dead
' ------------------------------------------

Dim sh, fso, logPath, lockPath, i, rc, wait
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
logPath  = fso.GetSpecialFolder(2).Path & "\autodial.log"
lockPath = fso.GetSpecialFolder(2).Path & "\autodial.lock"

Sub Log(msg)
    On Error Resume Next
    Dim f
    Set f = fso.OpenTextFile(logPath, 8, True)
    f.WriteLine Now & "  " & msg
    f.Close
    On Error GoTo 0
End Sub

' refresh the lock so other copies can tell this one is alive
Sub TouchLock()
    On Error Resume Next
    Dim f
    Set f = fso.CreateTextFile(lockPath, True)
    f.WriteLine Now
    f.Close
    On Error GoTo 0
End Sub

' drop the lock and quit
Sub Finish(code)
    On Error Resume Next
    fso.DeleteFile lockPath, True
    WScript.Quit code
End Sub

' true when a live copy holds the lock
Function LockIsFresh()
    Dim age
    LockIsFresh = False
    On Error Resume Next
    If fso.FileExists(lockPath) Then
        age = DateDiff("s", fso.GetFile(lockPath).DateLastModified, Now)
        If age < LOCKSTALE Then LockIsFresh = True
    End If
    On Error GoTo 0
End Function

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

' only one copy may run: two of them fight over the same port
If LockIsFresh() Then
    Log "another copy is already running, exit"
    WScript.Quit 0
End If
TouchLock()

WScript.Sleep STARTDELAY * 1000

If IsUp() Then
    Log "already connected to " & CONN & ", nothing to do"
    Finish 0
End If

For i = 1 To MAXTRY
    rc = Dial()
    Log "attempt " & i & ": exit=" & rc

    If rc = 0 Then
        Log "connected"
        Finish 0
    End If

    ' 691 / 623: no usable credentials -> show the dial dialog once
    If rc = 691 Or rc = 623 Then
        Log "no saved credentials (error " & rc & "), opening the dial dialog"
        sh.Run "rasphone.exe -d """ & CONN & """", 1, False
        Finish 1
    End If

    ' 619 / 651 / 756 / 628 / 797: port unusable - usually no cable,
    ' adaptor not ready, or another dial running. Back off longer.
    If rc = 619 Or rc = 651 Or rc = 756 Or rc = 628 Or rc = 797 Then
        wait = NOLINKWAIT
    Else
        wait = WAITSEC
    End If

    Log "retry in " & wait & "s"
    WScript.Sleep wait * 1000
    TouchLock()

    If IsUp() Then
        Log "connection detected, done"
        Finish 0
    End If
Next

Log "gave up after " & MAXTRY & " attempts"
Finish 1
