Attribute VB_Name = "ThisPresentation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True

Private Sub Presentation_SlideShowEnd(ByVal Pres As Presentation)
    On Error Resume Next
    StopCountdown
End Sub

Private Sub Presentation_Close()
    On Error Resume Next
    StopCountdown
End Sub
