B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
#RaisesSynchronousEvents: SubThatCanRaiseEvent
Sub Class_Globals
	Private fx As JFX
	Public path As String
	Public files As List
	Public projectFile As Map
	Public currentFilename As String
	Public segments As List
	Public projectTM As TM
	Public projectTerm As Term
	Public lastEntry As Int
	Private previousEntry As Int
	Private lastFilename As String
	Public settings As Map
	Public completed As Int
	Private cmClicked As Boolean=False
	Private cm As ContextMenu
	Private cursorReachEnd As Boolean=False
	Private projectGit As git
	Public contentChanged As Boolean=False
	
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	files.Initialize
	projectFile.Initialize
	segments.Initialize
	settings.Initialize
	cm.Initialize("cm")

End Sub


Sub initializeTM(projectPath As String,isExistingProject As Boolean)
	projectTM.Initialize(projectPath)
	Dim externalTMList As List
	externalTMList=settings.Get("tmList")
	Log(externalTMList.Size)
	For i=0 To externalTMList.Size-1
		Dim filename As String
		filename=externalTMList.Get(i)
		If File.Exists(File.Combine(Main.currentProject.path,"TM"),filename)=False Then
			fx.Msgbox(Main.MainForm,filename&" does not exist. Will be deleted.","")
            externalTMList.RemoveAt(i)
			settings.Put("tmList",externalTMList)
			save
		End If
	Next
	If isExistingProject Then
		If Main.preferencesMap.ContainsKey("checkExternalTMOnOpening") Then
			If Main.preferencesMap.Get("checkExternalTMOnOpening")=False Then
			    Return
			End If
		End If
	End If

	projectTM.importExternalTranslationMemory(externalTMList)
	'runTMBackend
End Sub

Sub initializeTerm(projectPath As String)
	projectTerm.Initialize(projectPath,projectFile.Get("source"))
End Sub



Public Sub open(jsonPath As String)
	Main.addProjectTreeTableItem
	path=getProjectPath(jsonPath)
	Dim json As JSONParser
	json.Initialize(File.ReadString(jsonPath,""))
	projectFile=json.NextObject
	lastEntry=projectFile.Get("lastEntry")
	lastFilename=projectFile.Get("lastFile")
	settings=projectFile.Get("settings")
	files.AddAll(projectFile.Get("files"))
	For Each filepath As String In files
		addFilesToTreeTable(filepath)
	Next
	initializeTM(path,True)
	initializeTerm(path)
	Main.initializeNLP(projectFile.Get("source"))
	'jumpToLastEntry
End Sub

Sub jumpToLastEntry
	If projectFile.Get("lastFile")="" Then
		Return
	End If
	openFile(projectFile.Get("lastFile"),True)
End Sub

Public Sub newProjectSetting(source As String,target As String)
	projectFile.Put("source",source)
	projectFile.Put("target",target)
	Main.initializeNLP(source)
	Dim tmList As List
	tmList.Initialize
	Dim termList As List
	termList.Initialize
	settings.Put("tmList",tmList)
	settings.Put("termList",termList)
End Sub

Public Sub addFile(filepath As String)
	Dim filename As String
	filename=Main.getFilename(filepath)
	Log("fp"&filepath)
	Log("fn"&filename)
	Wait For (File.CopyAsync(filepath,"",File.Combine(path,"source"),filename)) Complete (Success As Boolean)
	Log("Success: " & Success)
	files.Add(filename)
	addFilesToTreeTable(filename)
	createWorkFileAccordingToExtension(filename)
	save
End Sub


Public Sub saveSettings(newsettings As Map)
	projectFile.Put("settings",newsettings)
	Log(newsettings)
	save
	projectTM.deleteExternalTranslationMemory
	wait for (projectTM.importExternalTranslationMemory(settings.Get("tmList"))) complete (result As Boolean)
	projectTerm.deleteExternalTerminology
	projectTerm.importExternalTerminology(settings.Get("termList"))
End Sub

public Sub save
	If File.Exists(path,"")=False Then
		createProjectFiles
	End If
	If projectTM.IsInitialized=False Then
		initializeTM(path,False)
	End If
	If projectTerm.IsInitialized=False Then
		initializeTerm(path)
	End If
	showPreView
	projectFile.Put("files",files)
	projectFile.Put("lastFile",lastFilename)
	projectFile.Put("lastEntry",lastEntry)
	projectFile.Put("settings",settings)
	Dim json As JSONGenerator
	json.Initialize(projectFile)
	File.WriteString(path,"project.bcp",json.ToPrettyString(4))
	
	If contentChanged Then
		saveFile(currentFilename)
		If Main.preferencesMap.ContainsKey("vcsEnabled") Then
			If Main.preferencesMap.Get("vcsEnabled")=True Then
				gitcommit
			End If
		End If
		
	End If
	
	

	
	Main.updateSavedTime
End Sub

Sub gitcommit
	createGitignore
	If projectGit.IsInitialized=False Then
		projectGit.Initialize(path)
	End If
	Dim username,email As String
	If Main.preferencesMap.ContainsKey("vcs_email") Then
		email=Main.preferencesMap.Get("vcs_email")
	End If
	If Main.preferencesMap.ContainsKey("vcs_username") Then
		username=Main.preferencesMap.Get("vcs_username")
	End If
	Dim diffList As List
	diffList=projectGit.diffList
	If diffList<>Null And diffList.Size<>0 Then
		projectGit.add(".")
		projectGit.commit("new text change",username,email)
	End If
End Sub

Sub createGitignore
	If File.Exists(path,".gitignore")=False Then
		File.Copy(File.DirAssets,".gitignore",path,".gitignore")
	End If
End Sub

Sub showPreView
	If Main.pre.IsInitialized And Main.pre.isShowing Then
		Main.pre.loadText
	End If
End Sub

Sub createProjectFiles
	File.MakeDir(path,"")
	File.MakeDir(path,"source")
	File.MakeDir(path,"work")
	File.MakeDir(path,"target")
	File.MakeDir(path,"TM")
	File.MakeDir(path,"Term")
	File.MakeDir(path,"bak")
	File.Copy(File.DirAssets,"default_rules.srx",path,"segmentationRules.srx")
End Sub




Sub getProjectPath(jsonPath As String) As String
	Dim ProjectPath As String
	Try
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("\"))
	Catch
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("/"))
		Log(LastException)
	End Try
	Return ProjectPath
End Sub

Sub lbl_MouseClicked (EventData As MouseEvent)
	If EventData.PrimaryButtonPressed Then
		Dim lbl As Label
		lbl=Sender
		Log("file changed"&lbl.Text)
		Dim filename As String
		filename=lbl.text
		If currentFilename<>filename Then
			openFile(filename,False)
		End If
	End If
End Sub


Sub exportReviewMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	Dim rows As List
	rows.Initialize
	For Each bitext As List In getAllSegments(filename)
		Dim target As String=bitext.Get(1)
		Dim extra As Map
		extra=bitext.Get(4)
		If extra.ContainsKey("note") Then
			target=target&"  --------note: "&extra.Get("note")
		End If
		rows.Add(Array As String(bitext.Get(0),target))
	Next
	Dim poiw As POIWord
	poiw.Initialize("","write")
	poiw.createTable(rows,File.Combine(path,filename&".docx"))
	fx.Msgbox(Main.MainForm,"Done. File has been exported to the project folder.","")
End Sub

Sub exportBiParagraphMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	If currentFilename<>filename Then
		fx.Msgbox(Main.MainForm,"Please first open this file.","")
		Return
	End If
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("TXT",Array As String("*.txt"))
	Utils.exportToBiParagraph(segments,fc.ShowSave(Main.MainForm))
	fx.Msgbox(Main.MainForm,"Done.","")
End Sub

Sub importReviewMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	If currentFilename<>filename Then
		fx.Msgbox(Main.MainForm,"Please first open this file.","")
		Return
	End If
	Dim rows As List
	Dim reviewFilePath As String
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("Word Files",Array As String("*.docx"))
	reviewFilePath=fc.ShowOpen(Main.MainForm)
	If reviewFilePath<>"" Then
		Dim poiw As POIWord
		poiw.Initialize(reviewFilePath,"read")
		rows=poiw.readTable
		Dim crDialog As confirmReviewDialog
		crDialog.Initialize(rows,segments)
		crDialog.ShowAndWait
	End If

End Sub

Sub removeFileMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim tti As TreeTableItem
	Dim subTreeTableItem As TreeTableItem
	subTreeTableItem=Main.projectTreeTableView.Root.Children.Get(0)
	tti=mi.Tag
	Dim lbl As Label
	lbl=tti.GetValue(0)
	Dim filename As String
	filename=lbl.Text
	Dim result As Int
	result=fx.Msgbox2(Main.MainForm,"Remove corresponding translation memories?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
	Log(result)
	'yes -1, no -2, cancel -3
	If result=-3 Then
		Return
	End If 
	If currentFilename=filename Then
		Main.editorLV.Clear
		segments.Clear
		currentFilename=""
	End If
	If result=-1 Then
		For Each bitext As List In getAllSegments(filename)
			projectTM.translationMemory.Remove(bitext.Get(0))
		Next
	End If

	subTreeTableItem.Children.RemoveAt(subTreeTableItem.Children.IndexOf(mi.Tag))
	files.RemoveAt(files.IndexOf(filename))
	File.Delete(File.Combine(path,"source"),filename)
	File.Delete(File.Combine(path,"work"),filename&".json")
	save
	fx.Msgbox(Main.MainForm,"Done","")
End Sub

Sub openFile(filename As String,onOpeningProject As Boolean)
	If onOpeningProject=False Then
		save
	End If
	If File.Exists(File.Combine(path,"work"),filename&".json")=False Then
	    fx.Msgbox(Main.MainForm,"The workfile does not exist."&CRLF&"Maybe it's still in building.","")
		Return
	End If
	Main.editorLV.Clear
	Main.tmTableView.Items.Clear
	Main.LogWebView.LoadHtml("")
	Main.searchTableView.Items.Clear
	segments.Clear
	currentFilename=filename

	readWorkFile(currentFilename)

	Log("currentFilename:"&currentFilename)
	If lastFilename=currentFilename Then
		Log("ddd"&True)
		Log(lastEntry)
		Main.editorLV.JumpToItem(lastEntry)
		fillPane(Main.editorLV.FirstVisibleIndex,Main.editorLV.LastVisibleIndex)
		'Wait For(fillPaneAsync(lastEntry,lastEntry+10)) Complete (Result As Object)
		'Dim pane As Pane
		'pane=Main.editorLV.GetPanel(lastEntry)
		'Dim ta As TextArea
		'ta=pane.GetNode(1)
		'ta.RequestFocus
		
	End If
End Sub

Sub addFilesToTreeTable(filename As String)
	Dim subTreeTableItem As TreeTableItem
	subTreeTableItem=Main.projectTreeTableView.Root.Children.Get(0)
	Dim tti As TreeTableItem
	Dim lbl As Label
	lbl.Initialize("lbl")
	lbl.Text=filename
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim mi As MenuItem
	mi.Initialize("Remove","removeFileMi")
	Dim mi2 As MenuItem
	mi2.Initialize("Export to docx for review","exportReviewMi")
	Dim mi3 As MenuItem
	mi3.Initialize("Import from review","importReviewMi")
	Dim mi4 As MenuItem
	mi4.Initialize("Export to bi-paragraphs","exportBiParagraphMi")
	cm.MenuItems.Add(mi)
	cm.MenuItems.Add(mi2)
	cm.MenuItems.Add(mi3)
	cm.MenuItems.Add(mi4)

	lbl.ContextMenu=cm
	
	tti.Initialize("tti",Array As Object(lbl))
	mi.Tag=tti
	mi2.Tag=filename
	mi3.Tag=filename
	mi4.Tag=filename
	subTreeTableItem.Children.Add(tti)
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	If Old<>New  Then
		If Old="" And New.Length<=1 Then
			contentIsChanged
		End If
		If Old<>"" Then
			contentIsChanged
		End If
	End If
	
	Log(Old)
	Log(New)
	If Old="" And New.Length>1 Then
		Return
	End If
	If New.Contains(CRLF) Or Old.Contains(CRLF) Then
		Return
	End If
	Dim ta As TextArea
	ta=Sender
	
	Old=Old.SubString2(0,Min(ta.SelectionStart,Old.Length))
	New=New.SubString2(0,Min(ta.SelectionStart,New.Length))
	Dim lastString As String
	If New.Length>1 Then
		lastString=New.CharAt(New.Length-1)
	Else
		lastString=New
	End If
	If projectFile.Get("target")="zh" Then
		Old=Regex.Replace("[a-zA-Z]|[^\u4e00-\u9fa5]",Old,"")
		New=Regex.Replace("[a-zA-Z]|[^\u4e00-\u9fa5]",New,"")
		If New.Length>Old.Length Then
			lastString=New.Replace(Old,"")
		End If
	else if projectFile.Get("target")="en" Then
		Dim wordList As List
		wordList.Initialize
		wordList.AddAll(Regex.Split(" ",New))
		If wordList.Size<>0 Then
			lastString=wordList.Get(wordList.Size-1)
		End If
	End If
	'Log("old"&Old)
	'Log("last"&lastString)




	If cmClicked=True Then
		cmClicked=False
	Else
		If Utils.isList(ta.Tag) Then
			cm.MenuItems.Clear
			Sleep(0)
			Dim segmentsList As List
			segmentsList=ta.Tag
			For Each text As String In segmentsList
				If text.ToLowerCase.StartsWith(lastString.ToLowerCase) And text<>lastString Then
					If text.StartsWith(lastString) Then
						Dim mi As MenuItem
						mi.Initialize(text, "mi")
						mi.Tag=lastString
						cm.MenuItems.Add(mi)
					Else
						Dim mi As MenuItem
						mi.Initialize(text.ToLowerCase, "mi")
						mi.Tag=lastString
						cm.MenuItems.Add(mi)
					End If

				End If
			Next
			If cm.MenuItems.Size<>0 Then
				Dim map1 As Map
				map1=Utils.GetScreenPosition(ta)
				Log(map1)
				Dim jo As JavaObject = cm
				jo.RunMethod("show", Array(ta, map1.Get("x")+ta.Width/10, map1.Get("y")+ta.Height))
			End If
		End If
	End If
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub segmentPane_MouseClicked (EventData As MouseEvent)
	lastEntry=Main.editorLV.GetItemFromView(Sender)
	Log(lastEntry)
End Sub

Public Sub createSegmentPane(bitext As List)
	Dim extra As Map
	extra=bitext.Get(4)
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	addTextAreaToSegmentPane(segmentPane,bitext.Get(0),bitext.Get(1))
	Main.editorLV.Add(segmentPane,"")
	If extra.ContainsKey("translate") Then
		If extra.Get("translate")="no" Then
			Utils.disableTextArea(segmentPane)
		End If
	End If
	If extra.ContainsKey("note") Then
		If extra.Get("note")<>"" Then
			CSSUtils.SetStyleProperty(segmentPane.GetNode(1),"-fx-background-color","green")
		End If
	End If
End Sub

Public Sub createEmptyPane(bitext As List)

	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	Main.editorLV.Add(segmentPane,"")

End Sub

Public Sub addTextAreaToSegmentPane(segmentpane As Pane,source As String,target As String)
	segmentpane.LoadLayout("segment")
	segmentpane.SetSize(Main.editorLV.AsView.Width,50dip)
	Dim sourceTextArea As TextArea
	sourceTextArea=segmentpane.GetNode(0)
	sourceTextArea.Text=source

	'sourceTextArea.Style = "-fx-font-family: Tahoma;"
	Main.setTextAreaFont(sourceTextArea,"sourceFont")
	addKeyEvent(sourceTextArea,"sourceTextArea")
	addSelectionChangedEvent(sourceTextArea,"sourceTextAreaSelection")
	Dim targetTextArea As TextArea
	targetTextArea=segmentpane.GetNode(1)
	targetTextArea.Text=target


	'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
	Main.setTextAreaFont(targetTextArea,"targetFont")
	addKeyEvent(targetTextArea,"targetTextArea")
	addSelectionChangedEvent(targetTextArea,"targetTextAreaSelection")
	
	sourceTextArea.Left=5dip
	sourceTextArea.SetSize(Main.editorLV.AsView.Width/2-15dip,50dip)
	targetTextArea.Left=targetTextArea.Left+targetTextArea.Width
	targetTextArea.SetSize(Main.editorLV.AsView.Width/2-15dip,50dip)
End Sub

Sub addKeyEvent(textarea1 As TextArea,eventName As String)
	Dim CJO As JavaObject = textarea1
	Dim O As Object = CJO.CreateEventFromUI("javafx.event.EventHandler",eventName&"_KeyPressed",Null)
	CJO.RunMethod("setOnKeyPressed",Array(O))
	CJO.RunMethod("setFocusTraversable",Array(True))
End Sub

Sub addSelectionChangedEvent(textarea1 As TextArea,eventName As String)
	Dim Obj As Reflector
	Obj.Target = textarea1
	Obj.AddChangeListener(eventName, "selectionProperty")
	
End Sub

Sub sourceTextAreaSelection_changed(old As Object, new As Object)

	Dim ta As TextArea
	ta=Sender
	onSelectionChanged(new,ta,True)
End Sub

Sub targetTextAreaSelection_changed(old As Object, new As Object)
	cursorReachEnd=False
    Log(old)
	Log(new)
	Dim ta As TextArea
	ta=Sender
    onSelectionChanged(new,ta,False)

End Sub

Sub onSelectionChanged(new As Object,ta As TextArea,isSource As Boolean)
	
	Dim indexString As String
	indexString=new
	Dim selectionStart,selectionEnd As Int
	selectionStart=Regex.Split(",",indexString)(0)
	selectionEnd=Regex.Split(",",indexString)(1)
	Dim selectedText As String
	If selectionEnd<>selectionStart Then
		selectedText=ta.Text.SubString2(selectionStart,selectionEnd)
		If isSource Then
		    Main.sourceTermTextField.Text=selectedText
		Else
			Main.targetTermTextField1.Text=selectedText
		End If
	Else
		Return
	End If
	'---------------------- add term
	
	Dim index As Int
	If isSource Then
		index=0
		If cmClicked=True Then
			cmClicked=False
		Else
			cm.MenuItems.Clear
			wait for (getMeans(selectedText)) complete (result As List)
			For Each text As String In result
				Dim mi As MenuItem
				mi.Initialize(text, "mi")
				cm.MenuItems.Add(mi)
			Next
			Sleep(100)
			Dim jo As JavaObject = cm
			jo.RunMethod("show", Array(ta, Main.getLeft, Main.getTop))
		End If
		
	Else
		index=1
	End If
	'------------------ show word meaning
	If Main.TabPane1.SelectedIndex=1 Then
		
		If projectFile.Get("source")="en" And isSource=True Then
			If selectionEnd<>ta.Text.Length Then
				Dim lastChar As String
				lastChar=ta.Text.SubString2(selectionEnd,Min(ta.Text.Length,selectionEnd+1))
				If Regex.IsMatch("\s|,|\.|\!|\?|"&Chr(34),lastChar)=False Then
					Return
				End If
			End If
		End If
		If projectFile.Get("target")="en" And isSource=False Then
			If selectionEnd<>ta.Text.Length Then
				Dim lastChar As String
				lastChar=ta.Text.SubString2(selectionEnd,Min(ta.Text.Length,selectionEnd+1))
				If Regex.IsMatch("\s|,|\.|\!|\?|"&Chr(34),lastChar)=False Then
					Return
				End If
			End If
		End If
		
		Main.searchTableView.Items.Clear
		Main.searchTableView.Tag=selectedText
		Dim result As List
		result.Initialize
		
		For i=0 To segments.Size-1
			Dim segment1 As List
			segment1=segments.Get(i) 
			Dim newsegment As List 'avoid affecting segments
			newsegment.Initialize
			newsegment.AddAll(segment1)
			Dim content As String
			content=newsegment.Get(index)
			newsegment.Add(i)
			If content.Contains(selectedText) And content<>ta.Text Then
				result.Add(newsegment)
			End If
		Next
		For Each segment As List In result
			Dim row()  As Object = Array As String(segment.Get(4),segment.Get(0),segment.Get(1))
			Main.searchTableView.Items.Add(row)
		Next
		Main.changeWhenSegmentOrSelectionChanges
	End If
	'---------- show segment search
End Sub

Sub mi_Action
	cmClicked=True
	Dim mi As MenuItem
	mi=Sender
	Dim p As Pane
	p=Main.editorLV.GetPanel(lastEntry)
	Dim targetTextArea As TextArea
	targetTextArea=p.GetNode(1)
	targetTextArea.Text=targetTextArea.Text.SubString2(0,targetTextArea.SelectionStart)&mi.Text.Replace(mi.Tag,"")&targetTextArea.Text.SubString2(targetTextArea.SelectionStart,targetTextArea.Text.Length)
	Sleep(0)
	targetTextArea.SetSelection(targetTextArea.Text.Length,targetTextArea.Text.Length)
End Sub

Sub sourceTextArea_MouseClicked (EventData As MouseEvent)

	Dim ta As TextArea
	ta=Sender
	lastEntry=Main.editorLV.GetItemFromView(ta.Parent)
	If ta.SelectionEnd=ta.SelectionStart Then
		Dim jo As JavaObject = cm
		jo.RunMethod("hide", Null)
	End If
End Sub


Sub sourceTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim sourceTextArea As TextArea
	sourceTextArea=Sender

	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	Log(result)
    If result="ENTER" Then
		contentIsChanged
		If currentFilename.EndsWith(".txt") Then
			txtFilter.splitSegment(sourceTextArea)
		Else if currentFilename.EndsWith(".idml") Then
			idmlFilter.splitSegment(sourceTextArea)
		Else if currentFilename.EndsWith(".xlf") Then
			xliffFilter.splitSegment(sourceTextArea)
		Else
			Dim params As Map
			params.Initialize
			params.Put("main",Main)
			params.Put("sourceTextArea",sourceTextArea)
			params.Put("editorLV",Main.editorLV)
			params.Put("segments",segments)
			params.Put("projectFile",projectFile)
			runFilterPluginAccordingToExtension(currentFilename,"splitSegment",params)
		End If
	Else if result="DELETE" Then
		contentIsChanged
		If currentFilename.EndsWith(".txt") Then
			txtFilter.mergeSegment(sourceTextArea)
		Else if currentFilename.EndsWith(".idml") Then
			idmlFilter.mergeSegment(sourceTextArea)
		Else if currentFilename.EndsWith(".xlf") Then
			xliffFilter.mergeSegment(sourceTextArea)
		Else
			Dim params As Map
			params.Initialize
			params.Put("MainForm",Main.MainForm)
			params.Put("sourceTextArea",sourceTextArea)
			params.Put("editorLV",Main.editorLV)
			params.Put("segments",segments)
			params.Put("projectFile",projectFile)
			runFilterPluginAccordingToExtension(currentFilename,"mergeSegment",params)
		End If
	End If
End Sub

Sub targetTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	Log(result)
	Dim targetTextArea As TextArea
	targetTextArea=Sender
	If result="ENTER" Then
		changeSegment(1,targetTextArea)
	Else if result="DOWN" Then
		If 	cursorReachEnd=False Then
			cursorReachEnd=True
		Else
			changeSegment(1,targetTextArea)
		End If
	Else if result="UP" Then
		If 	cursorReachEnd=False Then
			cursorReachEnd=True
		Else
			changeSegment(-1,targetTextArea)
		End If
	End If
End Sub

Sub changeSegment(offset As Int,targetTextArea As TextArea)
	Try
		targetTextArea.Text=targetTextArea.Text.Replace(CRLF,"")
		saveTranslation(targetTextArea)
		Dim pane As Pane
		pane=targetTextArea.Parent
		Dim index As Int
		index=Main.editorLV.GetItemFromView(pane)
		If index+offset>=Main.editorLV.Size Or index+offset<0 Then
			Return
		End If
		Dim nextPane As Pane
		nextPane=Main.editorLV.GetPanel(index+offset)
		Dim nextTA As TextArea
		nextTA=nextPane.GetNode(1)
		nextTA.RequestFocus
		lastEntry=Main.editorLV.GetItemFromView(nextPane)
		lastFilename=currentFilename
		showTM(nextTA)
		showTerm(nextTA)
		Main.updateSegmentLabel(lastEntry,segments.Size)
		If index+offset<Main.editorLV.FirstVisibleIndex+1 Or index+offset>Main.editorLV.LastVisibleIndex-1 Then
			If offset<0 Then
				Main.editorLV.ScrollToItem(index+offset)
			Else
				Main.editorLV.ScrollToItem(index+offset-Main.editorLV.LastVisibleIndex+Main.editorLV.FirstVisibleIndex+1)
			End If
		End If
	Catch
		Log(LastException)
	End Try
	showPreView
End Sub

Sub sourceTextArea_FocusChanged (HasFocus As Boolean)
	Log(HasFocus)
	Dim TextArea1 As TextArea
	TextArea1=Sender
	If HasFocus Then
		TextArea1.Tag=TextArea1.Text
		TextArea1.Editable=True
	Else
		TextArea1.Text=TextArea1.Tag
		TextArea1.Editable=False
	End If
End Sub

Sub targetTextArea_FocusChanged (HasFocus As Boolean)
	Dim TextArea1 As TextArea
	TextArea1=Sender
	If TextArea1.IsInitialized=False Then
		Log("Null,Textarea")
		Return
	End If
	If TextArea1.Parent.IsInitialized=False Then
		Log("Null,Textarea Parent")
		Return
	End If
	lastEntry=Main.editorLV.GetItemFromView(TextArea1.Parent)
	lastFilename=currentFilename
	If HasFocus Then
        Log("hasFocus")
		showTM(TextArea1)
		showTerm(TextArea1)
		Main.updateSegmentLabel(Main.editorLV.GetItemFromView(TextArea1.Parent),segments.Size)
	Else
		Log("loseFocus")
		previousEntry=lastEntry
		If Main.preferencesMap.ContainsKey("languagetoolEnabled") Then
			If Main.preferencesMap.Get("languagetoolEnabled")=True Then
				wait for (LanguageTool.check(TextArea1.Text,lastEntry,projectFile.Get("target"))) complete (result As List)
				showReplacements(result,TextArea1)
			End If
		End If

	End If
End Sub

Sub showReplacements(values As List,ta As TextArea)
	If values.Size=0 Then
		Return
	End If
	Dim replacementsCM As ContextMenu
	replacementsCM.Initialize("replacementsCM")
	Dim replacements As List
	replacements=values.Get(2)
	For Each replace As Map In replacements
		Dim mi As MenuItem
		mi.Initialize(replace.Get("value"), "replacementMi")
		Dim tagList As List
		tagList=values
		tagList.set(2,replace.Get("value"))
		mi.Tag=tagList
		replacementsCM.MenuItems.Add(mi)
	Next
	Sleep(100)
	Dim map1 As Map
	map1=Utils.GetScreenPosition(ta)
	Log(map1)
	Dim jo As JavaObject = replacementsCM
	jo.RunMethod("show", Array(ta, map1.Get("x")+ta.Width/10, map1.Get("y")+ta.Height))
End Sub

Sub replacementMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim tagList As List
	tagList=mi.Tag
	Dim offset,length As Int
	offset=tagList.Get(0)
	length=tagList.Get(1)
	Dim replacement As String
	replacement=tagList.Get(2)
	Dim p As Pane
	p=Main.editorLV.GetPanel(previousEntry)
	Dim targetTextArea As TextArea
	targetTextArea=p.GetNode(1)
	targetTextArea.Text=targetTextArea.Text.SubString2(0,offset)&replacement&targetTextArea.Text.SubString2(offset+length,targetTextArea.Text.Length)
	Sleep(0)
	targetTextArea.SetSelection(targetTextArea.Text.Length,targetTextArea.Text.Length)
End Sub

Sub loadITPSegments(targetTextArea As TextArea,engine As String,fullTranslation As String)
	If Main.preferencesMap.ContainsKey("autocompleteEnabled") Then
		If Main.preferencesMap.Get("autocompleteEnabled")=False Then
			Return
		End If
	Else
		Return
	End If
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	wait for (ITP.getAllSegmentTranslation(sourceTA.Text,engine)) Complete (Result As List)
	Result.Add(fullTranslation)
	If Utils.isList(targetTextArea.Tag) Then
		Dim list1 As List
		list1=targetTextArea.Tag
		list1.AddAll(Result)
		targetTextArea.Tag=ITP.duplicatedRemovedList(list1)
	Else
		targetTextArea.Tag=Result
	End If
End Sub

Sub showTM(targetTextArea As TextArea)
	Dim time As Long
	time=DateTime.Now
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Dim targetTA As TextArea
	targetTA=pane.GetNode(1)
	Log(sourceTA.Text)
	If projectTM.currentSource=sourceTA.Text Then
		Return
	End If
	Main.tmTableView.Items.Clear
	Main.LogWebView.LoadHtml("")
	projectTM.currentSource=sourceTA.Text
	Dim senderFilter As Object = projectTM.getMatchList(sourceTA.Text)
	Wait For (senderFilter) Complete (Result As List)


	For Each matchList As List In Result

		If matchList.Get(1)=sourceTA.Text And matchList.Get(3)="" And targetTA.Text=matchList.Get(2) Then
			Continue 'itself
		End If
		Dim row()  As Object = Array As String(matchList.Get(0),matchList.Get(1),matchList.Get(2),matchList.Get(3))
		Main.tmTableView.Items.Add(row)
	Next
	Log(DateTime.Now-time)
	
	showMT(sourceTA.Text,targetTextArea)
	
	Main.changeWhenSegmentOrSelectionChanges
	If Main.tmTableView.Items.Size<>0 Then
		Main.tmTableView.SelectedRow=0
	End If
End Sub

Sub showMT(source As String,targetTextArea As TextArea)
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return
	End If
	For Each engine As String In MT.getMTList
		If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
			wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),engine)) Complete (Result As String)
			If Result<>"" Then
				Dim row()  As Object = Array As String("","",Result,engine)
				Main.tmTableView.Items.InsertAt(Min(Main.tmTableView.Items.Size,1),row)
				Main.changeWhenSegmentOrSelectionChanges
			End If
			loadITPSegments(targetTextArea,engine,Result)
		End If
	Next
End Sub

Sub getMeans(source As String) As ResumableSub
	Dim emptyList As List
	emptyList.Initialize
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return emptyList
	End If
	
	Dim youdaoSetuped As Boolean=True
	If mtPreferences.ContainsKey("youdao") Then
		For Each param As String In Utils.getMap("youdao",mtPreferences).Values
			If param="" Then
				youdaoSetuped=False
			End If
		Next
	Else
		youdaoSetuped=False
	End If

	If youdaoSetuped=True Then
		If Main.preferencesMap.ContainsKey("lookupWord") Then
			If Main.preferencesMap.Get("lookupWord")=True Then
				wait for (MT.youdaoMT(source,projectFile.Get("source"),projectFile.Get("target"),True)) Complete (Result As List)
				Return Result
			End If
		End If
	End If
	Return emptyList
End Sub

Sub showTerm(targetTextArea As TextArea)
	Main.termLV.Items.Clear
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Dim terms As List
	terms=projectTerm.termsInASentence(sourceTA.Text)
	Main.termLV.Items.Clear
	For Each termList As List In terms
		Dim p As Pane
		p.Initialize("termpane")
		p.LoadLayout("oneterm")
		p.SetSize(Main.termLV.Width,50)
		Dim lbl1 As Label
		lbl1=p.GetNode(0)
		lbl1.Text=termList.Get(0)
		
		Dim lbl2 As Label
		lbl2=p.GetNode(1)
		lbl2.Text=termList.Get(1)
		Dim termInfo As Map
		termInfo=termList.Get(2)
		If termInfo.ContainsKey("description") Then 'description
			If termInfo.Get("description")<>"" Then
				lbl1.TooltipText=termInfo.Get("description")
				lbl2.TooltipText=termInfo.Get("description")
			End If

		End If
		Main.termLV.Items.Add(p)
	Next
End Sub


Public Sub saveAlltheTranslationToTM
	For Each bitext As List In segments
		projectTM.addPair(bitext.Get(0),bitext.Get(1))
    Next
End Sub

Public Sub saveAlltheTranslationToSegmentsInVisibleArea(FirstIndex As Int, LastIndex As Int)
	For i=Max(0,FirstIndex) To Min(LastIndex,Main.editorLV.Size-1)
		Dim bitext As List
		bitext=segments.Get(i)
		Dim targetTextArea As TextArea
		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
		If p.NumberOfNodes=0 Then
			Continue
		End If
		targetTextArea=p.GetNode(1)
		bitext.Set(1,targetTextArea.Text)
		'projectTM.addPair(bitext.Get(0),bitext.Get(1))
	Next
End Sub

Sub saveTranslation(targetTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.GetItemFromView(targetTextArea.Parent)
	Dim bitext As List
	bitext=segments.Get(index)
	bitext.Set(1,targetTextArea.Text)
	projectTM.addPair(bitext.Get(0),bitext.Get(1))
End Sub

Public Sub fillPane(FirstIndex As Int, LastIndex As Int)
	Log("fillPane")
	Dim ExtraSize As Int
	ExtraSize=15
	For i = 0 To Main.editorLV.Size - 1
		Dim segmentPane As Pane
		segmentPane=Main.editorLV.GetPanel(i)
		If i > FirstIndex - ExtraSize And i < LastIndex + ExtraSize Then
			'visible+

			If segmentPane.NumberOfNodes = 0 Then
                
				Dim bitext As List
				bitext=segments.Get(i)
				addTextAreaToSegmentPane(segmentPane,bitext.Get(0),bitext.Get(1))
				Dim extra As Map
				extra=bitext.Get(4)
				If extra.ContainsKey("translate") Then
					If extra.Get("translate")="no" Then
						Utils.disableTextArea(segmentPane)
					End If
				End If
				If extra.ContainsKey("note") Then
					If extra.Get("note")<>"" Then
						CSSUtils.SetStyleProperty(segmentPane.GetNode(1),"-fx-background-color","green")
					End If
				End If
				If Main.calculatedHeight.ContainsKey(bitext.Get(0)&"	"&bitext.Get(1)) Then
					Dim h As Int=Main.calculatedHeight.Get(bitext.Get(0)&"	"&bitext.Get(1))
					Main.setLayout(segmentPane,i,h)
				End If
				
			End If
		Else
			'not visible
			If segmentPane.NumberOfNodes > 0 Then
				segmentPane.RemoveAllNodes '<--- remove the layout
			End If
		End If
	Next
End Sub

Public Sub fillPaneAsync(FirstIndex As Int, LastIndex As Int) As ResumableSub
	
	Dim ExtraSize As Int
	ExtraSize=15
	For i = 0 To Main.editorLV.Size - 1
		Dim segmentPane As Pane
		segmentPane=Main.editorLV.GetPanel(i)
		If i > FirstIndex - ExtraSize And i < LastIndex + ExtraSize Then
			'visible+
			Sleep(0)
			If segmentPane.NumberOfNodes = 0 Then
                
				Dim bitext As List
				bitext=segments.Get(i)
				addTextAreaToSegmentPane(segmentPane,bitext.Get(0),bitext.Get(1))
				If Main.calculatedHeight.ContainsKey(bitext.Get(0)&"	"&bitext.Get(1)) Then
					Dim h As Int=Main.calculatedHeight.Get(bitext.Get(0)&"	"&bitext.Get(1))
					Main.setLayout(segmentPane,i,h)
				End If
			End If
		Else
			'not visible
			If segmentPane.NumberOfNodes > 0 Then
				segmentPane.RemoveAllNodes '<--- remove the layout
			End If
		End If
	Next
	Return Null
End Sub

Sub preTranslate(options As Map)
	If options.Get("type")<>"" Then
		contentIsChanged
		completed=0
		Dim index As Int=-1
		progressDialog.Show("Pretranslating...","pretranslate")
		For Each bitext As List In segments
			Sleep(0)
			index=index+1
			Dim target As String
			target=bitext.Get(1)
			If target<>"" Then
				completed=completed+1
				progressDialog.update(completed,segments.Size)
				Continue
			End If
			
			Dim bitext As List
			bitext=segments.Get(index)
			
			If options.Get("type")="TM" Then
				If projectTM.ProjectMemorySize=0 Then
					progressDialog.close
					Return
				End If
	            Dim resultList As List
				Wait For (projectTM.getOneUseMemory(bitext.Get(0),options.Get("rate"))) Complete (Result As List)
				resultList=Result
				If resultList.Size=0 Then
					completed=completed+1
					progressDialog.update(completed,segments.Size)
					Continue
				End If
				Dim similarity,matchrate As Double
				similarity=resultList.Get(0)
				matchrate=options.Get("rate")

				Log(bitext.Get(0))
				Log(similarity)
				Log(matchrate)
				Log(similarity>=matchrate)
				
				If similarity>=matchrate Then
					bitext.Set(1,resultList.Get(2))
					segments.Set(index,bitext)
					fillOne(index,resultList.Get(2))
				End If
			Else if options.Get("type")="MT" Then
				wait for (MT.getMT(bitext.Get(0),projectFile.Get("source"),projectFile.Get("target"),options.Get("engine"))) Complete (translation As String)
				If translation<>"" Then
					bitext.Set(1,translation)
					segments.Set(index,bitext)
					fillOne(index,translation)
				End If
			End If
				
			completed=completed+1

			progressDialog.update(completed,segments.Size)
			If completed>=segments.Size Then
				progressDialog.close
				fillVisibleTargetTextArea
				Return
			End If
		Next

		progressDialog.close
		fillVisibleTargetTextArea
	End If
End Sub

Sub fillOne(index As Int,translation As String)
	Dim p As Pane
	p=Main.editorLV.GetPanel(index)
	If p.NumberOfNodes=0 Then
		Return
	End If
	Dim targetTextArea As TextArea
	targetTextArea=p.GetNode(1)
	targetTextArea.Text=translation
	contentIsChanged
End Sub

Public Sub fillVisibleTargetTextArea
	Log("fill")
	Log(Main.editorLV.FirstVisibleIndex)
	Log(Main.editorLV.LastVisibleIndex)
	For i=Max(0,Main.editorLV.FirstVisibleIndex-15) To Min(Main.editorLV.Size-1,Main.editorLV.LastVisibleIndex+14)
		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
		If p.NumberOfNodes=0 Then
			Continue
		End If
		Dim targetTextArea As TextArea
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=segments.Get(i)
		targetTextArea.Text=bitext.Get(1)
	Next
End Sub

Sub runFilterPluginAccordingToExtension(filename As String,task As String,params As Map) As Object
	Log(Main.plugin.GetAvailablePlugins)
	For Each pluginName As String In Main.plugin.GetAvailablePlugins
		If pluginName.EndsWith("Filter") Then
			Dim extension As String
			extension=pluginName.Replace("Filter","")
			If filename.EndsWith(extension) Then
				Return Main.plugin.RunPlugin(pluginName,task,params)
			End If
		End If
	Next
	Return ""
End Sub

Sub createWorkFileAccordingToExtension(filename As String)
	If filename.EndsWith(".txt") Then
		txtFilter.createWorkFile(filename,path,projectFile.Get("source"))
	Else if filename.EndsWith(".idml") Then
		idmlFilter.createWorkFile(filename,path,projectFile.Get("source"))
	Else if filename.EndsWith(".xlf") Then
		xliffFilter.createWorkFile(filename,path,projectFile.Get("source"))
	Else
		Dim params As Map
		params.Initialize
		params.Put("filename",filename)
		params.Put("path",path)
		params.Put("sourceLang",projectFile.Get("source"))
		runFilterPluginAccordingToExtension(filename,"createWorkFile",params)

	End If
End Sub

Sub readWorkFile(filename As String)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
	    Dim innerFilename As String
	    innerFilename=sourceFileMap.GetKeyAt(0)
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		segments.AddAll(segmentsList)
		Dim index As Int=0
		For Each bitext As List In segmentsList
			'Sleep(0) 'should not use coroutine as when change file, it will be a problem.
			If index<=20 Then
				Main.currentProject.createSegmentPane(bitext)
				
				index=index+1
			Else
				Main.currentProject.createEmptyPane(bitext)
				index=index+1
			End If
		Next
	Next
End Sub

Sub saveWorkFile(filename As String)
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim sourceFiles As List
	sourceFiles.Initialize
	
	Dim segmentsForEachFile As List
	segmentsForEachFile.Initialize
	
	Dim previousInnerFilename As String
	Dim firstBitext As List
	firstBitext=segments.Get(0)
	previousInnerFilename= firstBitext.Get(3)
	For Each bitext As List In segments
		If previousInnerFilename=bitext.Get(3) Then
			segmentsForEachFile.Add(bitext)
		Else
			Dim newsegments As List
			newsegments.Initialize
			newsegments.AddAll(segmentsForEachFile)
			Dim sourceFileMap As Map
			sourceFileMap.Initialize
			sourceFileMap.Put(previousInnerFilename,newsegments)
			sourceFiles.Add(sourceFileMap)
			previousInnerFilename=bitext.Get(3)
			segmentsForEachFile.Clear
			segmentsForEachFile.Add(bitext)
		End If
	Next
	'repeat as for the last file, filename will not change
	Dim newsegments As List
	newsegments.Initialize
	newsegments.AddAll(segmentsForEachFile)
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
	sourceFileMap.Put(previousInnerFilename,newsegments)
	sourceFiles.Add(sourceFileMap)
	
	workfile.Put("files",sourceFiles)
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub saveFile(filename As String)
	If filename="" Then
		Return
	End If
	saveAlltheTranslationToSegmentsInVisibleArea(Main.editorLV.FirstVisibleIndex,Main.editorLV.LastVisibleIndex)
	saveAlltheTranslationToTM
	saveWorkFile(filename)
	contentChanged=False
	Main.MainForm.Title=Main.MainForm.Title.Replace("*","")
End Sub


Sub getAllSegments(filename As String) As List
	Dim allSegments As List
	allSegments.Initialize
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim innerFilename As String
		innerFilename=sourceFileMap.GetKeyAt(0)
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		allSegments.AddAll(segmentsList)
	Next
	Return allSegments
End Sub

Public Sub generateTargetFiles
	For Each filename As String In files
		If filename.EndsWith(".txt") Then
			txtFilter.generateFile(filename,path,projectFile)
		Else if filename.EndsWith(".idml") Then
			idmlFilter.generateFile(filename,path,projectFile)
		Else if filename.EndsWith(".xlf") Then
			xliffFilter.generateFile(filename,path,projectFile)
		Else
			Dim params As Map
			params.Initialize
			params.Put("filename",filename)
			params.Put("path",path)
			params.Put("projectFile",projectFile)
			runFilterPluginAccordingToExtension(filename,"generateFile",params)
		End If
	Next
End Sub

Public Sub contentIsChanged
	If contentChanged=False Then
		contentChanged=True
		Main.MainForm.Title=Main.MainForm.Title&"*"
	End If
End Sub
