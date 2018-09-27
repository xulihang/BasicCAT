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
	Private files As List
	Private projectFile As Map
	Private currentFilename As String
	Public segments As List
	Public projectTM As TM
	Public projectTerm As Term
	Public lastEntry As Int
	Private lastFilename As String
	Public settings As Map
	Public sh As Shell
	Public completed As Int
	
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	files.Initialize
	projectFile.Initialize
	segments.Initialize
	settings.Initialize

End Sub

Sub initializeTM(projectPath As String)
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
	projectTM.importExternalTranslationMemory(externalTMList)
	'runTMBackend
End Sub

Sub initializeTerm(projectPath As String)
	projectTerm.Initialize(projectPath,projectFile.Get("source"))
End Sub

Sub runTMBackend
	If sh.IsInitialized Then
		Dim sh As Shell
	End If
	sh.Initialize("sh","java",Array As String("-jar","TMBackend.jar","51041"))
	sh.WorkingDirectory=File.DirApp
	sh.RunWithOutputEvents(-1)
End Sub

Sub sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		Log(StdOut)
	Else
		Log("Error: " & StdErr)
	End If
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
	initializeTM(path)
	initializeTerm(path)
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
	Dim tmList As List
	tmList.Initialize
	settings.Put("tmList",tmList)
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
	creatWorkFileAccordingExtension(filename)
	save
End Sub


Public Sub saveSettings(newsettings As Map)
	projectFile.Put("settings",newsettings)
	Log(newsettings)
	save
	projectTM.deleteExternalTranslationMemory
	projectTM.importExternalTranslationMemory(settings.Get("tmList"))
End Sub

public Sub save
	If File.Exists(path,"")=False Then
		creatProjectFiles
	End If
	If projectTM.IsInitialized=False Then
		initializeTM(path)
	End If
	If projectTerm.IsInitialized=False Then
		initializeTerm(path)
	End If
	projectFile.Put("files",files)
	projectFile.Put("lastFile",lastFilename)
	projectFile.Put("lastEntry",lastEntry)
	projectFile.Put("settings",settings)
	Dim json As JSONGenerator
	json.Initialize(projectFile)
	File.WriteString(path,"project.json",json.ToPrettyString(4))
	saveFileAccordingToExtenstion(currentFilename)
End Sub

Sub creatProjectFiles
	File.MakeDir(path,"")
	File.MakeDir(path,"source")
	File.MakeDir(path,"work")
	File.MakeDir(path,"target")
	File.MakeDir(path,"TM")
	File.MakeDir(path,"Term")
End Sub

Public Sub generateTargetFiles
	For Each filename As String In files
		If filename.EndsWith(".txt") Then
			txtFilter.generateFile(filename,path,projectFile)
		End If
	Next
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
		For Each bitext As List In getSegmentsAccordingToExtenstion(filename)
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
	
	Main.editorLV.Clear
	segments.Clear
	currentFilename=filename

	readFileAccordingToExtenstion(currentFilename)

	Log("currentFilename:"&currentFilename)
	If lastFilename=currentFilename Then
		Log("ddd"&True)
		Log(lastEntry)
		Main.editorLV.JumpToItem(lastEntry)
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
	cm.MenuItems.Add(mi)

	lbl.ContextMenu=cm
	
	tti.Initialize("tti",Array As Object(lbl))
	mi.Tag=tti
	subTreeTableItem.Children.Add(tti)
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Public Sub creatSegmentPane(bitext As List) As Pane
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	addTextAreaToSegmentPane(segmentPane,bitext.Get(0),bitext.Get(1))
	Return segmentPane
End Sub

Public Sub creatEmptyPane As Pane
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	Return segmentPane
End Sub

Sub addTextAreaToSegmentPane(segmentpane As Pane,source As String,target As String)
	segmentpane.LoadLayout("segment")
	segmentpane.SetSize(Main.editorLV.AsView.Width,50dip)
	Dim sourceTextArea As TextArea
	sourceTextArea=segmentpane.GetNode(0)
	sourceTextArea.Text=source
	'sourceTextArea.Style = "-fx-font-family: Tahoma;"
	addKeyEvent(sourceTextArea,"sourceTextArea")
	addSelectionChangedEvent(sourceTextArea,"sourceTextAreaSelection")
	Dim targetTextArea As TextArea
	targetTextArea=segmentpane.GetNode(1)
	targetTextArea.Text=target
	'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
	addKeyEvent(targetTextArea,"targetTextArea")
	addSelectionChangedEvent(targetTextArea,"targetTextAreaSelection")
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
	Log(GetType(new))
	Dim ta As TextArea
	ta=Sender
	onSelectionChanged(new,ta,True)
End Sub

Sub targetTextAreaSelection_changed(old As Object, new As Object)
	Log(GetType(new))
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
	
	Dim index As Int
	If isSource Then
		index=0
	Else
		index=1
	End If
	
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
				If ta.Text.SubString2(selectionEnd,Min(ta.Text.Length,selectionEnd+1))<>" " Then
					Return
				End If
			End If
		End If
		
		Main.searchTableView.Items.Clear
		Dim result As List
		result.Initialize
		
		For i=0 To segments.Size-1
			Dim segment As List
			segment=segments.Get(i)
			Dim content As String
			content=segment.Get(index)
			segment.Add(i)
			If content.Contains(selectedText) And content<>ta.Text Then
				result.Add(segment)
			End If
		Next
		For Each segment As List In result
			Dim row()  As Object = Array As String(segment.Get(4),segment.Get(0),segment.Get(1))
			Main.searchTableView.Items.Add(row)
		Next
	End If
End Sub

Sub sourceTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim sourceTextArea As TextArea
	sourceTextArea=Sender
	Dim index As Int
    index=Main.editorLV.GetItemFromView(sourceTextArea.Parent)
	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	Log(result)
	If result="ENTER" Then
		
		Dim source As String
		Dim newSegmentPane As Pane
		newSegmentPane.Initialize("segmentPane")
		source=sourceTextArea.Text.SubString2(sourceTextArea.SelectionEnd,sourceTextArea.Text.Length)
		If source.Trim="" Then
			Return Null
		End If
		sourceTextArea.Text=sourceTextArea.Text.SubString2(0,sourceTextArea.SelectionEnd)
		sourceTextArea.Text=sourceTextArea.Text.Replace(CRLF,"")
		sourceTextArea.Tag=sourceTextArea.Text
		addTextAreaToSegmentPane(newSegmentPane,source,"")
		Dim bitext,newBiText As List
		bitext=segments.Get(index)
		bitext.Set(0,sourceTextArea.Text)
		newBiText.Initialize
		newBiText.Add(source)
		newBiText.Add("")
		newBiText.Add("")
		newBiText.Add(bitext.Get(3))
		segments.set(index,bitext)
		segments.InsertAt(index+1,newBiText)


		Main.editorLV.InsertAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1,newSegmentPane,"")
	Else if result="DELETE" Then
		Dim bitext,nextBiText As List
		bitext=segments.Get(index)
		nextBiText=segments.Get(index+1)
		
		If bitext.Get(3)<>nextBiText.Get(3) Then
			fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different files.","")
			Return Null
		End If
		
		Dim pane,nextPane As Pane
		Dim index As Int
		index=Main.editorLV.GetItemFromView(sourceTextArea.Parent)
		pane=Main.editorLV.GetPanel(index)
		nextPane=Main.editorLV.GetPanel(index+1)
		Dim targetTa,nextSourceTa,nextTargetTa As TextArea
		nextSourceTa=nextPane.GetNode(0)
		nextTargetTa=nextPane.GetNode(1)
		
		Dim sourceWhitespace,targetWhitespace As String
		sourceWhitespace=""
		targetWhitespace=""
		If projectFile.Get("source")="en" Then
			sourceWhitespace=" "
		else if projectFile.Get("target")="en" Then
			targetWhitespace=" "
		End If
		
		sourceTextArea.Text=sourceTextArea.Text.Trim&sourceWhitespace&nextSourceTa.Text.Trim
		sourceTextArea.Tag=sourceTextArea.Text
		
		targetTa=pane.GetNode(1)
		targetTa.Text=targetTa.Text&targetWhitespace&nextTargetTa.Text


		bitext.Set(0,sourceTextArea.Text)
		bitext.Set(1,targetTa.Text)

		bitext.Set(2,bitext.Get(2)&sourceWhitespace&nextBiText.Get(0)) 'ignore next segment newline and spaces

		
		segments.RemoveAt(index+1)
		Main.editorLV.RemoveAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1)
	End If
End Sub

Sub targetTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	If result="ENTER" Then
		Dim targetTextArea As TextArea
		targetTextArea=Sender
		targetTextArea.Text=targetTextArea.Text.Replace(CRLF,"")
		saveTranslation(targetTextArea)
		Try
			Dim pane As Pane
			pane=targetTextArea.Parent
			Dim index As Int
			index=Main.editorLV.GetItemFromView(pane)
			If index=Main.editorLV.Size-1 Then
				index=-1
			End If
			Dim nextPane As Pane
			nextPane=Main.editorLV.GetPanel(index+1)
			Dim nextTA As TextArea
			nextTA=nextPane.GetNode(1)
			nextTA.RequestFocus
			showTM(nextTA)
			showTerm(nextTA)
			lastEntry=Main.editorLV.GetItemFromView(nextPane)
			lastFilename=currentFilename
		Catch
			Log(LastException)
		End Try
	End If
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
	If HasFocus Then
        Log("hasFocus")
		showTM(TextArea1)
		showTerm(TextArea1)
	Else
		lastEntry=Main.editorLV.GetItemFromView(TextArea1.Parent)
		lastFilename=currentFilename
	End If
End Sub

Sub showTM(targetTextArea As TextArea)
	Dim time As Long
	time=DateTime.Now
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Log(sourceTA.Text)
	If projectTM.currentSource=sourceTA.Text Then
		Return
	End If
	Main.tmTableView.Items.Clear
	projectTM.currentSource=sourceTA.Text
	Dim senderFilter As Object = projectTM.getMatchList(sourceTA.Text)
	Wait For (senderFilter) Complete (Result As List)

	For Each matchList As List In Result

		If matchList.Get(1)=sourceTA.Text And matchList.Get(3)="" Then
			Continue 'itself
		End If
		Dim row()  As Object = Array As String(matchList.Get(0),matchList.Get(1),matchList.Get(2),matchList.Get(3))
		Main.tmTableView.Items.Add(row)
	Next
	Log(DateTime.Now-time)
	showMT(sourceTA.Text)
End Sub

Sub showMT(source As String)
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return
	End If
	If Utils.get_isEnabled("baidu_isEnabled",mtPreferences)=True Then
		wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),"baidu")) Complete (Result As String)
		If Result<>"" Then
			Dim row()  As Object = Array As String("","",Result,"MT")
			Main.tmTableView.Items.InsertAt(Min(Main.tmTableView.Items.Size,1),row)
		End If
	End If
End Sub

Sub showTerm(targetTextArea As TextArea)
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
		Main.termLV.Items.Add(p)
	Next
End Sub



Public Sub saveAlltheTranslation(FirstIndex As Int, LastIndex As Int)
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
		projectTM.addPair(bitext.Get(0),bitext.Get(1))
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

Sub seperatedSegments(targetSegments As List) As List
	Dim seperated As List
	seperated.Initialize
	Dim eachsize As Int
	eachsize=targetSegments.Size/4
	If targetSegments.Size<20 Then
		seperated.Add(targetSegments)
	Else
		Dim indexToBeAdded As Int=0
		For i=0 To 3
			Dim oneSeperatedSegments As List
			oneSeperatedSegments.Initialize
			Dim endIndex As Int
			If i=3 Then
				endIndex=targetSegments.Size-1
			Else
				endIndex=eachsize+indexToBeAdded
			End If
			For j=indexToBeAdded To endIndex
				oneSeperatedSegments.Add(targetSegments.Get(indexToBeAdded))
				indexToBeAdded=indexToBeAdded+1
			Next
			seperated.Add(oneSeperatedSegments)
		Next
	End If
	Return seperated
End Sub

Sub preTranslate(options As Map)
	If options.Get("type")<>"" Then
		completed=0
		Dim index As Int=-1
		progressDialog.Show("Pretranslating...")
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
				If projectTM.ExternalMemorySize=0 Then
					progressDialog.close
					Return
				End If
	            Dim resultList As List
				Wait For (projectTM.getOneUseMemory(bitext.Get(0),options.Get("rate"))) Complete (Result As List)
				resultList=Result
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
				End If
			Else if options.Get("type")="MT" Then
				wait for (MT.getMT(bitext.Get(0),projectFile.Get("source"),projectFile.Get("target"),options.Get("engine"))) Complete (translation As String)
				If translation<>"" Then
					bitext.Set(1,translation)
					segments.Set(index,bitext)
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

Sub fillVisibleTargetTextArea
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

Sub creatWorkFileAccordingExtension(filename As String)
	If filename.EndsWith(".txt") Then
		txtFilter.creatWorkFile(filename,path,projectFile.Get("source"))
	Else
		
	End If
End Sub

Sub readFileAccordingToExtenstion(filename As String)
	If filename.EndsWith(".txt") Then
		txtFilter.readFile(filename,segments,path)
	End If
End Sub


Sub saveFileAccordingToExtenstion(filename As String)
	If filename.EndsWith(".txt") Then
		saveAlltheTranslation(Main.editorLV.FirstVisibleIndex,Main.editorLV.LastVisibleIndex)
		txtFilter.saveWorkFile(filename,segments,path)
	End If
End Sub

Sub getSegmentsAccordingToExtenstion(filename As String) As List
	If filename.EndsWith(".txt") Then
		Return txtFilter.readFileAndGetAlltheSegments(filename,path)
	Else
		Return Null
	End If
End Sub
