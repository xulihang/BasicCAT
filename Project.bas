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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	files.Initialize
	projectFile.Initialize
	segments.Initialize
End Sub

Public Sub open(jsonPath As String)
	Main.addProjectTreeTableItem
	path=getProjectPath(jsonPath)
	Log(path)
	Dim json As JSONParser
	json.Initialize(File.ReadString(jsonPath,""))
	projectFile=json.NextObject
	files.AddAll(projectFile.Get("files"))
	For Each filepath As String In files
		addFilesToTreeTable(filepath)
	Next
End Sub

Public Sub newProjectSetting(source As String,target As String)
	projectFile.Put("source",source)
	projectFile.Put("target",target)
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
		creatTxtWorkFile(filename)
	Else
		
	End If
End Sub

Sub creatTxtWorkFile(filename As String)
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	
	Dim sourceFiles As List
	sourceFiles.Initialize
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
    Dim segmentsList As List
	segmentsList.Initialize
	Dim inbetweenContent As String
	For Each source As String In segmentation.segmentedTxt(File.ReadString(File.Combine(path,"source"),filename),False)
		Dim bitext As List
		bitext.Initialize
        Log(source.Contains(CRLF))
		If source.Trim="" Then 'newline
			inbetweenContent=inbetweenContent&CRLF
			Continue
		Else if source.Trim<>"" Then
			bitext.add(source.Trim)
			bitext.Add("")
			bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
			inbetweenContent=""
		End If
		segmentsList.Add(bitext)
	Next
	sourceFileMap.Put("filename",filename)
	sourceFileMap.put("segmentsList",segmentsList)
	sourceFiles.Add(sourceFileMap)
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub readFile(filename As String)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get("segmentsList")
        segments.AddAll(segmentsList)
		Dim index As Int=0
		For Each bitext As List In segmentsList
			Sleep(0)

			If index<=20 Then
				Main.editorLV.Add(creatSegmentPane(bitext),"")
				index=index+1
			Else
				Main.editorLV.Add(creatEmptyPane,"")
				index=index+1
			End If
		Next
	Next
	Dim result As String
	For i=0 To Main.editorLV.size - 1
		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
		result=result&p.Tag
	Next
	File.WriteString(File.DirApp,"out",result)
End Sub

Sub creatSegmentPane(bitext As List) As Pane
	Dim source As String
	source=bitext.Get(0)
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.LoadLayout("segment")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	segmentPane.Tag=segmentPane.Tag&bitext.Get(0)
	Dim sourceTextArea As TextArea
	sourceTextArea=segmentPane.GetNode(0)
	sourceTextArea.Text=source
	addKeyEvent(sourceTextArea,"sourceTextArea")
	'Dim sourceLbl As Label
	'sourceLbl.Initialize("sourcelbl")
	'sourceLbl.Text=source
	'segmentPane.AddNode(sourceLbl,0,0,Main.editorLV.AsView.Width/2,50)
	Dim targetTextArea As TextArea
	targetTextArea=segmentPane.GetNode(1)
	targetTextArea.Text=bitext.Get(1)
	addKeyEvent(targetTextArea,"targetTextArea")
	'Dim targetLbl As Label
	'targetLbl.Initialize("targetLbl")
	'targetLbl.Text=bitext.Get(1)
	'segmentPane.AddNode(targetLbl,Main.editorLV.AsView.Width/2,0,Main.editorLV.AsView.Width/2,50)
	'sourceTextArea.RemoveNodeFromParent
	'targetTextArea.RemoveNodeFromParent
	Return segmentPane
End Sub

Sub creatEmptyPane As Pane
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.SetSize(Main.editorLV.AsView.Width,50dip)
	Return segmentPane
End Sub

public Sub save
	If File.Exists(path,"")=False Then
		creatProjectFiles
	End If
	projectFile.Put("files",files)
	Dim json As JSONGenerator
	json.Initialize(projectFile)
	File.WriteString(path,"project.json",json.ToPrettyString(4))
	status="saved"
End Sub

Sub creatProjectFiles
	File.MakeDir(path,"")
	File.MakeDir(path,"source")
	File.MakeDir(path,"work")
	File.MakeDir(path,"target")
End Sub

Sub getProjectPath(jsonPath As String) As String
	Dim ProjectPath As String
	Try
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("\"))
	Catch
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("\"))
		Log(LastException)
	End Try
	Return ProjectPath
End Sub

Sub lbl_MouseClicked (EventData As MouseEvent)
	Dim lbl As Label
	lbl=Sender
	Log(lbl.Text)
	Dim filename As String
	filename=lbl.text
	If currentFilename<>filename Then
		currentFilename=filename
		readFile(filename)
	End If
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
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
		Main.editorLV.InsertAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1,newSegmentPane,"")
	Else if result="DELETE" Then
		Dim pane,nextPane As Pane
		Dim index As Int
		index=Main.editorLV.GetItemFromView(sourceTextArea.Parent)
		pane=Main.editorLV.GetPanel(index)
		nextPane=Main.editorLV.GetPanel(index+1)
		Dim targetTa,nextSourceTa,nextTargetTa As TextArea
		nextSourceTa=nextPane.GetNode(0)
		nextTargetTa=nextPane.GetNode(1)
		
		If projectFile.Get("source")="EN" Then
			sourceTextArea.Text=sourceTextArea.Text.Trim&" "&nextSourceTa.Text.Trim
		Else
			sourceTextArea.Text=sourceTextArea.Text&nextSourceTa.Text
		End If
		
		sourceTextArea.Tag=sourceTextArea.Text
		targetTa=pane.GetNode(1)
		pane.Tag=pane.Tag&nextPane.Tag
		
		If projectFile.Get("target")="EN" Then
			targetTa.Text=targetTa.Text&" "&nextTargetTa.Text
		Else
			targetTa.Text=targetTa.Text&nextTargetTa.Text
		End If
		
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

Sub targetTextArea_MouseClicked (EventData As MouseEvent)
	Dim ta As TextArea
	ta=Sender
End Sub

Public Sub fillPane(FirstIndex As Int, LastIndex As Int)
	
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
				segmentPane.Tag=segmentPane.Tag&bitext.Get(0)
				Dim sourceTextArea As TextArea
				sourceTextArea=segmentPane.GetNode(0)
				sourceTextArea.Text=source
				addKeyEvent(sourceTextArea,"sourceTextArea")

				Dim targetTextArea As TextArea
				targetTextArea=segmentPane.GetNode(1)
				targetTextArea.Text=bitext.Get(1)
				addKeyEvent(targetTextArea,"targetTextArea")
			End If
		Else
			'not visible
			If segmentPane.NumberOfNodes > 0 Then
				segmentPane.RemoveAllNodes '<--- remove the layout
			End If
		End If
	Next
	'For i = Max(0, FirstIndex - ExtraSize) To Min(LastIndex + ExtraSize,Main.editorLV.Size - 1)
	'Next
End Sub