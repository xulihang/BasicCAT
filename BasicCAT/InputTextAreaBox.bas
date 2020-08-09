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
	If TextArea1.Text<>"" And TextArea1.Text<>extra.Get("note") Then
		Dim extra As Map
		extra=segment.Get(4)
		extra.Put("note",TextArea1.Text)
		Main.currentProject.contentIsChanged
		Dim p As Pane=Main.editorLV.Items.Get(Main.currentProject.lastEntry)
		If p.NumberOfNodes<>0 Then
			Dim ta As RichTextArea=p.GetNode(1).Tag
			ta.DefaultBorderColor=fx.Colors.RGB(0,128,0)
		End If
	Else if TextArea1.Text="" Then
		Dim extra As Map
		extra=segment.Get(4)
		extra.Remove("note")
		Main.currentProject.contentIsChanged
		Dim p As Pane=Main.editorLV.Items.Get(Main.currentProject.lastEntry)
		If p.NumberOfNodes<>0 Then
			Dim ta As RichTextArea=p.GetNode(1).Tag
			ta.resetBorderColor
		End If
	End If
	frm.Close
End Sub