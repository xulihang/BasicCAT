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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	files.Initialize
	projectFile.Initialize
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
	For Each source As String In segmentation.segmentedTxt(File.ReadString(File.Combine(path,"source"),filename),False)
		Dim bitext As List
		bitext.Initialize
		bitext.Add(source)
		If source.Trim="" Then 'non-text
			bitext.Add(source)
		Else
			bitext.Add("")
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
        Dim hiddenContent As String
		For Each bitext As List In segmentsList
		    Dim source As String
		    source=bitext.Get(0)
			source=source.Trim
			
			Dim segmentPane As Pane
			segmentPane.Initialize("segmentPane")
			segmentPane.LoadLayout("segment")
			If source="" Then
				hiddenContent=hiddenContent&bitext.Get(0)
				Log(hiddenContent)
				Continue
			Else if source<>"" And hiddenContent<>"" Then
				segmentPane.Tag=hiddenContent
				hiddenContent=""
			End If
			segmentPane.Tag=segmentPane.Tag&bitext.Get(0)
			'Log(segmentPane.Tag)
			Dim sourceTextArea As TextArea
			sourceTextArea=segmentPane.GetNode(0)
			sourceTextArea.Text=source
			addKeyEvent(sourceTextArea,"sourceTextArea")
			Dim targetTextArea As TextArea
			targetTextArea=segmentPane.GetNode(1)
			targetTextArea.Text=bitext.Get(1)
			addKeyEvent(targetTextArea,"targetTextArea")
			Main.editorLV.Items.Add(segmentPane)
		Next
	Next
	Dim result As String
	For Each item As Pane In Main.editorLV.Items
		result=result&item.Tag
	Next
	File.WriteString(File.DirApp,"out",result)
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
	CallSubDelayed3(Main, "ListViewParent_Resize", 0, 0)
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed3(Main, "ListViewParent_Resize", 0, 0)
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
		Main.editorLV.Items.InsertAt(Main.editorLV.Items.IndexOf(sourceTextArea.Parent)+1,newSegmentPane)
	Else if result="DELETE" Then
		Dim pane,nextPane As Pane
		Dim index As Int
		index=Main.editorLV.Items.IndexOf(sourceTextArea.Parent)
		pane=Main.editorLV.Items.Get(index)
		nextPane=Main.editorLV.Items.Get(index+1)
		Dim targetTa,nextSourceTa,nextTargetTa As TextArea
		nextSourceTa=nextPane.GetNode(0)
		nextTargetTa=nextPane.GetNode(1)
		
		If projectFile.Get("source")="EN" Then
			sourceTextArea.Text=sourceTextArea.Text&" "&nextSourceTa.Text
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
		
		Main.editorLV.Items.RemoveAt(Main.editorLV.Items.IndexOf(sourceTextArea.Parent)+1)
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
			Main.editorLV.SelectedIndex=Main.editorLV.SelectedIndex+1
			Dim pane As Pane
			pane=Main.editorLV.SelectedItem
			Dim nextTA As TextArea
			nextTA=pane.GetNode(1)
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
	Main.editorLV.SelectedIndex=Main.editorLV.Items.IndexOf(ta.parent)
End Sub