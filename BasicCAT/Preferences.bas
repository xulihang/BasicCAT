B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private applyButton As Button
	Private cancelButton As Button
	Private SettingPane As Pane
	Public preferencesMap As Map
	Private categoryListView As ListView
	Private mtTableView As TableView
	Private mtPreferences As Map

	Private ExternalTMCheckBox As CheckBox
	Private lookupCheckBox As CheckBox
    Private unsavedPreferences As Map
	Private autocompleteEnabledCheckBox As CheckBox
	Private corenlpAddressTextField As TextField
	Private corenlpPathTextField As TextField
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("preferences")
	preferencesMap.Initialize
	mtPreferences.Initialize
	unsavedPreferences.Initialize
	initList
    If File.Exists(File.DirApp,"preferences.conf") Then
	    Dim json As JSONParser
		json.Initialize(File.ReadString(File.DirApp,"preferences.conf"))
		preferencesMap=json.NextObject
		If preferencesMap.ContainsKey("mt") Then
			mtPreferences=preferencesMap.Get("mt")
		End If
    End If
	For Each key As String In preferencesMap.Keys
		unsavedPreferences.Put(key,preferencesMap.Get(key))
	Next
End Sub


Sub initList
	categoryListView.Items.AddAll(Array As String("General","Appearance","Machine Translation","Word Lookup","Autocomplete","Language Check","Version Control"))
End Sub

Public Sub ShowAndWait
	frm.ShowAndWait
End Sub


Sub cancelButton_MouseClicked (EventData As MouseEvent)
	Log(Main.preferencesMap)
	frm.Close
End Sub

Sub applyButton_MouseClicked (EventData As MouseEvent)
	For Each key As String In unsavedPreferences.Keys
		preferencesMap.Put(key,unsavedPreferences.get(key))
	Next
	Dim json As JSONGenerator
	json.Initialize(preferencesMap)
	File.WriteString(File.DirApp,"preferences.conf",json.ToString)
	Main.preferencesMap=preferencesMap
	frm.Close
End Sub

Sub categoryListView_SelectedIndexChanged(Index As Int)
	
	Log(Index)
	Select Index
		Case 0
			'general
			SettingPane.RemoveAllNodes
			SettingPane.LoadLayout("generalSetting")
			If unsavedPreferences.ContainsKey("checkExternalTMOnOpening") Then
				ExternalTMCheckBox.Checked=unsavedPreferences.get("checkExternalTMOnOpening")
			End If
		Case 1
			'appearance
			SettingPane.RemoveAllNodes
			SettingPane.LoadLayout("appearance")
		Case 2
			'mt
			SettingPane.RemoveAllNodes
			SettingPane.LoadLayout("mtSetting")
			loadMT
		Case 3
			'word lookup
			SettingPane.RemoveAllNodes
			SettingPane.LoadLayout("wordLookupSetting")
			If unsavedPreferences.ContainsKey("lookupWord") Then
				lookupCheckBox.Checked=unsavedPreferences.get("lookupWord")
			End If
		Case 4
			'autocomplete
			SettingPane.RemoveAllNodes
			SettingPane.LoadLayout("autocomplete")
			If unsavedPreferences.ContainsKey("autocompleteEnabled") Then
				autocompleteEnabledCheckBox.Checked=unsavedPreferences.get("autocompleteEnabled")
			End If
			If unsavedPreferences.ContainsKey("corenlp_address") Then
				corenlpAddressTextField.Text=unsavedPreferences.get("corenlp_address")
			End If
			If unsavedPreferences.ContainsKey("corenlp_path") Then
				corenlpPathTextField.Text=unsavedPreferences.get("corenlp_path")
			End If
		Case 5
			'Language Check
			
		Case 6
			'Version Control
			
	End Select
End Sub

Sub mtTableView_MouseClicked (EventData As MouseEvent)
	If mtTableView.SelectedRowValues<>Null Then
		Log(mtTableView.SelectedRowValues(0))
		Dim engineName As String
		engineName=mtTableView.SelectedRowValues(0)

        Dim filler As MTParamsFiller
		filler.Initialize(engineName,preferencesMap)
		mtPreferences.Put(engineName,filler.showAndWait)
		Log(mtPreferences)

		unsavedPreferences.Put("mt",mtPreferences)
	End If
	
End Sub

Sub loadMT
	For Each item As String In Array As String("baidu","yandex","youdao")
		Dim chkbox As CheckBox
		chkbox.Initialize("chkbox")
		chkbox.Text=""
		chkbox.Tag=item
		If mtPreferences.ContainsKey(item&"_isEnabled") Then
			chkbox.Checked=mtPreferences.Get(item&"_isEnabled")
		End If
		Dim Row() As Object = Array (item, chkbox)
		mtTableView.Items.Add(Row)
	Next

End Sub

Sub chkbox_CheckedChange(Checked As Boolean)
	
	Dim chkbox As CheckBox
	chkbox=Sender
	Dim engine As String
    engine=chkbox.Tag
	
	Dim params As Map
	Dim isfilled As Boolean=True
	
	If mtPreferences.ContainsKey(engine) Then
		params=mtPreferences.Get(engine)
		Log(params)
		If params.Size=0 Then
			isfilled=False
		End If
        For Each key As String In params.Keys
			Log(params.Get(key))
			If params.Get(key)="" Then
				isfilled=False
			End If
        Next
	Else
		isfilled=False
	End If
	
	If isfilled=True Then
		mtPreferences.Put(engine&"_isEnabled",Checked)
	Else
		If Checked Then
			fx.Msgbox(frm,"params are not filled completely","")
		End If
		chkbox.Checked=False
		
	End If
End Sub


Sub lookupCheckBox_CheckedChange(Checked As Boolean)
	unsavedPreferences.Put("lookupWord",Checked)
End Sub

Sub ExternalTMCheckBox_CheckedChange(Checked As Boolean)
	unsavedPreferences.Put("checkExternalTMOnOpening",Checked)
End Sub

Sub autocompleteEnabledCheckBox_CheckedChange(Checked As Boolean)
	unsavedPreferences.Put("autocompleteEnabled",Checked)
End Sub

Sub saveAddressButton_MouseClicked (EventData As MouseEvent)
	unsavedPreferences.Put("corenlp_address",corenlpAddressTextField.Text)
	unsavedPreferences.Put("corenlp_path",corenlpPathTextField.Text)
End Sub