B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private fullSourceTextArea As TextArea
	Private sourceTextArea As TextArea
	Private result As Map
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(source As String,fullsource As String)
	frm.Initialize("frm",600,400)
	frm.RootPane.LoadLayout("SourceEditor")
	result.Initialize
	result.Put("source",source)
	result.Put("fullsource",fullsource)
	sourceTextArea.Text=source
	fullSourceTextArea.Text=fullsource
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	saveAndClose
End Sub

Public Sub ShowAndWait As Map
	frm.ShowAndWait
	Return result
End Sub

Sub saveAndClose
	If fullSourceTextArea.Text.Contains(sourceTextArea.Text)=False Then
		fx.Msgbox(frm,"The full source text should contain the source text.","")
	Else
		result.Put("source",sourceTextArea.Text)
		result.Put("fullsource",fullSourceTextArea.Text)
		frm.Close
	End If
End Sub