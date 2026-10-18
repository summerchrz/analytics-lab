Attribute VB_Name = "modAllocationExport"
Option Explicit

Sub GenerateCSV()
    Dim WS_Count As Long
    Dim i As Long
    Dim r As Long
    Dim j As Long
    Dim k As Long
    Dim L As Long
    Dim M As String
    Dim n As String
    Dim p As String
    Dim RowCount As Long
    Dim ColCount As Long
    Dim RiskSPI As String
    Dim CategoryBCode As String
    Dim LineCount As Long
    Dim SaveCSV As Workbook
    Dim SavePath As String
    Dim FirstRow As Long
    Dim lastRow As Long
    Dim re As Object

    LineCount = 2
    r = Range("Totals_Row").Value
    FirstRow = Range("First_Row").Value
    lastRow = Range("Last_Row").Value
    j = Range("First_Column").Value
    k = Range("Last_Column").Value
    L = Range("Model_Year").Value
    M = Range("Manufacturer").Value
    n = Range("Group_A_Code").Value
    p = Range("Group_B_Code").Value
    RiskSPI = Range("CategoryACode").Value
    CategoryBCode = Range("Category_B_Code").Value
    SavePath = Range("CSV_Save").Value
    WS_Count = ActiveWorkbook.Worksheets.Count

    With ThisWorkbook.Worksheets("CSV")
        .Rows("2:" & .Rows.Count).ClearContents
    End With

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False

    Set re = CreateObject("VBScript.RegExp")
    With re
        .Pattern = "^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC) \d{4}$"
        .IgnoreCase = True
    End With

    For i = 1 To WS_Count
        If ThisWorkbook.Worksheets(i).Visible = xlSheetVisible And re.Test(ThisWorkbook.Worksheets(i).Name) Then
            For RowCount = FirstRow To lastRow
                For ColCount = j To k
                    If ThisWorkbook.Worksheets(i).Cells(RowCount, ColCount) <> "" And ThisWorkbook.Worksheets(i).Cells(RowCount, ColCount) <> 0 Then
                        If ThisWorkbook.Worksheets(i).Cells(RowCount, ColCount).Font.Color = 0 Then
                            If Range("Use_Row_SPI").Value = "Y" Then
                                If ThisWorkbook.Worksheets(i).Cells(RowCount, 6) = "GROUP_A" Then
                                    Worksheets("CSV").Cells(LineCount, 1).Value = n
                                ElseIf ThisWorkbook.Worksheets(i).Cells(RowCount, 6) = "GROUP_B" Then
                                    Worksheets("CSV").Cells(LineCount, 1).Value = p
                                Else
                                    Worksheets("CSV").Cells(LineCount, 1).Value = "UNKNOWN"
                                End If
                            ElseIf ThisWorkbook.Worksheets(i).Cells(6, ColCount) = "CATEGORY_A" Then
                                Worksheets("CSV").Cells(LineCount, 1).Value = RiskSPI
                            ElseIf ThisWorkbook.Worksheets(i).Cells(6, ColCount) = "CATEGORY_B" Then
                                Worksheets("CSV").Cells(LineCount, 1).Value = CategoryBCode
                            Else
                                Worksheets("CSV").Cells(LineCount, 1).Value = "UNKNOWN"
                            End If

                            Worksheets("CSV").Cells(LineCount, 2).Value = ThisWorkbook.Worksheets(i).Cells(FirstRow - 7, ColCount)
                            Worksheets("CSV").Cells(LineCount, 3).Value = ThisWorkbook.Worksheets(i).Cells(FirstRow - 8, ColCount)
                            Worksheets("CSV").Cells(LineCount, 4).Value = ThisWorkbook.Worksheets(i).Cells(FirstRow - 6, ColCount)
                            Worksheets("CSV").Cells(LineCount, 5).Value = L
                            Worksheets("CSV").Cells(LineCount, 6).Value = ThisWorkbook.Worksheets(i).Cells(FirstRow - 2, ColCount)
                            Worksheets("CSV").Cells(LineCount, 7).Value = ThisWorkbook.Worksheets(i).Cells(RowCount, j - 1)
                            Worksheets("CSV").Cells(LineCount, 8).Value = ThisWorkbook.Worksheets(i).Cells(1, 5)
                            Worksheets("CSV").Cells(LineCount, 9).Value = ThisWorkbook.Worksheets(i).Cells(RowCount, ColCount)
                            LineCount = LineCount + 1
                        End If
                    End If
                Next ColCount
            Next RowCount
        End If
    Next i

    If Range("Save_Toggle").Value = "Y" Then
        Workbooks.Add
        Set SaveCSV = ActiveWorkbook
        ThisWorkbook.Worksheets("CSV").Cells.Copy
        SaveCSV.Worksheets("Sheet1").Paste
        SaveCSV.Worksheets("Sheet1").Range("A1").Select
        SaveCSV.SaveAs Filename:=SavePath
    End If

    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
End Sub

Sub TotalAllocation()
    Dim ws As Worksheet
    Dim i As Long
    Dim r As Long
    Dim j As Long
    Dim k As Long
    Dim L As Long
    Dim RowCount As Long
    Dim ColCount As Long
    Dim RiskSPI As String
    Dim CategoryBCode As String
    Dim LineCount As Long
    Dim SavePath As String
    Dim re As Object
    Dim FirstRow As Long
    Dim lastRow As Long
    Dim dropShipRange As Range
    Dim dropVal

    With ThisWorkbook.Worksheets("Total Allocation")
        .Rows("2:" & .Rows.Count).ClearContents
    End With

    LineCount = 2
    r = Range("Totals_Row").Value
    FirstRow = Range("First_Row").Value
    lastRow = Range("Last_Row").Value
    j = Range("First_Column").Value
    k = Range("Last_Column").Value
    L = Range("Model_Year").Value
    RiskSPI = Range("CategoryACode").Value
    CategoryBCode = Range("Category_B_Code").Value
    SavePath = Range("CSV_Save").Value

    On Error Resume Next
    Set dropShipRange = ThisWorkbook.Names("Drop_Ship").RefersToRange
    On Error GoTo 0

    Set re = CreateObject("VBScript.RegExp")
    With re
        .Pattern = "^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC) \d{4}$"
        .IgnoreCase = True
    End With

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False

    For Each ws In ThisWorkbook.Worksheets
        If ws.Visible = xlSheetVisible And re.Test(ws.Name) Then
            For RowCount = FirstRow To lastRow
                If Not dropShipRange Is Nothing Then
                    dropVal = Application.VLookup(Trim$(CStr(ws.Cells(RowCount, j - 1).Value)), dropShipRange, 2, False)
                    If IsError(dropVal) Then dropVal = ""
                Else
                    dropVal = ""
                End If

                For ColCount = j To k
                    If ws.Cells(RowCount, ColCount) <> "" And ws.Cells(RowCount, ColCount) <> 0 Then
                        If ws.Cells(RowCount, ColCount).Font.Color = 0 Then
                            Worksheets("Total Allocation").Cells(LineCount, 1).Value = dropVal
                            Worksheets("Total Allocation").Cells(LineCount, 2).Value = ws.Cells(RowCount, j - 1)
                            Worksheets("Total Allocation").Cells(LineCount, 3).Value = "RG"
                            Worksheets("Total Allocation").Cells(LineCount, 4).Value = ws.Cells(1, 5)
                            Worksheets("Total Allocation").Cells(LineCount, 5).Value = ws.Cells(RowCount, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 6).Value = L
                            Worksheets("Total Allocation").Cells(LineCount, 7).Value = Application.WorksheetFunction.VLookup(ws.Cells(5, ColCount), Range("Manufacturer_Table"), 2, False)
                            Worksheets("Total Allocation").Cells(LineCount, 9).Value = ws.Cells(FirstRow - 6, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 11).Value = IIf(Range("Alt_Pool_Enabled").Value = "Y", ws.Cells(RowCount, j - 2), "")
                            Worksheets("Total Allocation").Cells(LineCount, 12).Value = ws.Cells(FirstRow - 4, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 13).Value = ws.Cells(FirstRow - 5, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 14).Value = ws.Cells(FirstRow - 8, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 16).Value = ws.Cells(FirstRow - 2, ColCount)
                            Worksheets("Total Allocation").Cells(LineCount, 15).Value = "Newly Allocated"
                            LineCount = LineCount + 1
                        End If
                    End If
                Next ColCount
            Next RowCount
        End If
    Next ws

    Call Remove_Duplicates
    Call Build_AddsByMonth_FromTotalAllocation_SumLines
    Call Build_TotalAllocation_NoTrim

    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
End Sub
