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
		txtFilter.creatTxtWorkFile(filename,path)
	Else
		
	End If
End Sub


public Sub save
	If File.Exists(path,"")=False Then
		creatProjectFiles
	End If
	projectFile.Put("files",files)
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
		If currentFilename.EndsWith(".txt") Then
			txtFilter.readTxtFile(filename,segments,path)
		End If
		
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
	addKeyEvent(sourceTextArea,"sourceTextArea")

	Dim targetTextArea As TextArea
	targetTextArea=segmentPane.GetNode(1)
	targetTextArea.Text=bitext.Get(1)
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

Public Sub saveAlltheTranslation(FirstIndex As Int, LastIndex As Int)
	For i=FirstIndex To LastIndex
		Dim bitext As List
		bitext=segments.Get(i)
		Dim targetTextArea As TextArea
		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
		targetTextArea=p.GetNode(1)
		bitext.Set(1,targetTextArea.Text)
	Next
End Sub

Sub saveTranslation(targetTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.GetItemFromView(targetTextArea.Parent)
	Dim bitext As List
	bitext=segments.Get(index)
	bitext.Set(1,targetTextArea.Text)
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