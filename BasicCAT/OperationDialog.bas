B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private frm As Form
	Private OkayButton As Button
	Private OperationsTableView As TableView
End Sub

Sub frm_CloseRequest (EventData As Event)
	EventData.Consume
End Sub

Public Sub Show
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("operation")
	frm.Show
End Sub

Public Sub Add(values() As Object)
	If values.Length=OperationsTableView.ColumnsCount Then
		OperationsTableView.Items.add(values)
	End If
End Sub

Public Sub UpdateByIndex(row As Int,values() As Object)
	If values.Length=OperationsTableView.ColumnsCount Then
		OperationsTableView.Items.Set(row,values)
	End If
End Sub

Public Sub UpdateByName(name As String,values() As Object)
	Dim index As Int=0
	For Each rowValues() As String In OperationsTableView.Items
		If rowValues(0)=name Then
			UpdateByIndex(index,values)
			Return
		End If
		index=index+1
	Next
	'no name matched
	Add(values)
End Sub

Sub OkayButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub

Public Sub SetButtonText(text As String)
	OkayButton.Text=text
End Sub

Public Sub EnableOkayButton(enabled As Boolean)
	OkayButton.Enabled=enabled
End Sub