B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub creatWorkFile(filename As String,path As String,sourceLang As String)
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim innerFilename As String
	innerFilename=filename
	Dim sourceFiles As List
	sourceFiles.Initialize
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
	Dim segmentsList As List
	segmentsList.Initialize
	Dim inbetweenContent As String
	For Each source As String In segmentation.segmentedTxt(File.ReadString(File.Combine(path,"source"),filename),False,sourceLang,"txt")
		Dim bitext As List
		bitext.Initialize
		If source.Trim="" Then 'newline
			inbetweenContent=inbetweenContent&CRLF
			Continue
		Else if source.Trim<>"" Then
			bitext.add(source.Trim)
			bitext.Add("")
			bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
			bitext.Add(innerFilename)
			inbetweenContent=""
		End If
		segmentsList.Add(bitext)
	Next
	sourceFileMap.Put(innerFilename,segmentsList)
	sourceFiles.Add(sourceFileMap)
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub saveWorkFile(filename As String,segments As List,path As String)
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim sourceFiles As List
	sourceFiles.Initialize
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
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
			sourceFileMap.Put(previousInnerFilename,newsegments)

			previousInnerFilename=bitext.Get(3)
			segmentsForEachFile.Clear
			segmentsForEachFile.Add(bitext)
		End If
	Next
	'repeat as for the last file, filename will not change
	Dim newsegments As List
	newsegments.Initialize
	newsegments.AddAll(segmentsForEachFile)
	sourceFileMap.Put(previousInnerFilename,newsegments)


	sourceFiles.Add(sourceFileMap)
	workfile.Put("files",sourceFiles)
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub readFile(filename As String,segments As List,path As String)
	Dim innerFilename As String
	innerFilename=filename
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		segments.AddAll(segmentsList)
		Dim index As Int=0
		For Each bitext As List In segmentsList
			'Sleep(0) should not use coroutine as when change file, it will be a problem.

			If index<=20 Then
				Main.editorLV.Add(Main.currentProject.creatSegmentPane(bitext),"")
				
				index=index+1
			Else
				Main.editorLV.Add(Main.currentProject.creatEmptyPane,"")
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

Sub generateFile(filename As String,path As String,projectFile As Map)
	Dim innerfilename As String=filename
	Dim result As String
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerfilename)
		For Each bitext As List In segmentsList
			Dim source,target,fullsource,translation As String
			source=bitext.Get(0)
			target=bitext.Get(1)
			fullsource=bitext.Get(2)
			Log(source)
			Log(target)
			Log(fullsource)
			If target="" Then
				translation=fullsource
			Else
				translation=fullsource.Replace(source,target)
				If projectFile.Get("source")="en" Then
					translation=translation.Replace(" ","")
				End If
			End If
			result=result&translation
		Next
	Next
	File.WriteString(File.Combine(path,"target"),filename,result)
End Sub

Sub readFileAndGetAlltheSegments(filename As String,path As String) As List
	Dim segments As List
	segments.Initialize
	Dim innerFilename As String
	innerFilename=filename
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		segments.AddAll(segmentsList)
	Next
	Return segments
End Sub

Sub mergeSegment(sourceTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.GetItemFromView(sourceTextArea.Parent)
	
	Dim bitext,nextBiText As List
	bitext=Main.currentProject.segments.Get(index)
	nextBiText=Main.currentProject.segments.Get(index+1)
		
	If bitext.Get(3)<>nextBiText.Get(3) Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
		
	Dim pane,nextPane As Pane

	pane=Main.editorLV.GetPanel(index)
	nextPane=Main.editorLV.GetPanel(index+1)
	Dim targetTa,nextSourceTa,nextTargetTa As TextArea
	nextSourceTa=nextPane.GetNode(0)
	nextTargetTa=nextPane.GetNode(1)
		
	Dim sourceWhitespace,targetWhitespace As String
	sourceWhitespace=""
	targetWhitespace=""
	If Main.currentProject.projectFile.Get("source")="en" Then
		If Regex.IsMatch("\w",sourceTextArea.Text.CharAt(sourceTextArea.Text.Length-1)) Or Regex.IsMatch("\w",nextSourceTa.Text.CharAt(0)) Then
			sourceWhitespace=" "
		End If
	else if Main.currentProject.projectFile.Get("target")="en" Then
		targetWhitespace=" "
	End If
		
	sourceTextArea.Text=sourceTextArea.Text.Trim&sourceWhitespace&nextSourceTa.Text.Trim
	sourceTextArea.Tag=sourceTextArea.Text
		
	targetTa=pane.GetNode(1)
	targetTa.Text=targetTa.Text&targetWhitespace&nextTargetTa.Text


	bitext.Set(0,sourceTextArea.Text)
	bitext.Set(1,targetTa.Text)

    Dim fullsource,nextFullSource As String
	fullsource=bitext.Get(2)
	nextFullSource=nextBiText.Get(2)
	If Main.currentProject.projectFile.Get("source")="en" Then
		If fullsource.EndsWith(" ")=False And nextFullSource.StartsWith(" ")=False Then
			If Regex.IsMatch("\w",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\w",nextFullSource.CharAt(0)) Then
				sourceWhitespace=" "
			Else
				sourceWhitespace=""
			End If
		Else
			sourceWhitespace=""
		End If
	End If
	bitext.Set(2,fullsource&sourceWhitespace&nextFullSource)

		
	Main.currentProject.segments.RemoveAt(index+1)
	Main.editorLV.RemoveAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1)
End Sub

Sub splitSegment(sourceTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.GetItemFromView(sourceTextArea.Parent)
	Dim source As String
	Dim newSegmentPane As Pane
	newSegmentPane.Initialize("segmentPane")
	source=sourceTextArea.Text.SubString2(sourceTextArea.SelectionEnd,sourceTextArea.Text.Length)
	If source.Trim="" Then
		Return
	End If
	sourceTextArea.Text=sourceTextArea.Text.SubString2(0,sourceTextArea.SelectionEnd)
	sourceTextArea.Text=sourceTextArea.Text.Replace(CRLF,"")
	sourceTextArea.Tag=sourceTextArea.Text
	Main.currentProject.addTextAreaToSegmentPane(newSegmentPane,source,"")
	Dim bitext,newBiText As List
	bitext=Main.currentProject.segments.Get(index)
	
	Dim fullsource As String
	fullsource=bitext.Get(2)
	
	bitext.Set(0,sourceTextArea.Text)
	bitext.Set(2,fullsource.Replace(source,"").Trim)
	
	
	newBiText.Initialize
	newBiText.Add(source)
	newBiText.Add("")
	newBiText.Add(fullsource.Replace(sourceTextArea.Text,""))
	newBiText.Add(bitext.Get(3))
	Main.currentProject.segments.set(index,bitext)
	Main.currentProject.segments.InsertAt(index+1,newBiText)


	Main.editorLV.InsertAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1,newSegmentPane,"")
End Sub