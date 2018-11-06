B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private result As List
	Private sourceTextArea As TextArea
	Private targetTextArea As TextArea
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(source As String,target As String)
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("TMEditor")
	result.Initialize
	result.Add(source)
	result.Add(target)
	sourceTextArea.Text=source
	targetTextArea.Text=target
End Sub

Public Sub showAndWait As List
	frm.ShowAndWait
	Return result
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	Dim list1 As List
	list1.Initialize
	list1.Add(sourceTextArea.Text)
	list1.Add(targetTextArea.Text)
	result=list1
	frm.Close
End Sub