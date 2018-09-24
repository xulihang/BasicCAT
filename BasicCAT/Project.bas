B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public path As String
	Private files As List
	Private projectFile As Map
	Public status As String
	Private currentFilename As String
	Private segments As List
	Public projectTM As TM
	Public lastEntry As Int
	Private lastFilename As String
	Public settings As Map
	Public sh As Shell
	Private maxRequest As Int
	Private completed As Int
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
			fx.Msgbox(Main.MainForm,filename&"外部记忆文件不存在，会将其从列表中移除","")
            externalTMList.RemoveAt(i)
			settings.Put("tmList",externalTMList)
			save
		End If
	Next
	projectTM.importExternalTranslationMemory(externalTMList)
	runTMBackend
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
	Wait For (File.CopyAsync(filepath,"",File.Combine(path,"source"),filename)) Complete (Success As Boolean)
	Log("Success: " & Success)
	files.Add(filename)
	addFilesToTreeTable(filename)
	creatWorkFile(filename)
	save
End Sub

Sub addFilesToTreeTable(filename As String)
	Dim subTreeTableItem As TreeTableItem
	subTreeTableItem=Main.projectTreeTableView.Root.Children.Get(0)
	Dim lbl As Label
	lbl.Initialize("lbl")
	lbl.Text=filename
	Dim tti As TreeTableItem
	tti.Initialize("tti",Array As Object(lbl))
	subTreeTableItem.Children.Add(tti)
End Sub

Sub creatWorkFile(filename As String)
	If filename.EndsWith(".txt") Then
		txtFilter.creatTxtWorkFile(filename,path)
	Else
		
	End If
End Sub

Public Sub saveSettings(newsettings As Map)
	projectFile.Put("settings",newsettings)
	Log(newsettings)
	save
	projectTM.importExternalTranslationMemory(settings.Get("tmList"))
End Sub

public Sub save
	If File.Exists(path,"")=False Then
		creatProjectFiles
	End If
	If projectTM.IsInitialized=False Then
		initializeTM(path)
	End If
	projectFile.Put("files",files)
	projectFile.Put("lastFile",lastFilename)
	projectFile.Put("lastEntry",lastEntry)
	projectFile.Put("settings",settings)
	Dim json As JSONGenerator
	json.Initialize(projectFile)
	File.WriteString(path,"project.json",json.ToPrettyString(4))
	If currentFilename.EndsWith(".txt") Then
		saveAlltheTranslation(Main.editorLV.FirstVisibleIndex,Main.editorLV.LastVisibleIndex)
		txtFilter.saveTxtWorkFile(currentFilename,segments,path)
	End If
	status="saved"
End Sub

Sub creatProjectFiles
	File.MakeDir(path,"")
	File.MakeDir(path,"source")
	File.MakeDir(path,"work")
	File.MakeDir(path,"target")
	File.MakeDir(path,"TM")
End Sub

Public Sub generateTargetFiles
	For Each filename As String In files
		If filename.EndsWith(".txt") Then
			txtFilter.generateTxtFile(filename,path,projectFile)
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
	Dim lbl As Label
	lbl=Sender
	Log("file changed"&lbl.Text)
	Dim filename As String
	filename=lbl.text
	If currentFilename<>filename Then
		openFile(filename,False)
	End If
End Sub

Sub openFile(filename As String,onOpeningProject As Boolean)
	If onOpeningProject=False Then
		save
	End If
	
	Main.editorLV.Clear
	segments.Clear
	currentFilename=filename

	If currentFilename.EndsWith(".txt") Then
		txtFilter.readTxtFile(filename,segments,path)
	End If

	Log("currentFilename:"&currentFilename)
	If lastFilename=currentFilename Then
		Log("ddd"&True)
		Log(lastEntry)
		Main.editorLV.JumpToItem(lastEntry)
		Wait For(fillPaneAsync(lastEntry-10,lastEntry+10)) Complete (Result As Object)
		Dim pane As Pane
		pane=Main.editorLV.GetPanel(lastEntry)
		Dim ta As TextArea
		ta=pane.GetNode(1)
		ta.RequestFocus
		
	End If
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Public Sub creatSegmentPane(bitext As List) As Pane
	Dim source As String
	source=bitext.Get(0)
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.LoadLayout("segment")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	Dim sourceTextArea As TextArea
	sourceTextArea=segmentPane.GetNode(0)
	sourceTextArea.Text=source
	'sourceTextArea.Style = "-fx-font-family: Tahoma;"
	addKeyEvent(sourceTextArea,"sourceTextArea")

	Dim targetTextArea As TextArea
	targetTextArea=segmentPane.GetNode(1)
	targetTextArea.Text=bitext.Get(1)
	'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
	addKeyEvent(targetTextArea,"targetTextArea")

	Return segmentPane
End Sub

Public Sub creatEmptyPane As Pane
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	Return segmentPane
End Sub

Sub addKeyEvent(textarea1 As TextArea,eventName As String)
	Dim CJO As JavaObject = textarea1
	Dim O As Object = CJO.CreateEventFromUI("javafx.event.EventHandler",eventName&"_KeyPressed",Null)
	CJO.RunMethod("setOnKeyPressed",Array(O))
	CJO.RunMethod("setFocusTraversable",Array(True))
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
		
		Dim newSegmentPane As Pane
		newSegmentPane.Initialize("segmentPane")
		newSegmentPane.LoadLayout("segment")
		Dim newSourceTextArea As TextArea
		newSourceTextArea=newSegmentPane.GetNode(0)
		addKeyEvent(sourceTextArea,"sourceTextArea")
		Dim targetTextArea As TextArea
		targetTextArea=newSegmentPane.GetNode(1)
		addKeyEvent(targetTextArea,"targetTextArea")
		newSourceTextArea.Text=sourceTextArea.Text.SubString2(sourceTextArea.SelectionEnd,sourceTextArea.Text.Length)
		If newSourceTextArea.Text.Trim="" Then
			Return
		End If
		sourceTextArea.Text=sourceTextArea.Text.SubString2(0,sourceTextArea.SelectionEnd)
		sourceTextArea.Text=sourceTextArea.Text.Replace(CRLF,"")
		sourceTextArea.Tag=sourceTextArea.Text
		
		Dim bitext,newBiText As List
		bitext=segments.Get(index)
		bitext.Set(0,sourceTextArea.Text)
		newBiText.Initialize
		newBiText.Add(newSourceTextArea.Text)
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
			Return
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
		If projectFile.Get("source")="EN" Then
			sourceWhitespace=" "
		else if projectFile.Get("target")="EN" Then
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
	Else
		lastEntry=Main.editorLV.GetItemFromView(TextArea1.Parent)
		lastFilename=currentFilename
	End If
End Sub

Sub showTM2(targetTextArea As TextArea)
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
	Wait For (projectTM.getMatchList(sourceTA.Text)) Complete (Result As List)

	For Each matchList As List In Result
		Dim row()  As Object = Array As String(matchList.Get(0),matchList.Get(1),matchList.Get(2),matchList.Get(3))
		Main.tmTableView.Items.Add(row)
	Next
End Sub

Sub showTM(targetTextArea As TextArea)
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	If projectTM.currentSource=sourceTA.Text Then
		Return
	End If
	projectTM.currentSource=sourceTA.Text
	Main.tmTableView.Items.Clear
	Dim job1 As HttpJob
	job1.Initialize("job1",Me)
	job1.Download2("http://127.0.0.1:51041/getMatchList",Array As String("source",sourceTA.Text,"path",path))
	Wait For JobDone(job As HttpJob)
	If job.Success Then
		Log("job")
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim result As List
		result=json.NextArray
		For Each matchList As List In result 
			Dim row()  As Object = Array As String(matchList.Get(0),matchList.Get(1),matchList.Get(2),matchList.Get(3))
			Main.tmTableView.Items.Add(row)
		Next
	End If
	job.Release
End Sub

Public Sub saveAlltheTranslation(FirstIndex As Int, LastIndex As Int)
	For i=Max(0,FirstIndex) To Min(LastIndex,Main.editorLV.Size-1)
		Dim bitext As List
		bitext=segments.Get(i)
		Dim targetTextArea As TextArea
		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
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
				Dim source As String
				source=bitext.Get(0)
				segmentPane.LoadLayout("segment")
				segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
				Dim sourceTextArea As TextArea
				sourceTextArea=segmentPane.GetNode(0)
				sourceTextArea.Text=source
				'sourceTextArea.Style = "-fx-font-family: Tahoma;"
				addKeyEvent(sourceTextArea,"sourceTextArea")

				Dim targetTextArea As TextArea
				targetTextArea=segmentPane.GetNode(1)
				targetTextArea.Text=bitext.Get(1)
				'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
				addKeyEvent(targetTextArea,"targetTextArea")
				Log(bitext)
				Log(targetTextArea.Text)
				Log(i)
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
				Dim source As String
				source=bitext.Get(0)

				segmentPane.LoadLayout("segment")
				segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
				Dim sourceTextArea As TextArea
				sourceTextArea=segmentPane.GetNode(0)
				sourceTextArea.Text=source
				'sourceTextArea.Style = "-fx-font-family: Tahoma;"
				addKeyEvent(sourceTextArea,"sourceTextArea")

				Dim targetTextArea As TextArea
				targetTextArea=segmentPane.GetNode(1)
				targetTextArea.Text=bitext.Get(1)
				'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
				addKeyEvent(targetTextArea,"targetTextArea")
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
	
	If options.Get("type")="TM" Then
		maxRequest=0
		completed=0
		Dim index As Int=-1
		preTrasnlateProgressDialog.Show(3)
		
		Dim seperatedSegments As List
		seperatedSegments.Initialize
		Dim eachsize As Int
		eachsize=segments.Size/4
		If segments.Size<20 Then
			seperatedSegments.Add(segments)
		Else
			Dim indexToBeAdded As Int=0
			For i=0 To 3
			    Dim oneSeperatedSegments As List
			    oneSeperatedSegments.Initialize
				Dim endIndex As Int
				If i=3 Then
					endIndex=segments.Size-1
				Else
					endIndex=eachsize+indexToBeAdded
				End If
				For j=indexToBeAdded To endIndex
					oneSeperatedSegments.Add(segments.Get(indexToBeAdded))
					indexToBeAdded=indexToBeAdded+1
				Next
				seperatedSegments.Add(oneSeperatedSegments)
			Next
		End If
		For Each oneSegments As List In seperatedSegments
			For Each bitext As List In oneSegments
				index=index+1
				Dim source,target As String
				source=bitext.Get(0)
				target=bitext.Get(1)
				If target<>"" Then
					completed=completed+1
					preTrasnlateProgressDialog.update(completed,segments.Size)
					Continue
				End If
			    Do While maxRequest>=10
					Sleep(1000)
		        Loop
				maxRequest=maxRequest+1
                getOneMatch(bitext.Get(0),index,options.Get("rate"))
			Next
		Next
		Do While completed<>segments.size
			Sleep(1000)
		Loop
		preTrasnlateProgressDialog.close
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

'Good example. Use.
Sub getOneMatch(source As String, index As Int,matchRate As Double)
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download2("http://127.0.0.1:51041/getOneMatch",Array As String("source",source,"path",path,"index",index,"matchrate",matchRate))
				
	Wait For (job) JobDone(job As HttpJob)
	completed=completed+1
	If job.Success Then
		Log("job")
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim result As List
		result=json.NextArray
	End If
	job.Release
	maxRequest=maxRequest-1
	Dim completedIndex As Int
	completedIndex=result.Get(4)
	Dim similarity As Double
	similarity=result.Get(0)
	Dim bitext As List
	bitext=segments.Get(completedIndex)
	Log(bitext.Get(0))
	Log(similarity)
	Log(matchRate)
	Log(similarity>=matchRate)
	If similarity>=matchRate Then
		bitext.Set(1,result.Get(2))
		segments.Set(completedIndex,bitext)
	End If
	preTrasnlateProgressDialog.update(completed,segments.Size)
End Sub