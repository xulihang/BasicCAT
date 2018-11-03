B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private XWPF As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(filepath As String,mode As String)
	Select mode
		Case "read"
			XWPF.InitializeNewInstance("org.apache.poi.xwpf.usermodel.XWPFDocument",Array(File.OpenInput(filepath,"")))
		Case "write"
			XWPF.InitializeNewInstance("org.apache.poi.xwpf.usermodel.XWPFDocument",Null)
	End Select
	
End Sub

Public Sub readTable As List
	Dim tables As List
	tables=XWPF.RunMethod("getTables",Null)
	Dim table As JavaObject
	table=tables.Get(0)
	Dim rows As List
	rows=table.RunMethod("getRows",Null)
	Dim resultRows As List
	resultRows.Initialize
	For Each row As JavaObject In rows
		resultRows.Add(Array As String(row.RunMethodJO("getCell",Array(0)).RunMethod("getText",Null),row.RunMethodJO("getCell",Array(1)).RunMethod("getText",Null)))
	Next
	Log(resultRows)
	Return resultRows
End Sub

Public Sub createTable(rows As List,outputPath As String)
	Dim table As JavaObject
	table=XWPF.RunMethod("createTable",Null)
	Dim first As Boolean=True
	For Each row() As String In rows
		Dim tableRow As JavaObject
		If first Then
			tableRow=table.RunMethod("getRow",Array(0))
			tableRow.RunMethodJO("getCell",Array(0)).RunMethod("setText",Array(row(0)))
			tableRow.RunMethodJO("addNewTableCell",Null).RunMethod("setText",Array(row(1)))
			first=False
		Else
			tableRow=table.RunMethod("createRow",Null)
			tableRow.RunMethodJO("getCell",Array(0)).RunMethod("setText",Array(row(0)))
			tableRow.RunMethodJO("getCell",Array(1)).RunMethod("setText",Array(row(1)))
		End If
		
	Next
	table.RunMethod("setWidth",Array("100%"))
	Dim output As OutputStream
	output=File.OpenOutput(outputPath,"",False)
	XWPF.RunMethod("write",Array(output))
	output.Close
	XWPF.RunMethod("close",Null)
End Sub