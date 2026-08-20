Attribute VB_Name = "cPPTEvents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

Option Explicit

Public WithEvents App As Application

Private Sub App_SlideShowBegin(ByVal Wn As SlideShowWindow)
    'StartCountdown
    'NOTE: StartCountdown shows input boxes.
    'If you want it to start automatically without prompting,
    'we can change StartCountdown to use default duration silently.
    StartCountdown
End Sub

Private Sub App_SlideShowEnd(ByVal Pres As Presentation)
    StopCountdown
End Sub
