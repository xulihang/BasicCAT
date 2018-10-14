B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private paragraphStyles As List
	Private characterStyles As List
	Private parser As SaxParser
	Private order As List
End Sub

Sub loadStyles(unzipedDirPath As String)
	Dim styleXmlMap As Map
	styleXmlMap=getXmlMap(File.ReadString(File.Combine(unzipedDirPath,"Resources"),"Styles.xml"))
	paragraphStyles=getStyleList(styleXmlMap,"paragraph")
	characterStyles=getStyleList(styleXmlMap,"character")
End Sub



Sub creatWorkFile(filename As String,path As String,sourceLang As String)
	If order.IsInitialized=False Then
		parser.Initialize
		order.Initialize
	End If
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	wait for (unzipAndLoadIDML(path,filename)) Complete (spreadsList As List)
	
	loadStyles(unzipedDirPath)
	
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
		Sleep(0)
		Log(storyID)
		Dim sourceFileMap As Map
		sourceFileMap.Initialize
		Dim segmentsList As List
		segmentsList.Initialize
		Dim storyString As String
		storyString=File.ReadString(unzipedDirPath,"Stories/Story_"&storyID&".xml")
		getBrContentOrder(File.Combine(unzipedDirPath,"Stories/Story_"&storyID&".xml"))
		Dim storyContent As String
		storyContent=getStoryContent(getXmlMap(storyString))

		Dim inbetweenContent As String
		Dim innerFilename As String
		innerFilename="Story_"&storyID&".xml"
		Log(storyContent)
		Dim index As Int=-1
		Dim segmentedText As List
		segmentedText=segmentation.segmentedTxt(storyContent,False,sourceLang,"idml")
		For Each source As String In segmentedText
			index=index+1
			Dim bitext As List
			bitext.Initialize
			If source.Trim="" And index<segmentedText.Size-1 Then 'newline
				inbetweenContent=inbetweenContent&CRLF
				Continue
			Else if Regex.Replace("<.*?>",source,"").Trim="" And index<segmentedText.Size-1 Then ' pure tag maybe with \t \n
				Log("totalmatch"&source)
				Log(index)
				Log(segmentedText.size)
				inbetweenContent=inbetweenContent&source
				Continue
			Else
                Dim sourceShown As String
				sourceShown=Utils.getPureText(source)
				
				Log("sourceShown"&sourceShown)
				bitext.add(sourceShown.Trim)
				bitext.Add("")
				bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
				bitext.Add(innerFilename)
				inbetweenContent=""
			End If
			Log(index)
			Log(segmentedText.Size-1)
			If index=segmentedText.Size-1 And sourceShown="" And segmentsList.size=0 Then
				'This is a pagenum story
				Continue
			End If
			If index=segmentedText.Size-1 And sourceShown="" Then 'last segment contains tags
				Log(bitext)
				Log(segmentsList)
				Dim previousBitext As List
				previousBitext=segmentsList.Get(segmentsList.Size-1)
				previousBitext.Set(0,previousBitext.Get(0)&bitext.Get(0))
				previousBitext.Set(2,previousBitext.Get(2)&bitext.Get(2))
			Else
				segmentsList.Add(bitext)
			End If
			
			
		Next
		Log(segmentsList)
		Do While containsSingleTagContent(segmentsList)
			'Log(segmentsList)
			mergeSubsentences(segmentsList)
		Loop
		If segmentsList.Size<>0 Then
			sourceFileMap.Put(innerFilename,segmentsList)
			sourceFiles.Add(sourceFileMap)
		End If
	Next
	
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub mergeSubsentences(segmentsList As List)
	If segmentsList.Size<3 Then
		Return
	End If
	Dim newList As List
	newList.Initialize
	Dim duplicatedList As List
	duplicatedList.Initialize
	duplicatedList.AddAll(segmentsList)
	Dim previousMergedIndex As Int=segmentsList.Size
	Dim merged As Boolean=False
	
	For index=0 To segmentsList.Size-1
		Dim previousSegment,bitext,nextSegment As List
		bitext=duplicatedList.Get(index)
		Dim previousSource,fullsource,nextSource As String

		If index-1>=0 And index+1<=duplicatedList.Size-1 Then
			previousSegment=duplicatedList.Get(index-1)
			nextSegment=duplicatedList.Get(index+1)
			previousSource=previousSegment.Get(2)
			fullsource=bitext.Get(2)
			nextSource=nextSegment.Get(2)

			If merged=False Or index-previousMergedIndex>=3 Then
				If Regex.IsMatch("<.*?>",fullsource.Trim) And Utils.isEndOfSentence(fullsource.Trim)=False And Utils.isEndOfSentence(nextSource) And previousSource.Contains("</p")=False And nextSource.Contains("<p")=False Then
					Dim newSegment As List
					newSegment.Initialize
					If Main.currentproject.projectFile.Get("source")="en" Then
						newSegment.Add(previousSegment.Get(0)&" "&fullsource.Trim&" "&nextSegment.Get(0))
					Else
						newSegment.Add(previousSegment.Get(0)&fullsource.Trim&nextSegment.Get(0))
					End If
					
					newSegment.Add("")
					newSegment.Add(previousSegment.Get(2)&fullsource.Trim&nextSegment.Get(2))
					newSegment.Add(previousSegment.Get(3))

					previousMergedIndex=index
					newList.RemoveAt(newList.Size-1)
					newList.Add(newSegment)
					merged=True
				End If
			End If
		End If
		
		If merged=False Or index-previousMergedIndex>=2 Then
			newList.Add(bitext)
		End If
	Next
	segmentsList.Clear
	segmentsList.AddAll(newList)
End Sub

Sub containsSingleTagContent(segmentsList As List) As Boolean
	If segmentsList.Size<3 Then
		Return False
	End If
	For index=0 To segmentsList.Size-1
		Dim previousSegment,bitext,nextSegment As List
		bitext=segmentsList.Get(index)
		Dim previousSource,fullsource,nextSource As String
		If index-1>=0 And index+1<=segmentsList.Size-1 Then
			previousSegment=segmentsList.Get(index-1)
			nextSegment=segmentsList.Get(index+1)
			previousSource=previousSegment.Get(2)
			fullsource=bitext.Get(2)
			nextSource=nextSegment.Get(2)
			Dim fullsource As String
			fullsource=bitext.Get(2)
			If Regex.IsMatch("<.*?>",fullsource.Trim) And Utils.isEndOfSentence(fullsource.Trim)=False  And Utils.isEndOfSentence(nextSource) And previousSource.Contains("</p")=False And nextSource.Contains("<p")=False Then
				Log(fullsource)
				Return True
			End If
		End If
	Next
	Return False
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

Sub taggedTextToXml(taggedText As String,storypath As String) As String
	Log("storypath"&storypath)
	Dim storyMap As Map
	storyMap=getXmlMap(File.ReadString(storypath,""))
	Dim root As Map = storyMap.Get("idPkg:Story")
	Dim story As Map = root.Get("Story")
	Dim ParagraphStyleRanges As List
	ParagraphStyleRanges=GetElements(story,"ParagraphStyleRange")
	ParagraphStyleRanges.Clear
	Dim matcher As Matcher
	matcher=Regex.Matcher("(?s)<p\d+>.*?</p\d+>",taggedText)
	Dim paragraphsTextList As List
	paragraphsTextList.Initialize
	
	Do While matcher.Find
		paragraphsTextList.Add(matcher.Match)
	Loop
	Log(paragraphsTextList)
	For Each paragraphText As String In paragraphsTextList
		Log(paragraphText)
		Dim paragraphMap As Map
		paragraphMap.Initialize
		paragraphMap=CreateMap("Attributes":CreateMap("AppliedParagraphStyle":paragraphStyles.Get(getStyleIndex(paragraphText,"paragraph"))))
		Dim matcher2 As Matcher
		matcher2=Regex.Matcher("(?s)<c\d+>.*?</c\d+>",paragraphText)
		Dim characterMapsList As List
		characterMapsList.Initialize
		Dim characterTextList As List
		characterTextList.Initialize
		Do While matcher2.Find
			characterTextList.Add(matcher2.Match)
		Loop
		Log(characterTextList)
		For Each characterText As String In characterTextList
			'Log(characterText)
			Dim styleIndex As String
			styleIndex=getStyleIndex(characterText,"character")
			Dim pureText As String=characterText
			Dim tagMatcher As Matcher
			tagMatcher=Regex.Matcher("<.*?>",characterText)
			Do While tagMatcher.Find
				pureText=pureText.Replace(tagMatcher.Match,"")
			Loop
			'Log(styleIndex)
			Log(pureText)
			If pureText.StartsWith("Z") Then
				Log(pureText.Contains(CRLF))
			End If


			Dim list1 As List
			list1=textToListInOrder(pureText)
			characterMapsList.Add(CreateMap("Attributes":CreateMap("AppliedCharacterStyle":characterStyles.Get(styleIndex)),"Content":list1))
		Next
		paragraphMap.Put("CharacterStyleRange",characterMapsList)
		Log(paragraphMap)
		ParagraphStyleRanges.Add(paragraphMap)
	Next
	story.Put("ParagraphStyleRange",ParagraphStyleRanges)
	Dim result As String
	result=getXmlFromMap(storyMap)
	result=result.Replace("<Content>"&Chr(13) & Chr(10) &"</Content>","<Br />")

	Return result
End Sub



Sub generateFile(filename As String,path As String,projectFile As Map)
	If paragraphStyles.IsInitialized=False Then
		Dim unzipedDirPath As String
		unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
		loadStyles(unzipedDirPath)
	End If
    Log(filename)
	Log(path)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Sleep(0)
		Dim innerfilename As String
		innerfilename=sourceFileMap.GetKeyAt(0)
		Dim innerfileContent As String
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
			innerfileContent=innerfileContent&translation
		Next
		Dim storypath As String
		storypath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
		storypath=File.Combine(File.Combine(storypath,"Stories"),innerfilename)
		Log("storypath"&storypath)
		'Log(innerfileContent)
		File.WriteString(File.Combine(path,"target"),innerfilename,taggedTextToXml(innerfileContent,storypath))
	Next

End Sub


Sub textToListInOrder(pureText As String) As List

	Dim result As List
	result.Initialize
	Dim splitted As List
	splitted.Initialize
	splitted.Addall(Regex.Split(CRLF,pureText))

	For i=0 To splitted.Size-1
		Dim content As String
		content=splitted.Get(i)
		If content<>"" Then
			result.Add(splitted.Get(i))
		End If
		If i<>splitted.Size-1 Then
			result.Add(CRLF)
		End If
		If i=splitted.Size-1 And pureText.EndsWith(CRLF) Then
			result.Add(CRLF)
		End If
	Next

	Return result
End Sub

Sub getStyleIndex(text As String,styleType As String) As Int
	Dim pattern As String
	Select styleType
		Case "character"
			pattern="<c\d+?>"
		Case "paragraph"
			pattern="<p\d+?>"
	End Select
	Log(text)
	Dim styleIndex As String
	Dim indexMatcher As Matcher
	indexMatcher=Regex.Matcher(pattern,text)
	indexMatcher.Find
	styleIndex=indexMatcher.Match
	styleIndex=styleIndex.SubString2(2,styleIndex.Length-1)
	Log("styleindex:"&styleIndex)
	Return styleIndex
End Sub

Sub getXmlMap(xmlstring As String) As Map
	Dim ParsedData As Map
	Dim xm As Xml2Map
	xm.Initialize
	ParsedData = xm.Parse(xmlstring)
	Return ParsedData
End Sub

Sub getXmlFromMap(map1 As Map) As String
	Dim mx As Map2Xml
	mx.Initialize
	Return mx.MapToXml(map1)
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


Sub getStyleList(ParsedData As Map, styleType As String) As List
	Dim result As List
	result.Initialize
	Dim GroupName,styleName As String
	Select styleType
		Case "character"
			GroupName="RootCharacterStyleGroup"
			styleName="CharacterStyle"
		Case "paragraph"
			GroupName="RootParagraphStyleGroup"
			styleName="ParagraphStyle"
	End Select
	Dim root As Map = ParsedData.Get("idPkg:Styles")
	Dim styleGroup As Map = root.Get(GroupName)
	Dim styles As List
	styles=GetElements(styleGroup,styleName)
	For Each style As Map In styles
		Dim attributes As Map
		attributes=style.Get("Attributes")
		Dim name As String
		name=attributes.Get("Self")
		result.Add(name)
	Next
	Return result
End Sub


Sub getBrContentOrder(path As String)
	order.Clear
	parser.Parse(File.OpenInput(path,""),"Parser")
	Log(order)
End Sub


Sub Parser_EndElement (Uri As String, Name As String, Text As StringBuilder)
	If Name="Br" Or Name="Content" Then
		order.Add(Name)
	End If
End Sub



Sub getStoryContent(ParsedData As Map) As String
	
	Dim root As Map = ParsedData.Get("idPkg:Story")
	Dim story As Map = root.Get("Story")
	Dim content As String
	Dim ParagraphStyleRanges As List
	ParagraphStyleRanges=GetElements(story,"ParagraphStyleRange")
	For Each ParagraphStyleRange As Map In ParagraphStyleRanges
		Dim paragraphStyleRangeContent As String
		
		Dim paragraphAttributes As Map
		paragraphAttributes=ParagraphStyleRange.Get("Attributes")

		Dim paragraphStyleIndex As String
		paragraphStyleIndex=paragraphStyles.IndexOf(paragraphAttributes.Get("AppliedParagraphStyle"))
		
		Dim CharacterStyleRanges As List
		CharacterStyleRanges=GetElements(ParagraphStyleRange,"CharacterStyleRange")
		
		For Each CharacterStyleRange As Map In CharacterStyleRanges
			Dim characterStyleRangeContent As String
			
			Dim brcontentInOrder As List
			brcontentInOrder.Initialize

			Dim size As Int
			size=GetElements(CharacterStyleRange,"Br").Size+GetElements(CharacterStyleRange,"Content").Size

			For i=0 To Max(0,size-1)
				If order.Size=0 Then
					Exit
				End If
				If order.Get(i)="Br" Then
					brcontentInOrder.Add(CRLF)
				Else
					brcontentInOrder.Add("Content")
				End If
			Next

			For i=0 To Max(0,size-1)
				If order.Size=0 Then
					Exit
				End If
				order.RemoveAt(0)
			Next
			
			Dim attributes As Map
			attributes=CharacterStyleRange.Get("Attributes")
			Dim characterStyleIndex As String
			characterStyleIndex=characterStyles.IndexOf(attributes.Get("AppliedCharacterStyle"))

			For Each key As String In CharacterStyleRange.Keys

	
				If key="Content" Then
					Dim contentList As List
					contentList=GetElements(CharacterStyleRange,"Content")
					Dim j As Int=0
					Do While j<contentList.Size
						For k=0 To brcontentInOrder.Size-1
							If brcontentInOrder.Get(k)="Content" Then

								Dim oneContent As String=contentList.Get(j)
								brcontentInOrder.Set(k,oneContent)
								j=j+1
							End If
						Next
					Loop

					For Each item As String In brcontentInOrder
						characterStyleRangeContent=characterStyleRangeContent&item
					Next

					
				End If
			Next
			characterStyleRangeContent=characterStyleRangeContent.Replace(" ","") 'replace LSEP
			characterStyleRangeContent="<c"&characterStyleIndex&">"&characterStyleRangeContent&"</c"&characterStyleIndex&">"&CRLF
			paragraphStyleRangeContent=paragraphStyleRangeContent&characterStyleRangeContent&CRLF
		Next
		paragraphStyleRangeContent="<p"&paragraphStyleIndex&">"&paragraphStyleRangeContent&"</p"&paragraphStyleIndex&">"&CRLF
		paragraphStyleRangeContent=mergeSameTags(paragraphStyleRangeContent)
		content=content&paragraphStyleRangeContent
	Next
	'Log(content)
	Return content
End Sub

Sub mergeSameTags(content As String) As String
	Dim new As String=content
	Dim matcher As Matcher
	matcher=Regex.Matcher("</c(\d+)>",content)
	Do While matcher.Find
		new=Regex.Replace("(?s)"&matcher.Match&"\s*<c"&matcher.Group(1)&">",new,"")
	Loop
	Return new
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