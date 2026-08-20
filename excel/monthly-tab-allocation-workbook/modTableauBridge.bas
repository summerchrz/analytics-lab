Attribute VB_Name = "modTableauBridge"
Option Explicit

Sub Tableau_Input()
    Dim ws As Worksheet
    Dim output As Worksheet
    Dim formulaText As String
    Dim monthYearPattern As Object
    Dim RowCount As Long
    Dim ColumnCount As Long
    Dim FirstRow As Long
    Dim lastRow As Long
    Dim FirstCol As Long
    Dim lastCol As Long
    Dim colLetter As String
    Dim Tableau As Worksheet
    Dim startRow As Long, endRow As Long
    Dim startCol As Long, endCol As Long
    Dim processedSheets As String

    FirstRow = Range("First_Row").Value
    lastRow = Range("Last_Row").Value
    FirstCol = Range("First_Column").Value
    lastCol = Range("Last_Column").Value
    processedSheets = ""

    Set monthYearPattern = CreateObject("VBScript.RegExp")
    With monthYearPattern
        .Pattern = "^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC) \d{4}$"
        .IgnoreCase = True
        .Global = False
    End With

    Set Tableau = ThisWorkbook.Sheets("Tableau")

    For Each ws In ThisWorkbook.Worksheets
        If ws.Visible = xlSheetVisible Then
            If monthYearPattern.Test(ws.Name) Then
                Set output = ws

                If InStr(processedSheets, ws.Name) = 0 Then
                    If processedSheets = "" Then
                        processedSheets = ws.Name
                    Else
                        processedSheets = processedSheets & ", " & ws.Name
                    End If
                End If

                startRow = FirstRow
                endRow = lastRow
                startCol = FirstCol
                endCol = lastCol

                For RowCount = startRow To endRow
                    For ColumnCount = startCol To endCol
                        colLetter = Split(output.Cells(1, ColumnCount).Address(True, False), "$")(0)
                        formulaText = "=IFNA(SUMIFS(" & _
                                      "INDEX('" & Tableau.Name & "'!$H$3:$W$7001,0, MATCH($E$1, '" & Tableau.Name & "'!$H$2:$W$2,0))," & _
                                      "'" & Tableau.Name & "'!$G$3:$G$7001, $H" & RowCount & ", " & _
                                      "'" & Tableau.Name & "'!$D$3:$D$7001, " & colLetter & "$9),0)"

                        output.Cells(RowCount, ColumnCount).Formula = formulaText
                    Next ColumnCount
                Next RowCount

                With output.Range(output.Cells(startRow, startCol), output.Cells(lastRow, lastCol))
                    .Value = .Value
                End With
            End If
        End If
    Next ws

    If processedSheets = "" Then
        MsgBox "No sheets matched the Month-Year pattern.", vbInformation
    Else
        MsgBox "Formulas applied and converted to values on sheets: " & vbNewLine & processedSheets, vbInformation
    End If
End Sub

Sub Clear_Tableau()
    Range("H2:W7001").Select
    Selection.ClearContents
    Range("A3:G7001").Select
    Selection.ClearContents
    Range("A2").Select
End Sub
