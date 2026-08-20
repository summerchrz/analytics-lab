Attribute VB_Name = "modAllocationColumns"
Option Explicit

Sub HideZeroColumns()
    Dim ws As Worksheet
    Dim i As Integer
    Dim r As Long, j As Long, k As Long, totalsCol As Long
    Dim c As Long
    Dim monthYearPattern As Object
    Dim cellval As Variant

    r = Range("Totals_Row").Value
    j = Range("First_Column").Value
    k = Range("Last_Column").Value
    totalsCol = k + 1

    Application.ScreenUpdating = False

    Set monthYearPattern = CreateObject("VBScript.RegExp")
    With monthYearPattern
        .Pattern = "^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC) \d{4}$"
        .IgnoreCase = True
        .Global = False
    End With

    For i = 1 To ThisWorkbook.Worksheets.Count
        Set ws = ThisWorkbook.Worksheets(i)
        If ws.Visible = xlSheetVisible Then
            If monthYearPattern.Test(ws.Name) Then
                ws.Columns.Hidden = False

                For c = k To j Step -1
                    cellval = ws.Cells(r, c).Value
                    If Len(cellval) > 0 And Val(cellval) = 0 Then
                        ws.Columns(c).Hidden = True
                    End If
                Next c

                ws.Columns(totalsCol).Hidden = False
            End If
        End If
    Next i

    Application.ScreenUpdating = True
End Sub

Sub UnhideColumns()
    Dim j As Long
    Dim k As Long
    Dim monthYearPattern As Object
    Dim ws As Worksheet

    j = Range("First_Column").Value
    k = Range("Last_Column").Value

    Set monthYearPattern = CreateObject("VBScript.RegExp")
    With monthYearPattern
        .Pattern = "^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC) \d{4}$"
        .IgnoreCase = True
        .Global = False
    End With

    For Each ws In ThisWorkbook.Worksheets
        If ws.Visible = xlSheetVisible And monthYearPattern.Test(ws.Name) Then
            ws.Columns.Hidden = False
        End If
    Next ws

    Application.ScreenUpdating = True
End Sub
