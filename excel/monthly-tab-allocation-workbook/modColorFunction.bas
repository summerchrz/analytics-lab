Attribute VB_Name = "modColorFunction"
Option Explicit

Function ColorFunction(rColor As Range, rRange As Range, Optional SUM As Boolean)
    Dim rCell As Range
    Dim lCol As Long
    Dim vResult
    lCol = rColor.Interior.ColorIndex
    If SUM = True Then
        For Each rCell In rRange
            If rCell.Interior.ColorIndex = lCol Then
                vResult = WorksheetFunction.SUM(rCell, vResult)
            End If
        Next rCell
    Else
        For Each rCell In rRange
            If rCell.Interior.ColorIndex = lCol Then
                vResult = 1 + vResult
            End If
        Next rCell
    End If
    ColorFunction = vResult
End Function
