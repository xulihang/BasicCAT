B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.32
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private TextArea1 As TextArea
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",500,500)
	frm.RootPane.LoadLayout("ErrorReporter")
End Sub

Public Sub ShowAndWait(error As String)
	TextArea1.Text=error
    frm.ShowAndWait
End Sub

Sub ReportButton_MouseClicked (EventData As MouseEvent)
	fx.ShowExternalDocument("https://github.com/xulihang/BasicCAT/issues/new")
End Sub

Sub OkayButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub