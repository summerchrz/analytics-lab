Attribute VB_Name = "modAllocationDedup"
Option Explicit

Sub Remove_Duplicates()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets("Total Allocation")

    Dim lastRow As Long, lastCol As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column

    If lastRow < 2 Then Exit Sub

    Dim qtyCol As Long: qtyCol = 5

    Dim keepForKey As Object
    Set keepForKey = CreateObject("Scripting.Dictionary")

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    Dim r As Long, c As Long
    Dim trimcol As Long
    trimcol = 0

    For c = 1 To lastCol
        If UCase$(Trim$(CStr(ws.Cells(1, c).Value2))) = "TRIM KEY" Then
            trimcol = c
        End If
    Next c

    For r = lastRow To 2 Step -1
        Dim keyStr As String: keyStr = ""

        For c = 1 To lastCol
            If c <> qtyCol Then
                If c = trimcol Then
                    keyStr = keyStr & "|" & Trim$(CStr(ws.Cells(r, c).Value2))
                Else
                    Dim hdr As String
                    hdr = UCase$(Trim$(CStr(ws.Cells(1, c).Value2)))
                    keyStr = keyStr & "|" & NormKeyValue(ws.Cells(r, c).Value2, hdr)
                End If
            End If
        Next c

        Dim qty As Double
        qty = Val(ws.Cells(r, qtyCol).Value2)

        If keepForKey.Exists(keyStr) Then
            ws.Cells(keepForKey(keyStr), qtyCol).Value = Val(ws.Cells(keepForKey(keyStr), qtyCol).Value2) + qty
            ws.Rows(r).Delete
        Else
            keepForKey.Add keyStr, r
        End If
    Next r

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
End Sub

Private Function NormKeyValue(ByVal v As Variant, ByVal header As String) As String
    Dim s As String

    If IsError(v) Or IsNull(v) Then
        NormKeyValue = ""
        Exit Function
    End If

    If LCase$(header) = "del mo" Then
        If IsDate(v) Then
            NormKeyValue = Format$(DateSerial(Year(CDate(v)), Month(CDate(v)), 1), "yyyymm")
            Exit Function
        End If

        s = Trim$(CStr(v))
        If Len(s) = 0 Then
            NormKeyValue = ""
            Exit Function
        End If

        If IsNumeric(s) Then
            If Len(s) = 6 Then
                NormKeyValue = s
            Else
                On Error Resume Next
                NormKeyValue = Format$(DateSerial(Year(CDate(CDbl(s))), Month(CDate(CDbl(s))), 1), "yyyymm")
                On Error GoTo 0
            End If
            Exit Function
        End If

        On Error Resume Next
        If IsDate(s) Then
            NormKeyValue = Format$(DateSerial(Year(CDate(s)), Month(CDate(s)), 1), "yyyymm")
        Else
            NormKeyValue = UCase$(s)
        End If
        On Error GoTo 0
        Exit Function
    End If

    s = Trim$(CStr(v))
    NormKeyValue = UCase$(s)
End Function
