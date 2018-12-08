B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private settings As Map
	Private applyButton As Button
	Private cancelButton As Button
	Private settingTabPane As TabPane
	Private AddTMButton As Button
	Private DeleteTMButton As Button
	Private TMListView As ListView
	Private resultList As List
	Private TermListView As ListView
	Private MatchRateLabel As Label
	Private MatchRateTextField As TextField
	Private quickFillListView As ListView
	Private IncludeTermCheckBox As CheckBox
	Private autocorrecCheckBox As CheckBox
	Private autocorrectListView As ListView
	Private serverAddressTextField As TextField
	Private sharingTermCheckBox As CheckBox
	Private sharingTMCheckBox As CheckBox
	Private enableGitCollaborationCheckBox As CheckBox
	Private updateWorkFileCheckBox As CheckBox
	Private GitURITextField As TextField
	Private setKeyButton As Button
	Private firstTime As Boolean=True
	Private SaveAndCommitCheckBox As CheckBox
	Private TermMatchAlgorithmComboBox As ComboBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("projectSetting")
	settings.Initialize
	settings=Main.currentProject.settings
	settingTabPane.LoadLayout("generalProjectSetting","General")
	settingTabPane.LoadLayout("tmSetting","TM")
	settingTabPane.LoadLayout("termSetting","Term")
	settingTabPane.LoadLayout("quickfillSetting","Quickfill")
	settingTabPane.LoadLayout("autocorrectSetting","Autocorrect")
	settingTabPane.LoadLayout("teamSetting","Team")


	loadGeneral
	loadTMandTermList
	loadQuickfill
	loadAutocorrect
	loadTeam
	resultList.Initialize
End Sub

Sub loadTMandTermList
	If settings.ContainsKey("tmList") Then
		TMListView.Items.AddAll(settings.Get("tmList"))
	End If
	If settings.ContainsKey("termList") Then
		TermListView.Items.AddAll(settings.Get("termList"))
	End If
End Sub

Sub loadGeneral
	TermMatchAlgorithmComboBox.Items.AddAll(Array As String("hashmap","iteration"))
	If settings.ContainsKey("termMatch_algorithm") Then
		Select settings.Get("termMatch_algorithm")
			Case "hashmap"
				TermMatchAlgorithmComboBox.SelectedIndex=0
			Case "iteration"
				TermMatchAlgorithmComboBox.SelectedIndex=1
		End Select
	Else
		TermMatchAlgorithmComboBox.SelectedIndex=1
	End If
	If settings.ContainsKey("matchrate") Then
		MatchRateTextField.Text=(settings.Get("matchrate"))
	End If
	SaveAndCommitCheckBox.checked=settings.GetDefault("save_and_commit",False)
End Sub

Sub loadQuickfill
	If settings.ContainsKey("quickfill_includeterm") Then
		IncludeTermCheckBox.Checked=settings.Get("quickfill_includeterm")
	End If
	If settings.ContainsKey("quickfill") Then
		Dim items As List
		items=settings.Get("quickfill")
		For Each item As String In items
			Dim tf As TextField
			tf.Initialize("tf")
			tf.PrefWidth=quickFillListView.Width
			tf.Text=item
			quickFillListView.Items.Add(tf)
		Next
	Else
		For Each item As String In Array As String("——","¥","©","®","™","『","』","","","")
			Dim tf As TextField
			tf.Initialize("tf")
			tf.PrefWidth=quickFillListView.Width
			tf.Text=item
			quickFillListView.Items.Add(tf)
		Next
	End If
End Sub


Sub loadAutocorrect
	If settings.ContainsKey("autocorrect_enabled") Then
		autocorrecCheckBox.Checked=settings.Get("autocorrect_enabled")
	End If
	If settings.ContainsKey("autocorrect") Then
		Dim items As List
		items=settings.Get("autocorrect")
		For Each item As List In items
			Dim p As Pane
			p.Initialize("")
			p.LoadLayout("autocorrectItem")
			p.PrefHeight=50
			Dim tf1,tf2 As TextField
			tf1=p.GetNode(0)
			tf2=p.GetNode(1)
			tf1.Text=item.Get(0)
			tf2.Text=item.Get(1)
			autocorrectListView.Items.Add(p)
		Next
	Else
		For i=0 To 10
			Dim p As Pane
			p.Initialize("")
			p.LoadLayout("autocorrectItem")
			autocorrectListView.Items.Add(p)
		Next
	End If
End Sub

Sub loadTeam
	If settings.ContainsKey("sharingTM_enabled") Then
		sharingTMCheckBox.Checked=settings.Get("sharingTM_enabled")
	End If
	If settings.ContainsKey("sharingTerm_enabled") Then
		sharingTermCheckBox.Checked=settings.Get("sharingTerm_enabled")
	End If
	If settings.ContainsKey("server_address") Then
		serverAddressTextField.Text=settings.Get("server_address")
	End If
	If settings.ContainsKey("git_enabled") Then
		enableGitCollaborationCheckBox.Checked=settings.Get("git_enabled")
	End If
	If settings.ContainsKey("updateWorkFile_enabled") Then
		updateWorkFileCheckBox.Checked=settings.Get("updateWorkFile_enabled")
	End If
	If File.Exists(Main.currentProject.path,".git") Then
		Dim uri As String=Main.currentProject.getGitRemote
		If uri<>"" Then
			GitURITextField.Text=uri
		End If
	End If
End Sub

Public Sub ShowAndWait As List
	frm.ShowAndWait
	Return resultList
End Sub

Sub settingTabPane_TabChanged (SelectedTab As TabPage)
	
End Sub

Sub frm_CloseRequest (EventData As Event)
	resultList.Add("canceled")
End Sub

Sub cancelButton_MouseClicked (EventData As MouseEvent)
	resultList.Add("canceled")
	frm.Close
End Sub

Sub applyButton_MouseClicked (EventData As MouseEvent)
	Dim num As Double
	num=MatchRateTextField.Text
	If num<0.5 Or num>1 Then
		fx.Msgbox(frm,"Matchrate cannot be below 0.5 or over 1.0","")
        Return
	End If
	Dim quickfillList As List
	quickfillList.Initialize
	For Each tf As TextField In quickFillListView.Items
		quickfillList.Add(tf.Text)
	Next
	Dim autocorrectList As List
	autocorrectList.Initialize
	For Each p As Pane In autocorrectListView.Items
		Dim tf1,tf2 As TextField
		tf1=p.GetNode(0)
		tf2=p.GetNode(1)
		Dim list1 As List
		list1.Initialize
		list1.Add(tf1.Text)
		list1.Add(tf2.Text)
		autocorrectList.Add(list1)
	Next
	
	Dim updateTM As String=askTM
	Dim updateTerm As String
	If updateTM<>"cancel" Then
		updateTerm=askTerm
	End If
	If updateTM="cancel" Or updateTerm="cancel" Then
		Return
	Else
		resultList.Add("changed")
		settings.Put("matchrate",num)
		settings.Put("save_and_commit",SaveAndCommitCheckBox.Checked)
		settings.Put("tmList",TMListView.Items)
		settings.Put("termList",TermListView.Items)
		settings.Put("quickfill",quickfillList)
		settings.Put("quickfill_includeterm",IncludeTermCheckBox.Checked)
		settings.Put("autocorrect",autocorrectList)
		settings.Put("autocorrect_enabled",autocorrecCheckBox.Checked)
		settings.put("tmListChanged",updateTM)
		settings.put("termListChanged",updateTerm)
		settings.Put("server_address",serverAddressTextField.Text)
		settings.Put("sharingTM_enabled",sharingTMCheckBox.Checked)
		settings.Put("sharingTerm_enabled",sharingTermCheckBox.Checked)
		settings.Put("git_enabled",enableGitCollaborationCheckBox.Checked)
		settings.Put("updateWorkFile_enabled",updateWorkFileCheckBox.Checked)
		Select TermMatchAlgorithmComboBox.SelectedIndex
			Case 0
				settings.Put("termMatch_algorithm","hashmap")
			Case 1
				settings.Put("termMatch_algorithm","iteration")
		End Select
		resultList.Add(settings)
	End If
	frm.Close
End Sub

Sub askTM As String
	If tmListChanged Then
		Dim result As Int=fx.Msgbox2(frm,"Will reset external tm db, continue?","","Continue","","Cancel",fx.MSGBOX_CONFIRMATION)
		If result=fx.DialogResponse.POSITIVE Then
			Return "yes"
		Else
			Return "cancel"
		End If
	Else
		Return "notchanged"
	End If
End Sub

Sub askTerm As String
	If termListChanged Then
		Dim result As Int=fx.Msgbox2(frm,"Will reset external term db, continue?","","Continue","","Cancel",fx.MSGBOX_CONFIRMATION)
		If result=fx.DialogResponse.POSITIVE Then
			Return "yes"
		Else
			Return "cancel"
		End If
	Else
		Return "notchanged"
	End If
End Sub

Sub tmListChanged As Boolean
	Dim tmList As List
	tmList=settings.Get("tmList")
	If tmList<>TMListView.Items Then
		Return True
	Else
		Return False
	End If
End Sub

Sub termListChanged As Boolean
	Dim termList As List
	termList=settings.Get("termList")
	If termList<>TermListView.Items Then
		Return True
	Else
		Return False
	End If
End Sub

Sub DeleteTMButton_MouseClicked (EventData As MouseEvent)
	If TMListView.SelectedIndex<>-1 Then
		TMListView.Items.RemoveAt(TMListView.SelectedIndex)
	End If
	
End Sub

Sub DeleteTermButton_MouseClicked (EventData As MouseEvent)
	If TermListView.SelectedIndex<>-1 Then
		TermListView.Items.RemoveAt(TermListView.SelectedIndex)
	End If
	
End Sub

Sub AddTermButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	
	Dim descriptionList,filterList As List
	descriptionList.Initialize
	filterList.Initialize

	descriptionList.Add("TAB-delimited Files")
	filterList.add("*.txt")
	descriptionList.Add("TBX Files")
	filterList.add("*.tbx")
	FileChooserUtils.AddExtensionFilters4(fc,descriptionList,filterList,False,"",True)
	Dim path As String
	path=fc.ShowOpen(frm)
	If path="" Then
		Return
	Else
		Dim filename As String
		filename=Main.getFilename(path)
		Dim thisImportDialog As importDialog
		thisImportDialog.Initialize
		If thisImportDialog.ShowAndWait(path,"term")=True Then
			Wait For (File.CopyAsync(path,"",File.Combine(Main.currentProject.path,"Term"), filename)) Complete (Success As Boolean)
			Log("Success: " & Success)
			TermListView.Items.Add(filename)
		End If
	End If
End Sub

Sub AddTMButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	
	Dim descriptionList,filterList As List
	descriptionList.Initialize
	filterList.Initialize

	descriptionList.Add("TAB-delimited Files")
	filterList.add("*.txt")
	descriptionList.Add("TMX Files")
	filterList.add("*.tmx")
	FileChooserUtils.AddExtensionFilters4(fc,descriptionList,filterList,False,"",True)
	Dim path As String
	path=fc.ShowOpen(frm)
	If path="" Then
		Return
	Else
		Dim filename As String
		filename=Main.getFilename(path)
		Dim thisImportDialog As importDialog
		thisImportDialog.Initialize
		If thisImportDialog.ShowAndWait(path,"tm")=True Then
			Wait For (File.CopyAsync(path,"",File.Combine(Main.currentProject.path,"TM"), filename)) Complete (Success As Boolean)
			Log("Success: " & Success)
			TMListView.Items.Add(filename)
		End If
	End If
End Sub



Sub MatchRateTextField_TextChanged (Old As String, New As String)
	If Regex.IsMatch("^([0-9]{1,}[.][0-9]*)$",New)=False Then
		fx.Msgbox(frm,"The text must be like *.*","")
		MatchRateTextField.Text=Old
		Return
	End If
End Sub


Sub enableGitCollaborationCheckBox_CheckedChange(Checked As Boolean)
	If Main.currentProject.settings.ContainsKey("git_enabled") And firstTime=True Then
		firstTime=False
		Return
	End If
	If Checked Then
		If sharingTMCheckBox.Checked=False Or updateWorkFileCheckBox.Checked=False Then
			fx.Msgbox(frm,"It is recommended to share TM and update workfile to avoid conflicts when using git. But you can continue with sharingTM disabled.","")
		End If
		Log(Main.currentProject.getGitRemote)
		Log(GitURITextField.Text)
		If Main.currentProject.getGitRemote="" And GitURITextField.Text="" Then
			
		    fx.Msgbox(frm,"Please set up a remote uri.","")
			enableGitCollaborationCheckBox.Checked=False
		End If
	End If

End Sub

Sub setRemoteButton_MouseClicked (EventData As MouseEvent)
	Main.currentProject.setGitRemoteAndPush(GitURITextField.Text)
	Sleep(2000)
	fx.Msgbox(frm,"Done","")
End Sub

Sub setKeyButton_MouseClicked (EventData As MouseEvent)
	Dim key As String
	If File.Exists(Main.currentProject.path,"accesskey") Then
		key=File.ReadString(Main.currentProject.path,"accesskey")
	End If
	Dim inp As InputBox
	inp.Initialize
	key=inp.showAndWait(key)
	If key<>"" Then
		File.WriteString(Main.currentProject.path,"accesskey",key)
	End If
End Sub