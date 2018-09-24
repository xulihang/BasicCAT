B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private result As Map
	Private rateTextField As TextField
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("pretranslate")
	result.Initialize
End Sub

Public Sub ShowAndWait As Map
	frm.ShowAndWait
	Return result
End Sub

Sub cancelButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub

Sub applyTMButton_MouseClicked (EventData As MouseEvent)
	result.Put("type","TM")
	result.Put("rate",rateTextField.Text)
	frm.Close
End Sub

Sub applyMTButton_MouseClicked (EventData As MouseEvent)
	result.Put("type","MT")
	frm.Close
End Sub