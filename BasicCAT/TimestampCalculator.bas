B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private TextField1 As TextField
	Private TextField2 As TextField
	Private TextField3 As TextField
	Private TextField4 As TextField
	Private TextField5 As TextField
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("timestamp")
End Sub

Public Sub Show
	frm.Show
End Sub

Sub Button1_MouseClicked (EventData As MouseEvent)
	Try
		TextField3.Text=DateTime.DateTimeParse(TextField1.Text,TextField2.Text)&","&DateTime.DateTimeParse(TextField4.Text,TextField5.Text)
	Catch
		Log(LastException)
		fx.Msgbox(frm,LastException.Message,"")
	End Try
End Sub