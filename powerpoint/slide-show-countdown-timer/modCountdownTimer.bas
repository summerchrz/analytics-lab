Attribute VB_Name = "modCountdownTimer"
Option Explicit

'================ CONFIG ================
Public Const TIMER_SHAPE_NAME As String = "TimerBox"
Private Const MAX_DURATION_SECONDS As Long = 2 * 3600 + 55 * 60
Private Const DEFAULT_DURATION As String = "2:55:00"
Private Const TICK_MS As Long = 1000

'================ STATE =================
Private gEndTime As Date
Private gRunning As Boolean
Private gStopRequested As Boolean
Private gMode As String ' "Duration" or "Endtime"

'Windows timer state
Private gTimerID As LongPtr

'============== WINDOWS TIMER (SAFE) ==============
#If VBA7 Then
   Private Declare PtrSafe Function SetTimer Lib "user32" ( _
       ByVal hwnd As LongPtr, _
       ByVal nIDEvent As LongPtr, _
       ByVal uElapse As Long, _
       ByVal lpTimerFunc As LongPtr) As LongPtr

   Private Declare PtrSafe Function KillTimer Lib "user32" ( _
       ByVal hwnd As LongPtr, _
       ByVal nIDEvent As LongPtr) As Long
#Else
   Private Declare Function SetTimer Lib "user32" ( _
       ByVal hwnd As Long, _
       ByVal nIDEvent As Long, _
       ByVal uElapse As Long, _
       ByVal lpTimerFunc As Long) As Long

   Private Declare Function KillTimer Lib "user32" ( _
       ByVal hwnd As Long, _
       ByVal nIDEvent As Long) As Long
#End If

'This is the callback Windows calls every second
Public Sub TimerProc(ByVal hwnd As LongPtr, ByVal uMsg As Long, ByVal idEvent As LongPtr, ByVal dwTime As Long)
   On Error Resume Next

   If Not SlideShowActive() Then
        gStopRequested = True
    End If
   
   If gStopRequested Then
        gRunning = False
        gStopRequested = False
        StopWinTimer
        Exit Sub
    End If
    
    If gRunning Then
        TickCountdown
    End If
End Sub

'================ PUBLIC MACROS =================
Public Sub StartCountdown()
   Dim choice As VbMsgBoxResult
   Dim s As String
   Dim hours As Long, mins As Long, secs As Long
   Dim totalSeconds As Long
   Dim endClock As Date
   Dim secondsToGo As Long

   If Not SlideShowActive() Then
       MsgBox "Start Slide Show first, then run StartCountdown.", vbExclamation
       Exit Sub
   End If

   If gRunning Then
       MsgBox "Timer already running.", vbInformation
       Exit Sub
   End If

   choice = MsgBox( _
       "Choose countdown mode:" & vbCrLf & vbCrLf & _
       "YES = Countdown by duration (default 2:55:00, max 2:55:00)" & vbCrLf & _
       "NO  = Countdown to an end time (e.g., 3:30 PM)" & vbCrLf & _
       "CANCEL = abort", _
       vbYesNoCancel + vbQuestion, _
       "Countdown Timer")

   If choice = vbCancel Then Exit Sub

   If choice = vbYes Then
       gMode = "Duration"
       s = InputBox( _
           "Enter duration as H:MM or H:MM:SS (max 2:55:00)." & vbCrLf & _
           "Leave blank to use default: " & DEFAULT_DURATION, _
           "Duration", _
           DEFAULT_DURATION)

       If Len(Trim$(s)) = 0 Then s = DEFAULT_DURATION

       If Not ParseHMS(s, hours, mins, secs) Then
           MsgBox "Could not parse duration. Use H:MM or H:MM:SS (e.g., 2:55 or 2:55:00).", vbExclamation
           Exit Sub
       End If

       totalSeconds = hours * 3600 + mins * 60 + secs

       If totalSeconds <= 0 Then
           MsgBox "Duration must be greater than zero.", vbExclamation
           Exit Sub
       End If

       If totalSeconds > MAX_DURATION_SECONDS Then
           MsgBox "Max allowed duration is 2:55:00. Please enter 2:55:00 or less.", vbExclamation
           Exit Sub
       End If

       gEndTime = Now + (totalSeconds / 86400#)

   ElseIf choice = vbNo Then
       gMode = "Endtime"
       s = InputBox( _
           "Enter end time (example: 3:30 PM OR 15:30)", _
           "End Time", _
           Format(Now + TimeSerial(2, 55, 0), "h:mm AM/PM"))

       If Len(Trim$(s)) = 0 Then Exit Sub

       On Error GoTo BadTime
       endClock = CDate(s)
       On Error GoTo 0

       If TimeValue(endClock) < TimeValue(Now) Then
           gEndTime = Date + 1 + TimeValue(endClock)
       Else
           gEndTime = Date + TimeValue(endClock)
       End If
   End If

   secondsToGo = CLng((gEndTime - Now) * 86400#)
   
   If secondsToGo <= 0 Then
        MsgBox "End time must be in the future.", vbExclamation
           Exit Sub
   End If
   
   If secondsToGo > MAX_DURATION_SECONDS Then
        MsgBox "Max allowed countdown is " & DEFAULT_DURATION & ". Choose a time within 2:55 from now.", vbExclamation
        Exit Sub
    End If
    
   'Make sure shape exists somewhere we can update
   If FindTimerShape() Is Nothing Then
       MsgBox "Couldn't find a shape named '" & TIMER_SHAPE_NAME & "'." & vbCrLf & _
              "Put it on the Slide Master, OR ensure the current slide has that shape name.", vbExclamation
       Exit Sub
   End If
   
   Dim shp As Shape
   Set shp = FindTimerShapeOnCurrentSlide()
   If Not shp Is Nothing Then shp.ZOrder msoBringToFront

   StopWinTimer
   gRunning = True
   SetTimerText "00:00:00"
   UpdateTimerText
   StartWinTimer
   Exit Sub

BadTime:
   MsgBox "Could not parse that end time. Try formats like 3:30 PM or 15:30.", vbExclamation
End Sub

Public Sub StopCountdown()
   gStopRequested = True
End Sub

Public Sub ResetCountdownDisplay()
   SetTimerText "00:00:00"
End Sub

'Called by events too (keeps new slide "fresh")
Public Sub RefreshTimerOnCurrentSlide()
   If gRunning Then UpdateTimerText
End Sub

'================ INTERNAL TICK =================
Public Sub TickCountdown()
   If Not gRunning Then Exit Sub

   If Not SlideShowActive() Then
       Exit Sub
   End If

   If Now >= gEndTime Then
       SetTimerText "00:00:00"
       StopCountdown
       Exit Sub
   End If

   UpdateTimerText
End Sub

Private Sub UpdateTimerText()
   Dim remaining As Long
   Dim h As Long, m As Long, s As Long

   remaining = Fix((gEndTime - Now) * 86400#)
   If remaining < 0 Then remaining = 0

   h = remaining \ 3600
   m = (remaining Mod 3600) \ 60
   s = remaining Mod 60

   SetTimerText Format$(h, "00") & ":" & Format$(m, "00") & ":" & Format$(s, "00")
End Sub

'================ TIMER START/STOP =================
Private Sub StartWinTimer()
   StopWinTimer
   gTimerID = SetTimer(0, 0, TICK_MS, AddressOf TimerProc)
End Sub

Private Sub StopWinTimer()
   If gTimerID <> 0 Then
       KillTimer 0, gTimerID
       gTimerID = 0
   End If
End Sub

'================ SHAPE UPDATE =================
Private Sub SetTimerText(ByVal txt As String)
   Dim shp As Shape

   'Update master (preferred)
   Set shp = FindTimerShapeOnCurrentSlide()
   If Not shp Is Nothing Then
        SetShapeText shp, txt
        DoEvents
        Exit Sub
    End If

   'Also update current slide (helps if a slide hides background graphics / weird layouts)
   Set shp = FindTimerShapeMaster()
   If Not shp Is Nothing Then
        SetShapeText shp, txt
        DoEvents
    End If
End Sub

Private Sub SetShapeText(ByVal shp As Shape, ByVal txt As String)
   On Error Resume Next

   If shp.HasTextFrame Then
        shp.TextFrame.TextRange.Text = ""
        shp.TextFrame.TextRange.Text = txt
    End If
      
    If shp.HasTextFrame Then
        shp.TextFrame2.TextRange.Text = ""
        shp.TextFrame2.TextRange.Text = txt
    End If
    
    If Err.Number <> 0 Then
        Err.Clear
        shp.TextFrame.TextRange.Text = txt
    End If
    
   On Error GoTo 0
End Sub

Private Function FindTimerShape() As Shape
    Dim shp As Shape
    
    Set shp = FindTimerShapeOnCurrentSlide()
    If Not shp Is Nothing Then
        Set FindTimerShape = shp
        Exit Function
    End If
    
    Set shp = FindTimerShapeMaster()
    Set FindTimerShape = shp
End Function

Private Function FindTimerShapeMaster() As Shape
   Dim sm As Object
   Dim shp As Shape

   On Error GoTo CleanFail
   Set sm = ActivePresentation.SlideMaster

   For Each shp In sm.Shapes
       If shp.Name = TIMER_SHAPE_NAME Then
           Set FindTimerShapeMaster = shp
           Exit Function
       End If
   Next shp
   
   Set FindTimerShapeMaster = Nothing
   Exit Function
   
CleanFail:
   Set FindTimerShapeMaster = Nothing
End Function

Private Function FindTimerShapeOnCurrentSlide() As Shape
   Dim sld As Slide
   Dim shp As Shape

   On Error GoTo CleanFail
   If Not SlideShowActive() Then GoTo CleanFail

   Set sld = ActivePresentation.SlideShowWindow.View.Slide

   For Each shp In sld.Shapes
       If shp.Name = TIMER_SHAPE_NAME Then
           Set FindTimerShapeOnCurrentSlide = shp
           Exit Function
       End If
   Next shp
   
   For Each shp In sld.CustomLayout.Shapes
    If shp.Name = TIMER_SHAPE_NAME Then
        Set FindTimerShapeOnCurrentSlide = shp
        Exit Function
    End If
    Next shp
    
    For Each shp In sld.Master.Shapes
        If shp.Name = TIMER_SHAPE_NAME Then
            Set FindTimerShapeOnCurrentSlide = shp
            Exit Function
        End If
    Next shp
   
CleanFail:
   Set FindTimerShapeOnCurrentSlide = Nothing
End Function

'================ HELPERS =================
Private Function SlideShowActive() As Boolean
   On Error Resume Next
   SlideShowActive = Not (ActivePresentation.SlideShowWindow Is Nothing)
   On Error GoTo 0
End Function

Private Function ParseHMS(ByVal s As String, ByRef h As Long, ByRef m As Long, ByRef sec As Long) As Boolean
   Dim parts() As String
   Dim n As Long

   s = Trim$(s)
   parts = Split(s, ":")
   n = UBound(parts) - LBound(parts) + 1

   On Error GoTo Bad

   If n = 2 Then
       h = CLng(parts(0))
       m = CLng(parts(1))
       sec = 0
   ElseIf n = 3 Then
       h = CLng(parts(0))
       m = CLng(parts(1))
       sec = CLng(parts(2))
   Else
       GoTo Bad
   End If

   If h < 0 Or m < 0 Or m > 59 Or sec < 0 Or sec > 59 Then GoTo Bad
   ParseHMS = True
   Exit Function

Bad:
   ParseHMS = False
End Function
