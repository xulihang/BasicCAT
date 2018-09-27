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
	frm.Close
End Sub

Sub applyButton_MouseClicked (EventData As MouseEvent)
	preferencesMap.Put("mt",mtPreferences)
	Dim json As JSONGenerator
	json.Initialize(preferencesMap)
	File.WriteString(File.DirApp,"preferences.conf",json.ToString)
	frm.Close
End Sub

Sub categoryListView_SelectedIndexChanged(Index As Int)
	
	Log(Index)
	Select Index
		Case Index
			SettingPane.LoadLayout("mtSetting")
			loadMT
	End Select
End Sub

Sub mtTableView_MouseClicked (EventData As MouseEvent)
	If mtTableView.SelectedRowValues<>Null Then
		Log(mtTableView.SelectedRowValues(0))
		Dim engineName As String
		engineName=mtTableView.SelectedRowValues(0)
	    Select engineName
			Case "baidu"
                Dim filler As MTParamsFiller
				filler.Initialize("baidu",preferencesMap)
				mtPreferences.Put("baidu",filler.showAndWait)
				Log(mtPreferences)
				
		End Select
		preferencesMap.Put("mt",mtPreferences)
	End If
	
End Sub

Sub loadMT
	Dim chkbox As CheckBox
	chkbox.Initialize("chkbox")
	chkbox.Text=""
	chkbox.Tag="baidu"
	If mtPreferences.ContainsKey("baidu_isEnabled") Then
		chkbox.Checked=mtPreferences.Get("baidu_isEnabled")
	End If
	Dim Row() As Object = Array ("baidu", chkbox)
	mtTableView.Items.Add(Row)
End Sub

Sub chkbox_CheckedChange(Checked As Boolean)
	
	Dim chkbox As CheckBox
	chkbox=Sender
	Select chkbox.Tag
		Case "baidu"
			Dim params As Map
			Dim isfilled As Boolean=True
			If mtPreferences.ContainsKey("baidu") Then
				params=mtPreferences.Get("baidu")
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
				mtPreferences.Put("baidu_isEnabled",Checked)
			Else
				If Checked Then
					fx.Msgbox(frm,"参数未填写完整","")
				End If
				chkbox.Checked=False
				
			End If
				
	End Select
End Sub