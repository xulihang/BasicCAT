B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
    Private segment As List
	Private TextArea1 As TextArea
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",400,200)
	frm.RootPane.LoadLayout("inputTextArea")
End Sub


Public Sub showAndWait
	segment=Main.currentProject.segments.Get(Main.currentProject.lastEntry)
	Dim extra As Map
	extra=segment.Get(4)
	If extra.ContainsKey("note") Then
		TextArea1.Text=extra.Get("note")
	End If
	frm.ShowAndWait
End Sub

Sub Button1_MouseClicked (EventData As MouseEvent)
	Dim extra As Map
	extra=segment.Get(4)
	extra.Put("note",TextArea1.Text)
	frm.Close
End Sub