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
	Private mtComboBox As ComboBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("pretranslate")
	result.Initialize
	mtComboBox.Items.AddAll(Array As String("baidu","yandex","youdao","google","microsoft"))
	mtComboBox.SelectedIndex=0
End Sub

Public Sub ShowAndWait As Map
	frm.ShowAndWait
	Return result
End Sub

Sub cancelButton_MouseClicked (EventData As MouseEvent)
	result.Put("type","")
	frm.Close
End Sub

Sub applyTMButton_MouseClicked (EventData As MouseEvent)
	result.Put("type","TM")
	result.Put("rate",rateTextField.Text)
	frm.Close
End Sub

Sub applyMTButton_MouseClicked (EventData As MouseEvent)
	Dim engine As String
	engine=mtComboBox.Items.Get(mtComboBox.SelectedIndex)
	If engine<>"" And Utils.getMap("mt",Main.preferencesMap).Get(engine&"_isEnabled")=True Then
		result.Put("engine",engine)
		result.Put("type","MT")
	Else
		fx.Msgbox(frm,"The engine is not enabled","")
		result.Put("type","")
	End If
	frm.Close
End Sub