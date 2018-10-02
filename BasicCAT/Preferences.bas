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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("preferences")
	preferencesMap.Initialize
	mtPreferences.Initialize
	initList
    If File.Exists(File.DirApp,"preferences.conf") Then
	    Dim json As JSONParser
		json.Initialize(File.ReadString(File.DirApp,"preferences.conf"))
		preferencesMap=json.NextObject
		If preferencesMap.ContainsKey("mt") Then
			mtPreferences=preferencesMap.Get("mt")
		End If
    End If
End Sub

Sub initList
	categoryListView.Items.AddAll(Array As String("Machine Translation"))
End Sub

Public Sub ShowAndWait
	frm.ShowAndWait
End Sub


Sub cancelButton_MouseClicked (EventData As MouseEvent)
	Log(Main.preferencesMap)
	frm.Close
End Sub

Sub applyButton_MouseClicked (EventData As MouseEvent)
	preferencesMap.Put("mt",mtPreferences)
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
			SettingPane.LoadLayout("mtSetting")
			loadMT
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

		preferencesMap.Put("mt",mtPreferences)
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