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
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	wait for (unzipAndLoadIDML(path,filename)) Complete (spreadsList As List)
	
	Dim storiesList As List
	storiesList.Initialize
	For Each map1 As Map In spreadsList
		Dim leftPageStoriesForSpreadList,rightPageStoriesForSpreadList As List
		leftPageStoriesForSpreadList.Initialize
		rightPageStoriesForSpreadList.Initialize
		Dim spreadMap As Map
		spreadMap=map1.Get("spreadMap")
		For Each TextFrame As Map In TextFramesListOfEachSpread(spreadMap)
			Dim attributes As Map
			attributes=TextFrame.Get("Attributes")
			Dim XY As coordinate
			XY.Initialize(attributes.Get("ItemTransform"))
			Dim storyID As String
			storyID=attributes.Get("ParentStory")
			Dim XY As coordinate
			XY.Initialize(attributes.Get("ItemTransform"))
			If XY.x<0 Then
				leftPageStoriesForSpreadList.Add(storyID)
			Else
				rightPageStoriesForSpreadList.Add(storyID)
			End If
			
			Log(XY)
		Next
		storiesList.AddALL(leftPageStoriesForSpreadList)
		storiesList.AddALL(rightPageStoriesForSpreadList)
	Next

	Log(storiesList)
	
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim sourceFiles As List
	sourceFiles.Initialize

	

	For Each storyID As String In storiesList
		Dim sourceFileMap As Map
		sourceFileMap.Initialize
		Dim segmentsList As List
		segmentsList.Initialize
		Dim storyString As String
		storyString=File.ReadString(unzipedDirPath,"Stories/Story_"&storyID&".xml")
		Dim storyContent As String
		storyContent=getStoryContent(getXmlMap(storyString))
		storyContent=stripContent(storyContent)
		Dim inbetweenContent As String
		Dim innerFilename As String
		innerFilename="Story_"&storyID&".xml"
		Log(storyContent)
		For Each source As String In segmentation.segmentedTxt(storyContent,False,sourceLang)
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
	Next
	
	sourceFiles.Add(sourceFileMap)
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub unzipAndLoadIDML(path As String,filename As String) As ResumableSub
	Dim spreadsList As List
	spreadsList.Initialize
	
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	Log(File.Combine(File.Combine(path,"source"),filename.Replace(".idml","")))
	File.MakeDir(File.Combine(path,"source"),filename.Replace(".idml",""))
	
	Log(unzipedDirPath)
	
	Dim archiver As Archiver
	archiver.AsyncUnZip(File.Combine(path,"source"),filename,unzipedDirPath,"archiver")
	wait for archiver_UnZipDone(CompletedWithoutError As Boolean, NbOfFiles As Int)
	Log(CompletedWithoutError)
	
	Dim designmapString As String
	designmapString=File.ReadString(unzipedDirPath, "designmap.xml")
	Dim spreadsPathList As List
	spreadsPathList=getSpreadsPathList(getXmlMap(designmapString))
	For Each spreadPath As String In spreadsPathList
		Dim spreadString As String
		spreadString=File.ReadString(unzipedDirPath,spreadPath)
		Dim map1 As Map
		map1.Initialize
		map1.Put("path",spreadPath)
		map1.Put("spreadMap",getXmlMap(spreadString))
		spreadsList.Add(map1)
	Next
	Return spreadsList
End Sub

Sub saveWorkFile(filename As String,segments As List,path As String)
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

Sub readFile(filename As String,segments As List,path As String)

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


Sub getXmlMap(xmlstring As String) As Map
	Dim ParsedData As Map
	Dim xm As Xml2Map
	xm.Initialize
	ParsedData = xm.Parse(xmlstring)
	Return ParsedData
End Sub

Sub getSpreadsPathList(ParsedData As Map) As List
	Dim Document As Map = ParsedData.Get("Document")
	Dim SpreadsList As List
	SpreadsList=GetElements(Document,"idPkg:Spread")
	Dim pathList As List
	pathList.Initialize
	For Each spread As Map In SpreadsList
		Dim Attributes As Map
		Attributes=spread.Get("Attributes")
		pathList.Add(Attributes.Get("src"))
	Next
	Return pathList
End Sub

Sub getStoryContent(ParsedData As Map) As String
	Dim root As Map = ParsedData.Get("idPkg:Story")
	Dim story As Map = root.Get("Story")
	Dim content As String
	Dim ParagraphStyleRanges As List
	ParagraphStyleRanges=GetElements(story,"ParagraphStyleRange")
	For Each ParagraphStyleRange As Map In ParagraphStyleRanges
		Dim CharacterStyleRanges As List
		CharacterStyleRanges=GetElements(ParagraphStyleRange,"CharacterStyleRange")
		For Each CharacterStyleRange As Map In CharacterStyleRanges
			For Each key As String In CharacterStyleRange.Keys
				Log(key)
				If key="Br" Then
					content=content&CRLF
				End If
				If key="Content" Then
					If CharacterStyleRange.Get("Content")=Null Then
						Continue
					End If
					content=content&CharacterStyleRange.Get("Content")
				End If
			Next

			
		Next
		content=content&CRLF
	Next
	Return content
End Sub


Sub sortTextFrameList(TextFramesList As List) As List
	Dim LeftXYAsKey As Map
	LeftXYAsKey.Initialize
	Dim RightXYAsKey As Map
	RightXYAsKey.Initialize
	Dim LeftXY,RightXY As List
	LeftXY.Initialize
	RightXY.Initialize
	For Each TextFrame As Map In TextFramesList
		Dim attributes As Map
		attributes=TextFrame.Get("Attributes")
		Dim XY As coordinate
		XY.Initialize(attributes.Get("ItemTransform"))
		If XY.X<=0 Then
			LeftXYAsKey.Put(XY,TextFrame)
			LeftXY.Add(XY)
		Else
			RightXYAsKey.Put(XY,TextFrame)
			RightXY.Add(XY)
		End If
	Next
	Dim resultList As List
	resultList.Initialize
	For Each XY As coordinate In BubbleSort(LeftXY)
		resultList.Add(LeftXYAsKey.Get(XY))
	Next
	For Each XY As coordinate In BubbleSort(RightXY)
		resultList.Add(RightXYAsKey.Get(XY))
	Next
	Return resultList
End Sub

Sub GetElements (m As Map, key As String) As List
	Dim res As List
	If m.ContainsKey(key) = False Then
		res.Initialize
		Return res
	Else
		Dim value As Object = m.Get(key)
		If value Is List Then Return value
		res.Initialize
		res.Add(value)
		Return res
	End If
End Sub

Sub BubbleSort(XYList As List) As List

	For j=0 To XYList.Size-1
		For i = 1 To XYList.Size - 1
			If  NextIsLower(XYList.Get(i),XYList.Get(i-1)) Then
				XYList=Swap(XYList,i, i-1)

			End If
		Next
	Next
	Return XYList
End Sub

Sub Swap(XYList As List,index1 As Int, index2 As Int) As List
	Dim temp As coordinate
	temp = XYList.Get(index1)
	XYList.Set(index1,XYList.Get(index2))
	XYList.Set(index2,temp)
	Return XYList
End Sub

Sub NextIsLower(XY1 As coordinate,XY2 As coordinate) As Boolean
	'XY1 is the next
	If XY1.Y<=XY2.Y Then
		Return True
	Else
		Return False
	End If
End Sub

Sub stripContent(content As String) As String
	content=Regex.Replace(" +", content," ")
	content=content.Replace(" ","")
	content=content.Replace("  "," ")
	content=Regex.Replace("\n\n+",content,CRLF&CRLF)
	Return content
End Sub


Sub TextFramesListOfEachSpread(spreadMap As Map) As List
	Dim root As Map
	root=spreadMap.Get("idPkg:Spread")
	Dim Spread As Map
	Spread=root.Get("Spread")
	Dim TextFramesList As List
	TextFramesList=GetElements(Spread,"TextFrame")
	
	'add textframes in groups
	Dim groupsList As List
	groupsList.Initialize
	groupsList.AddAll(GetElements(Spread,"Group"))
	For Each group As Map In groupsList
		TextFramesList.AddAll(GetElements(group,"TextFrame"))
	Next
	
	'sort the TextFrames according to the order of left-upper to right-lower
	TextFramesList=sortTextFrameList(TextFramesList)
	
	'remove duplicate stories as some TextFrames are linked
	Dim storyIDList As List
	storyIDList.Initialize
	Dim newList As List
	newList.Initialize
	For Each TextFrame As Map In TextFramesList
		Dim attributes As Map
		attributes=TextFrame.Get("Attributes")
		Dim storyID As String
		storyID=attributes.Get("ParentStory")
		Log(storyID)
		If storyIDList.IndexOf(storyID)=-1 Then
			newList.Add(TextFrame)
			storyIDList.Add(storyID)
		End If
	Next
	Return newList

End Sub

Sub readFileAndGetAlltheSegments(filename As String,path As String) As List
	Dim segments As List
	segments.Initialize

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
	Next
	Return segments
End Sub