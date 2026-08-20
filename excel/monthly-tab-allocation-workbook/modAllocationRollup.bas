Attribute VB_Name = "modAllocationRollup"
Option Explicit

Public Sub Build_TotalAllocation_NoTrim()
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False

    Dim wsSrc As Worksheet
    Dim wsOut As Worksheet
    Set wsSrc = ThisWorkbook.Worksheets("Total Allocation")

    On Error Resume Next
    Set wsOut = ThisWorkbook.Worksheets("Total Allocation (No Trim)")

    Dim colFinal As Long
    Dim colTrim As Long
    colFinal = FindHeaderCol(wsSrc, "FINAL_COUNT")
    colTrim = FindHeaderCol(wsSrc, "TRIM_KEY")
    On Error GoTo 0

    If wsOut Is Nothing Then
        Set wsOut = ThisWorkbook.Worksheets.Add(After:=wsSrc)
        wsOut.Name = "Total Allocation (No Trim)"
    Else
        wsOut.Cells.Clear
        wsSrc.Rows(1).Copy
        wsOut.Rows(1).PasteSpecial xlPasteAll
        Application.CutCopyMode = False
        wsOut.Columns(colTrim).Delete
    End If

    Dim lastRow As Long
    Dim lastCol As Long
    lastRow = wsSrc.Cells(wsSrc.Rows.Count, 1).End(xlUp).Row
    lastCol = wsSrc.Cells(1, wsSrc.Columns.Count).End(xlToLeft).Column

    If colFinal = 0 Then
        MsgBox "FINAL_COUNT column not found.", vbCritical
        GoTo CleanExit
    End If
    If colTrim = 0 Then
        MsgBox "TRIM_KEY column not found.", vbCritical
        GoTo CleanExit
    End If

    Dim dict As Object
    Set dict = CreateObject("Scripting.Dictionary")
    Dim rowRef As Object
    Set rowRef = CreateObject("Scripting.Dictionary")

    Dim r As Long
    Dim keyStr As String
    Dim qty As Double
    For r = 2 To lastRow
        keyStr = BuildKey(wsSrc, r, lastCol, colTrim, colFinal)
        qty = wsSrc.Cells(r, colFinal).Value
        If dict.Exists(keyStr) Then
            dict(keyStr) = dict(keyStr) + qty
        Else
            dict.Add keyStr, qty
            rowRef.Add keyStr, r
        End If
    Next r

    Dim outRow As Long
    outRow = 2
    Dim k As Variant
    Dim srcRow As Long
    Dim outCol As Long
    Dim c As Long

    For Each k In dict.Keys
        srcRow = rowRef(k)
        outCol = 1
        For c = 1 To lastCol
            If c <> colTrim Then
                If c = colFinal Then
                    wsOut.Cells(outRow, outCol).Value = dict(k)
                Else
                    wsOut.Cells(outRow, outCol).Value = wsSrc.Cells(srcRow, c).Value
                End If
                outCol = outCol + 1
            End If
        Next c
        outRow = outRow + 1
    Next k

    wsOut.Columns.AutoFit
    MsgBox "Total Allocation (No Trim) built successfully."

CleanExit:
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
End Sub

Private Function FindHeaderCol(ws As Worksheet, headerText As String) As Long
    Dim lastCol As Long
    Dim c As Long
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    For c = 1 To lastCol
        If UCase(Trim(ws.Cells(1, c).Value)) = UCase(headerText) Then
            FindHeaderCol = c
            Exit Function
        End If
    Next c
End Function

Private Function BuildKey(ws As Worksheet, r As Long, lastCol As Long, colTrim As Long, colFinal As Long) As String
    Dim c As Long
    Dim keyStr As String
    Dim DELIM As String
    DELIM = Chr(30)
    For c = 1 To lastCol
        If c <> colTrim And c <> colFinal Then
            keyStr = keyStr & DELIM & ws.Cells(r, c).Value
        End If
    Next c
    If Len(keyStr) > 0 Then
        keyStr = Mid(keyStr, 2)
    End If
    BuildKey = keyStr
End Function

Private Function MonthTokenFromDelMo(ByVal v As Variant) As String
    If IsError(v) Or IsNull(v) Then Exit Function
    If IsDate(v) Then
        MonthTokenFromDelMo = Format$(DateSerial(Year(CDate(v)), Month(CDate(v)), 1), "yyyymm")
        Exit Function
    End If
    Dim s As String: s = Trim$(CStr(v))
    If Len(s) = 0 Then Exit Function
    If IsNumeric(s) And Len(s) = 6 Then
        MonthTokenFromDelMo = s
    ElseIf IsDate(s) Then
        MonthTokenFromDelMo = Format$(DateSerial(Year(CDate(s)), Month(CDate(s)), 1), "yyyymm")
    End If
End Function

Private Function MonthTokenFromHeader(ByVal hdr As Variant) As String
    If IsDate(hdr) Then
        MonthTokenFromHeader = Format$(DateSerial(Year(CDate(hdr)), Month(CDate(hdr)), 1), "yyyymm")
        Exit Function
    End If
    Dim s As String: s = Trim$(CStr(hdr))
    If Len(s) = 0 Then Exit Function
    Dim d As Variant
    On Error Resume Next
    d = DateValue("1-" & s)
    On Error GoTo 0
    If IsDate(d) Then
        MonthTokenFromHeader = Format$(DateSerial(Year(CDate(d)), Month(CDate(d)), 1), "yyyymm")
    End If
End Function

Public Sub Build_AddsByMonth_FromTotalAllocation_SumLines()
    Dim wsT As Worksheet, wsA As Worksheet
    Set wsT = ThisWorkbook.Worksheets("Total Allocation")
    Set wsA = ThisWorkbook.Worksheets("Adds by Month")

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    Const COL_POOL_T As Long = 2
    Const COL_DELMO As Long = 4
    Const COL_QTY As Long = 5
    Const COL_POOL_A As Long = 6
    Const FIRST_MONTH_COL As Long = 7

    Dim dict As Object: Set dict = CreateObject("Scripting.Dictionary")
    Dim lastT As Long: lastT = wsT.Cells(wsT.Rows.Count, COL_POOL_T).End(xlUp).Row
    Dim r As Long

    For r = 2 To lastT
        Dim pool As String
        pool = UCase$(Trim$(CStr(wsT.Cells(r, COL_POOL_T).Value2)))
        If Len(pool) = 0 Then GoTo NextT

        Dim mt As String
        mt = MonthTokenFromDelMo(wsT.Cells(r, COL_DELMO).Value2)
        If Len(mt) = 0 Then GoTo NextT

        Dim qty As Double
        qty = Val(wsT.Cells(r, COL_QTY).Value2)
        dict(pool & "|" & mt) = dict(pool & "|" & mt) + qty
NextT:
    Next r

    Dim monthCols As Object: Set monthCols = CreateObject("Scripting.Dictionary")
    Dim lastColA As Long: lastColA = wsA.Cells(1, wsA.Columns.Count).End(xlToLeft).Column
    Dim c As Long
    For c = FIRST_MONTH_COL To lastColA
        mt = MonthTokenFromHeader(wsA.Cells(1, c).Value2)
        If Len(mt) > 0 Then monthCols(mt) = c
    Next c

    Dim lastRowA As Long: lastRowA = wsA.Cells(wsA.Rows.Count, COL_POOL_A).End(xlUp).Row
    If lastRowA >= 2 And lastColA >= FIRST_MONTH_COL Then
        wsA.Range(wsA.Cells(2, FIRST_MONTH_COL), wsA.Cells(lastRowA, lastColA)).ClearContents
    End If

    For r = 2 To lastRowA
        pool = UCase$(Trim$(CStr(wsA.Cells(r, COL_POOL_A).Value2)))
        If Len(pool) = 0 Then GoTo NextA

        Dim mk As Variant
        For Each mk In monthCols.Keys
            Dim k As String
            k = pool & "|" & CStr(mk)
            If dict.Exists(k) Then
                wsA.Cells(r, monthCols(mk)).Value = dict(k)
            Else
                wsA.Cells(r, monthCols(mk)).Value = 0
            End If
        Next mk
NextA:
    Next r

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
End Sub
