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
		bitext.Add("")
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
		For Each bitext As List In segmentsList
				Dim segmentPane As Pane
				segmentPane.Initialize("segmentPane")
				segmentPane.LoadLayout("segment")
				Dim sourceTextArea As TextArea
				sourceTextArea=segmentPane.GetNode(0)
				sourceTextArea.Text=bitext.Get(0)
				Dim targetTextArea As TextArea
				targetTextArea=segmentPane.GetNode(1)
				targetTextArea.Text=bitext.Get(1)
				Main.editorLV.Items.Add(segmentPane)
		Next
	Next
	
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
	readFile(filename)
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	Log(New)
	CallSubDelayed3(Main, "ListViewParent_Resize", 0, 0)
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	Log(New)
	CallSubDelayed3(Main, "ListViewParent_Resize", 0, 0)
End Sub