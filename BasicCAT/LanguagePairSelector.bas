B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private result As Map
	Private sourceComboBox As ComboBox
	Private sourceTextField As TextField
	Private targetComboBox As ComboBox
	Private targetTextField As TextField
	Private langcodes As Map
	Private LanguageNames As Map
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",500,300)
	frm.RootPane.LoadLayout("LangaugePairSelector")
	result.Initialize
	LanguageNames.Initialize
	langcodes=Utils.readLanguageCode(File.Combine(File.DirData("BasicCAT"),"langcodes.txt"))
	fillComboBox
End Sub

Sub fillComboBox
	For Each key As String In langcodes.Keys
		Dim codesMap As Map
		codesMap=langcodes.Get(key)
		LanguageNames.Put(codesMap.Get("language name"),key)
		sourceComboBox.Items.Add(codesMap.Get("language name"))
		targetComboBox.Items.Add(codesMap.Get("language name"))
	Next
End Sub


Public Sub ShowAndWait As Map
	frm.ShowAndWait
	Return result
End Sub

Sub close
	frm.Close
End Sub

Sub targetComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	targetTextField.Text=LanguageNames.Get(Value)
End Sub

Sub sourceComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	sourceTextField.Text=LanguageNames.Get(Value)
End Sub

Sub OkButton_MouseClicked (EventData As MouseEvent)
	If sourceTextField.Text="" Or targetTextField.Text="" Then
		fx.Msgbox(frm,"Please choose language pair.","")
		Return
	End If
	result.put("source",sourceTextField.Text)
	result.put("target",targetTextField.Text)
	close
End Sub