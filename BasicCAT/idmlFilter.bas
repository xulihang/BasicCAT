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



Sub createWorkFile(filename As String,path As String,sourceLang As String,sentenceLevel as Boolean) As ResumableSub
	If order.IsInitialized=False Then
		parser.Initialize
		order.Initialize
	End If
	progressDialog.close
	progressDialog.ShowWithoutProgressBar("Loading idml file...","loadfile")
	progressDialog.update2("Unzipping...")
	Sleep(0)
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	wait for (unzipAndLoadIDML(path,filename)) Complete (spreadsList As List)
	
	progressDialog.update2("Loading styles...")
	loadStyles(unzipedDirPath)
	'--------------------------
	Dim storiesList As List
	storiesList.Initialize
	progressDialog.update2("Reading Spreads...")
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
			
			'Log(XY)
		Next
		storiesList.AddALL(leftPageStoriesForSpreadList)
		storiesList.AddALL(rightPageStoriesForSpreadList)
	Next
	'Log(storiesList)
    '--------------------------
	
	
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim sourceFiles As List
	sourceFiles.Initialize

	

	For Each storyID As String In storiesList
		progressDialog.update2("Reading Story_"&storyID&".xml...")
		Sleep(0)
		'Log(storyID)
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
		'Log(storyContent)
		Dim index As Int=-1
		Dim segmentedText As List
		wait for (segmentation.segmentedTxt(storyContent,sentenceLevel,sourceLang,path)) Complete (resultList As List)
		segmentedText=resultList
		For Each source As String In segmentedText
			source=Regex.Replace(" {2,}",source," ")
			
			index=index+1
			Dim bitext As List
			bitext.Initialize
			If source.Trim="" And index<segmentedText.Size-1 Then 'newline or empty space
				inbetweenContent=inbetweenContent&source
				Continue
			Else if Regex.Replace("<.*?>",source,"").Trim="" And index<segmentedText.Size-1 Then ' pure tag maybe with \t \n
				'Log("totalmatch"&source)
				'Log(index)
				'Log(segmentedText.size)
				inbetweenContent=inbetweenContent&source
				Continue
			Else
                Dim sourceShown As String
				sourceShown=idmlUtils.getPureText(source)
				
				inbetweenContent=inbetweenContent&source


				'Log("sourceShown"&sourceShown)
				bitext.add(sourceShown.Trim)
				bitext.Add("")
				bitext.Add(inbetweenContent) 'inbetweenContent contains crlf and spaces between sentences
				bitext.Add(innerFilename)
				Dim extra As Map
				extra.Initialize
				bitext.Add(extra)
				inbetweenContent=""
			End If
			'Log(index)
			'Log(segmentedText.Size-1)
			If index=segmentedText.Size-1 And sourceShown="" And segmentsList.size=0 Then
				'This is a pagenum story
				Continue
			End If
			If index=segmentedText.Size-1 And sourceShown="" And segmentsList.Size>0 Then 'last segment contains tags
				'Log(bitext)
				'Log(segmentsList)
				Dim previousBitext As List
				previousBitext=segmentsList.Get(segmentsList.Size-1)
				previousBitext.Set(0,previousBitext.Get(0)&bitext.Get(0))
				previousBitext.Set(2,previousBitext.Get(2)&bitext.Get(2))
			Else
				segmentsList.Add(bitext)
			End If
			
			
		Next
		
		removeNewLinesBetweenTags(segmentsList)
		mergeSpecialTaggedContentAtBeginning(segmentsList)
		Do While containsInbetweenSpecialTaggedContent(segmentsList)
			''Log(segmentsList)
			mergeInbetweenSpecialTaggedContent(segmentsList)
		Loop
		mergeSpecialTaggedContentInTheEnd(segmentsList)
		replaceNewlinestoHtmlTag(segmentsList)
		
		If segmentsList.Size<>0 Then
			sourceFileMap.Put(innerFilename,segmentsList)
			sourceFiles.Add(sourceFileMap)
		End If

		
	Next
	
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
	progressDialog.close
	'fx.Msgbox(Main.MainForm,"idml file imported","")
	Return True
End Sub

Sub replaceNewlinestoHtmlTag(segmentsList As List)
	For Each bitext As List In segmentsList
		Dim source As String
		source=bitext.Get(0)
		If source.Contains(CRLF) Then
			source=source.Replace(CRLF,"<br/>")
			bitext.Set(0,source)
		End If
	Next
End Sub

Sub removeNewLinesBetweenTags(segmentsList As List)
	For Each bitext As List In segmentsList
		Dim fullSource As String
		fullSource=bitext.Get(2)
		fullSource=Regex.Replace("(?s)(</.*?>)\n{1,}",fullSource,"$1")
		fullSource=Regex.Replace("(?s)\n{1,}(<(?!/).*?>)",fullSource,"$1") ' remove unnecessary \n between tags
		bitext.Set(2,fullSource)
	Next
End Sub

Sub mergeSpecialTaggedContentAtBeginning(segmentsList As List)
	If segmentsList.Size<2 Then
		Return
	End If
	Dim fullsource,nextFullSource As String
	Dim bitext,nextSegment As List
	bitext=segmentsList.Get(0)
	nextSegment=segmentsList.Get(1)
	fullsource=bitext.Get(2)
	'fullsource=Regex.Replace("<p.*?>",fullsource,"")
	'fullsource=Regex.Replace("<c\d+ .*?></c\d+>",fullsource,"")
	nextFullSource=nextSegment.Get(2)

    Dim nextPureText As String
	nextPureText=idmlUtils.getPureTextWithoutTrim(nextFullSource)
	

	If Regex.IsMatch("(?s)<.*?>",fullsource.Trim) Then
		If idmlUtils.containsUnshownSpecialTaggedContent(bitext.Get(0),fullsource) And nextPureText.StartsWith(CRLF)=False Then
			Dim tagMatcher As Matcher
			tagMatcher=Regex.Matcher("<.*?>",nextFullSource)
			If tagMatcher.Find Then
				'Log(tagMatcher.Match)
				If tagMatcher.Match="<c0>" Then
					fullsource=bitext.Get(2)
					bitext.Clear
					Dim sourceShown As String
					Dim nextSourceShown As String
					nextSourceShown=nextSegment.Get(0)
					If Utils.LanguageHasSpace(Main.currentproject.projectFile.Get("source")) And Regex.Matcher("\w",nextSourceShown.Trim.CharAt(0)).Find Then
						Dim pureText,nextPureText As String
						pureText=idmlUtils.getPureTextwithouttrim(fullsource)
						nextPureText=idmlUtils.getPureTextwithouttrim(nextFullSource)
						If Regex.IsMatch("\s",pureText.CharAt(pureText.Length-1)) Or Regex.IsMatch("\s",nextPureText.CharAt(0)) Then
							sourceShown=fullsource.Trim&" "&nextSourceShown
						Else
							sourceShown=fullsource.Trim&nextSourceShown
						End If
						
					Else
						sourceShown=fullsource.Trim&nextSourceShown
					End If
					sourceShown=idmlUtils.getPureText(sourceShown)
					bitext.Add(sourceShown)
					bitext.Add("")
					bitext.Add(fullsource.Trim&nextSegment.Get(2))
					bitext.Add(nextSegment.Get(3))
					Dim extra As Map
					extra.Initialize
					bitext.Add(extra)
					segmentsList.RemoveAt(1)
				End If
			End If
		End If
	End If
End Sub


Sub mergeInbetweenSpecialTaggedContent(segmentsList As List)
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
		Dim previousFullSource,fullsource,nextFullSource As String

		If index-1>=0 And index+1<=duplicatedList.Size-1 Then
			previousSegment=duplicatedList.Get(index-1)
			nextSegment=duplicatedList.Get(index+1)
			previousFullSource=previousSegment.Get(2)
			fullsource=bitext.Get(2)
			nextFullSource=nextSegment.Get(2)

			If merged=False Or index-previousMergedIndex>=3 Then
				If Regex.IsMatch("(?s)<.*?>",fullsource.Trim) Then
					If idmlUtils.containsUnshownSpecialTaggedContent(bitext.Get(0),fullsource) Then
						If previousFullSource.Trim.EndsWith("</c0>") And nextFullSource.Trim.StartsWith("<c0>") Then
							Dim newSegment As List
							newSegment.Initialize
							If Utils.LanguageHasSpace(Main.currentproject.projectFile.Get("source")) Then
								Dim new As String
								Dim previousSourceShown,nextSourceShown As String
								previousSourceShown=previousSegment.Get(0)
								nextSourceShown=nextSegment.Get(0)
								
								Dim previousPureText,pureText,nextPureText As String
								previousPureText=idmlUtils.getPureTextwithouttrim(previousFullSource)
								pureText=idmlUtils.getPureTextwithouttrim(fullsource)
								nextPureText=idmlUtils.getPureTextwithouttrim(nextFullSource)
								
								If Regex.IsMatch("\s",previousPureText.CharAt(previousPureText.Length-1)) Or Regex.IsMatch("\s",pureText.CharAt(0)) Then
									new=previousSourceShown&" "&fullsource.Trim
								Else
									new=previousSourceShown&fullsource.Trim
								End If
								
								If Regex.IsMatch("\s",nextPureText.CharAt(0)) Or Regex.IsMatch("\s",pureText.CharAt(pureText.Length-1)) Then
									new=new&" "&nextSourceShown
								Else
									new=new&nextSourceShown
								End If
								
								'If Regex.Matcher("\w",nextSourceShown.Trim.CharAt(0)).Find Then
								'	new=new&" "&nextSourceShown
								'Else
							    '	new=new&nextSourceShown
								'End If
								
								newSegment.Add(new)
							Else
								newSegment.Add(previousSegment.Get(0)&fullsource.Trim&nextSegment.Get(0))
							End If
					
							newSegment.Add("")
							newSegment.Add(previousSegment.Get(2)&fullsource.Trim&nextSegment.Get(2))
							newSegment.Add(previousSegment.Get(3))
							Dim extra As Map
							extra.Initialize
							newSegment.Add(extra)

							previousMergedIndex=index
							newList.RemoveAt(newList.Size-1)
							newList.Add(newSegment)
							merged=True
						End If
					End If
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

Sub containsInbetweenSpecialTaggedContent(segmentsList As List) As Boolean
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
			If Regex.IsMatch("(?s)<.*?>",fullsource.Trim) Then
				If idmlUtils.containsUnshownSpecialTaggedContent(bitext.Get(0),fullsource) Then
					If previousSource.Trim.EndsWith("</c0>") And nextSource.Trim.StartsWith("<c0>") Then
						Return True
					End If
				End If
			End If
		End If
	Next
	Return False
End Sub

Sub mergeSpecialTaggedContentInTheEnd(segmentsList As List)
	If segmentsList.Size<2 Then
		Return
	End If
	Dim fullsource,previousFullSource As String
	Dim bitext,previousSegment As List
	bitext=segmentsList.Get(segmentsList.Size-1)
	previousSegment=segmentsList.Get(segmentsList.Size-2)
	fullsource=bitext.Get(2)
	previousFullSource=previousSegment.Get(2)
	'fullsource=Regex.Replace("<p.*?>",fullsource,"")
	'fullsource=Regex.Replace("<c\d+ .*?></c\d+>",fullsource,"")
	If Regex.IsMatch("(?s)<.*?>",fullsource.Trim) Then
		If idmlUtils.containsUnshownSpecialTaggedContent(bitext.Get(0),fullsource) Then
			If previousFullSource.Trim.EndsWith("</c0>") Then
				fullsource=bitext.Get(2)
				bitext.Clear
				Dim sourceShown As String
			    Dim previousSourceShown As String
			    previousSourceShown=previousSegment.Get(0)
				If Utils.LanguageHasSpace(Main.currentproject.projectFile.Get("source")) Then
					Dim previousPureText,pureText As String
					previousPureText=idmlUtils.getPureTextwithouttrim(previousFullSource)
					pureText=idmlUtils.getPureTextwithouttrim(fullsource)

					If Regex.IsMatch("\s",previousPureText.CharAt(previousPureText.Length-1)) Or Regex.IsMatch("\s",pureText.CharAt(0)) Then
						sourceShown=previousSourceShown&" "&fullsource.Trim
					Else
						sourceShown=previousSourceShown&fullsource.Trim
					End If
					
				Else
					sourceShown=previousSourceShown&fullsource.Trim
				End If
				sourceShown=idmlUtils.getPureText(sourceShown)
				bitext.Add(sourceShown)
				bitext.Add("")
			    bitext.Add(previousSegment.Get(2)&fullsource.Trim)
			    bitext.Add(previousSegment.Get(3))
				Dim extra As Map
				extra.Initialize
				bitext.Add(extra)
			    segmentsList.RemoveAt(segmentsList.Size-2)
			End If
		End If
	End If
End Sub


Sub unzipAndLoadIDML(path As String,filename As String) As ResumableSub
	Dim spreadsList As List
	spreadsList.Initialize
	
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	'Log(File.Combine(File.Combine(path,"source"),filename.Replace(".idml","")))
	File.MakeDir(File.Combine(path,"source"),filename.Replace(".idml",""))
	
	'Log(unzipedDirPath)
	
	'Dim archiver As Archiver
	'archiver.AsyncUnZip(File.Combine(path,"source"),filename,unzipedDirPath,"archiver")
	'wait for archiver_UnZipDone(CompletedWithoutError As Boolean, NbOfFiles As Int)
	'Log(CompletedWithoutError)
	Dim zip As zip4j
	zip.Initialize
	wait for (zip.unzipAsync(File.Combine(path,"source"),filename,unzipedDirPath)) Complete (success As Boolean)
	
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

Sub taggedTextToXml(taggedText As String,storypath As String) As String
	'Log("storypath"&storypath)
	Dim storyMap As Map
	storyMap=getXmlMap(File.ReadString(storypath,""))
	Dim root As Map = storyMap.Get("idPkg:Story")
	Dim story As Map = root.Get("Story")
	Dim ParagraphStyleRanges As List
	ParagraphStyleRanges=GetElements(story,"ParagraphStyleRange")

	Dim matcher As Matcher
	matcher=Regex.Matcher("(?s)<p\d+>.*?</p\d+>",taggedText)
	Dim paragraphsTextList As List
	paragraphsTextList.Initialize
	
	Do While matcher.Find
		paragraphsTextList.Add(matcher.Match)
	Loop
	'Log("paragraphsTextList"&paragraphsTextList)
	
	Dim index As Int=0
	For Each paragraphText As String In paragraphsTextList
		'Log(paragraphText)
		Dim paragraphMap As Map
		paragraphMap.Initialize
		paragraphMap=ParagraphStyleRanges.Get(index)
		index=index+1
		Dim originalCharacterStyleRanges As List
		originalCharacterStyleRanges.Initialize
		originalCharacterStyleRanges=GetElements(paragraphMap,"CharacterStyleRange")
		
		Do While paragraphMap.ContainsKey("CharacterStyleRange")
			paragraphMap.Remove("CharacterStyleRange")
		Loop
		Dim matcher2 As Matcher
		matcher2=Regex.Matcher("(?s)<c\d+.*?>.*?</c\d+>",paragraphText)
		Dim characterMapsList As List
		characterMapsList.Initialize

		Dim characterTextList As List
		characterTextList.Initialize
		Do While matcher2.Find
			characterTextList.Add(matcher2.Match)
		Loop
		'Log(characterTextList)
		For Each characterText As String In characterTextList
			''Log(characterText)
			Dim styleIndex As String
			styleIndex=getStyleIndex(characterText,"character")
			Dim pureText As String=characterText
			Dim tagMatcher As Matcher
			tagMatcher=Regex.Matcher("<.*?>",characterText)
			Do While tagMatcher.Find
				pureText=pureText.Replace(tagMatcher.Match,"")
			Loop
			''Log(styleIndex)
			'Log(pureText)


			Dim list1 As List
			list1=textToListInOrder(pureText)
			
			Dim characterMap As Map
			
			Dim styleRankMatcher As Matcher
			styleRankMatcher=Regex.Matcher($"id="(\d+)""$,characterText)
			If styleRankMatcher.Find Then
				'Log("originalCharacterStyleRanges"&originalCharacterStyleRanges)
				
				Try

					characterMap=originalCharacterStyleRanges.Get(styleRankMatcher.Group(1))
					Dim targetLang As String
					targetLang=Main.currentProject.projectFile.Get("target")
					If targetLang.StartsWith("zh") Then
						idmlUtils.changeFontsFromEnToZh(characterMap)
					End If
					
					Log(characterMap)
					If characterMap.ContainsKey("Br") Then
						characterMap.Remove("Br")
					End If
					If characterMap.ContainsKey("Text") Then
						characterMap.Remove("Text")
					End If
					If characterMap.ContainsKey("Content") Then
						characterMap.Remove("Content")
					End If
				Catch
					characterMap=CreateMap("Attributes":CreateMap("AppliedCharacterStyle":characterStyles.Get(styleIndex)),"Content":list1)
					'Log(LastException)
				End Try
				characterMap.Put("Content",list1)
				
			Else
				characterMap=CreateMap("Attributes":CreateMap("AppliedCharacterStyle":characterStyles.Get(styleIndex)),"Content":list1)
			End If
			
			characterMapsList.Add(characterMap)
			
		Next
		paragraphMap.Put("CharacterStyleRange",characterMapsList)
		If paragraphMap.ContainsKey("Text")  Then
			If paragraphMap.Get("Text")="" Then
				paragraphMap.Remove("Text")
			End If
			
		End If
		
		'Log(paragraphMap)
	Next

	story.Put("ParagraphStyleRange",ParagraphStyleRanges)

	Dim result As String
	result=getXmlFromMap(storyMap)
	result=result.Replace("<Content>"&Chr(13) & Chr(10) &"</Content>","<Br />") ' for windows
	result=result.Replace("<Content>"&CRLF&"</Content>","<Br />") ' for mac/linux
	Return result
End Sub



Sub generateFile(filename As String,path As String,projectFile As Map)
	progressDialog.ShowWithoutProgressBar("Building idml file...","buildidml")
	
	Dim unzipedDirPath As String
	unzipedDirPath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
	If paragraphStyles.IsInitialized=False Then
		loadStyles(unzipedDirPath)
	End If
	Dim targetLang As String
	targetLang=projectFile.Get("target")
	If targetLang.StartsWith("zh") Then
		replaceStyleAndFontFileForZh(unzipedDirPath)
	End If

	If File.Exists(File.Combine(path,"target"),"Stories")=False Then
		File.MakeDir(File.Combine(path,"target"),"Stories")
	End If


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
		
		progressDialog.update2("Generating "&innerfilename&"...")
		
		Dim innerfileContent As String
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerfilename)
        Dim index As Int=-1
		For Each bitext As List In segmentsList
			index=index+1
			Dim source,target,fullsource,translation As String
			source=bitext.Get(0)
			target=bitext.Get(1)
			fullsource=bitext.Get(2)

			'Log(source)
			'Log(target)
			'Log(fullsource)
			If target="" Then
				translation=fullsource
			Else
				'Dim pp As String
				'pp=source
				source=source.Replace("<br/>",CRLF)
				target=target.Replace("<br/>",CRLF)
				If shouldAddSpace(projectFile.Get("source"),projectFile.Get("target"),index,segmentsList) Then
					target=target&" "
				End If
				If fullsource.Contains(C0TagAddedText(source,fullsource)) And idmlUtils.containsUnshownSpecialTaggedContent(target,source)=False Then
					translation=fullsource.Replace(C0TagAddedText(source,fullsource),C0TagAddedText(target,fullsource))

				Else
					'tags not match, remove tags
					If idmlUtils.containsUnshownC0Tag(source,fullsource) Then
						source=C0TagAddedText(source,fullsource)
					End If
					Dim tagReplaceMatcher As Matcher
					tagReplaceMatcher=Regex.Matcher2("<.*?>",32,target)
					Do While tagReplaceMatcher.Find
						target=target.Replace(tagReplaceMatcher.Match,"")
					Loop
						
					'If Regex.Matcher2("</c0><c\d+",32,fullsource).Find And Regex.Matcher2("</c\d+><c0>",32,fullsource).Find Then
						
					'Else
					target=addNecessaryTags(target,fullsource)
					'End If
					
                    
					translation=fullsource.Replace(source,target)

				End If

				'If pp.StartsWith("<c0><br/></c0><c4>Ca") Then
				'	Log(source)
				'	Log(target)
				'	Log(fullsource)
				'	Log(translation)
					'ExitApplication
				'End If
				If Utils.LanguageHasSpace(projectFile.Get("target"))=False Then
					translation=segmentation.removeSpacesAtBothSides(Main.currentProject.path,Main.currentProject.projectFile.Get("target"),translation,Utils.getMap("settings",projectFile).GetDefault("remove_space",True))
				End If


			End If
			

			
			Dim extra As Map
			extra=bitext.Get(4)
			If extra.ContainsKey("neglected") Then
				If extra.get("neglected")="yes" Then
					translation=fullsource.Replace(C0TagAddedText(source,fullsource),"")
				End If
			End If
			
			innerfileContent=innerfileContent&translation
		Next

		Dim storypath As String
		storypath=File.Combine(File.Combine(path,"source"),filename.Replace(".idml",""))
		storypath=File.Combine(File.Combine(storypath,"Stories"),innerfilename)
		'Log("storypath"&storypath)
		''Log(innerfileContent)
		File.WriteString(File.Combine(File.Combine(path,"target"),"Stories"),innerfilename,taggedTextToXml(innerfileContent,storypath))
	Next
	progressDialog.update2("Zipping...")
	zipIDML(unzipedDirPath,filename,path)
End Sub


Sub shouldAddSpace(sourceLang As String,targetLang As String,index As Int,segmentsList As List) As Boolean
	Dim bitext As List=segmentsList.Get(index)
	Dim fullsource As String=bitext.Get(2)
	fullsource=Utils.getPureTextWithoutTrim(fullsource)
	If Utils.LanguageHasSpace(sourceLang)=False And Utils.LanguageHasSpace(targetLang)=True Then
		If index+1<=segmentsList.Size-1 Then
			Dim nextBitext As List
			nextBitext=segmentsList.Get(index+1)
			Dim nextfullsource As String=nextBitext.Get(2)
			nextfullsource=Utils.getPureTextWithoutTrim(nextfullsource)
			Try
				If Regex.IsMatch("\s",nextfullsource.CharAt(0))=False And Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1))=False Then
					Return True
				End If
			Catch
				Log(LastException)
			End Try
		End If
	End If
	Return False
End Sub

Sub zipIDML(unzipedDirPath As String,filename As String,path As String)
    If File.Exists(File.Combine(path,"target"),filename) Then
		File.Delete(File.Combine(path,"target"),filename)
	End If
	Dim zipDirPath As String
	zipDirPath=File.Combine(File.Combine(path,"target"),filename.Replace(".idml",""))
	wait for (Utils.CopyFolderAsync(unzipedDirPath,zipDirPath)) Complete (result As Object)
	
	wait for (Utils.CopyFolderAsync(File.Combine(File.Combine(path,"target"),"Stories"),File.Combine(zipDirPath,"Stories"))) Complete (result As Object)
	
    Dim zip As zip4j
	zip.Initialize
	wait for (zip.zipFilesAsync(zipDirPath,File.Combine(path,"target"),filename)) complete (result As Object)
	File.Delete(File.Combine(path,"target"),"Stories")
	File.Delete(File.Combine(path,"target"),filename.Replace(".idml",""))
	progressDialog.close
	Main.updateOperation(filename&" generated!")
End Sub


Sub C0TagAddedText(text As String,fullsource As String) As String
	Dim matcher As Matcher
	matcher=Regex.Matcher2("<c[1-9].*?>.*?</c[1-9].*?>|<c0 id=.*?>.*?</c0>",32,text)

	Dim textForMatch As String
	textForMatch=text
	Do While matcher.Find
		Log("match"&matcher.Match)
		Dim before,mid,after As String
		before=text.SubString2(0,text.IndexOf(matcher.Match))
		mid=matcher.Match
		Log("mid"&mid)
		
	    If Regex.Matcher2("</c0><c\d+",32,fullsource).Find Then
			If Regex.Matcher2("</c0><c\d+",32,textForMatch).Find=False Then
				mid="</c0>"&mid
			End If
		End If
		If Regex.Matcher2("</c\d+><c0>",32,fullsource).Find Then
			If Regex.Matcher2("</c\d+><c0>",32,textForMatch).Find=False Then
				mid=mid&"<c0>"
			End If
			
		End If
		after=text.SubString2(text.IndexOf(matcher.Match)+matcher.Match.Length,text.Length)
		text=before&mid&after
		textForMatch=after
		Log("text"&text)
	Loop
	Return text
End Sub


Sub addNecessaryTags(target As String,fullsource As String) As String
	'source=Regex.Replace2("<c[1-9].*?>.*?</c[1-9].*?>|<c0 id=.*?>.*?</c0>",32,source,"")
	
	target="<c0>"&target&"</c0>"
	
	
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("</*c.*?>",32,fullsource)
	Dim tagList As List
	tagList.Initialize
	Do While tagMatcher.Find
		tagList.Add(tagMatcher.Match)
	Loop
	
    If tagList.Size=0 Then
		Return target
    End If
	
	If Regex.IsMatch("</c.*?>",tagList.Get(0)) Then
		target=tagList.Get(0)&target
	End If
	
	If Regex.IsMatch("<c.*?>",tagList.Get(tagList.Size-1)) Then
		target=target&tagList.Get(tagList.Size-1)
	End If
	
	'Dim matcher1 As Matcher
	'matcher1=Regex.Matcher2(".*?(</c\d+>)",32,source)
	'If matcher1.Find Then
	'	target=matcher1.Group(1)&target
	'End If
	
	'Dim matcher2 As Matcher
	'matcher2=Regex.Matcher2("(<c\d+>).*?",32,source)
	'If matcher2.Find Then
	'	target=target&matcher2.Group(1)
	'Else
	'End If

	Return target
End Sub

Sub replaceStyleAndFontFileForZh(unzipedDirPath As String)
	Dim stylexml As String
	stylexml=File.ReadString(File.Combine(unzipedDirPath,"Resources"),"Styles.xml")
	Dim styleMap As Map
	styleMap=getXmlMap(stylexml)
	idmlUtils.changeFontsFromEnToZhOfStyleFile(styleMap)
	stylexml=getXmlFromMap(styleMap)
	File.WriteString(File.Combine(unzipedDirPath,"Resources"),"Styles.xml",stylexml)
	File.Copy(File.DirAssets,"Fonts.xml",File.Combine(unzipedDirPath,"Resources"),"Fonts.xml")
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
	If result.Size=0 And Regex.IsMatch("\s",pureText) Then
		result.Add(pureText)
	End If
	Return result
End Sub

Sub getStyleIndex(text As String,styleType As String) As Int
	Dim pattern As String
	Select styleType
		Case "character"
			pattern="<c(\d+).*?>"
		Case "paragraph"
			pattern="<p(\d+).*?>"
	End Select
	'Log(text)
	Dim styleIndex As String
	Dim indexMatcher As Matcher
	indexMatcher=Regex.Matcher(pattern,text)
	indexMatcher.Find
	styleIndex=indexMatcher.Group(1)
	'Log("styleindex:"&styleIndex)
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
	'Log(order)
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
		
		Dim characterStyleRank As Int=-1
		For Each CharacterStyleRange As Map In CharacterStyleRanges
			characterStyleRank=characterStyleRank+1
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



					
				End If
			Next
			For Each item As String In brcontentInOrder
				characterStyleRangeContent=characterStyleRangeContent&item
			Next
			characterStyleRangeContent=characterStyleRangeContent.Replace(" ","") 'replace LSEP
			If attributes.Size>1 Then
				characterStyleRangeContent="<c"&characterStyleIndex&" id="&Chr(34)&characterStyleRank&Chr(34)&">"&characterStyleRangeContent&"</c"&characterStyleIndex&">"&CRLF
			Else
				characterStyleRangeContent="<c"&characterStyleIndex&">"&characterStyleRangeContent&"</c"&characterStyleIndex&">"&CRLF
			End If
			
			paragraphStyleRangeContent=paragraphStyleRangeContent&characterStyleRangeContent&CRLF
		Next
		paragraphStyleRangeContent=idmlUtils.mergeInWordPartForparaStyleRange(paragraphStyleRangeContent)
		
		paragraphStyleRangeContent="<p"&paragraphStyleIndex&">"&paragraphStyleRangeContent&"</p"&paragraphStyleIndex&">"&CRLF
		'paragraphStyleRangeContent=mergeSameTags(paragraphStyleRangeContent)
		content=content&paragraphStyleRangeContent
	Next
	''Log(content)
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
		'Log(storyID)
		If storyIDList.IndexOf(storyID)=-1 Then
			newList.Add(TextFrame)
			storyIDList.Add(storyID)
		End If
	Next
	Return newList

End Sub


Sub mergeSegment(sourceTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.Items.IndexOf(sourceTextArea.Parent)
	If index+1>Main.currentProject.segments.Size-1 Then
		Return
	End If
	Dim bitext,nextBiText As List
	bitext=Main.currentProject.segments.Get(index)
	nextBiText=Main.currentProject.segments.Get(index+1)
		
	If bitext.Get(3)<>nextBiText.Get(3) Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
	
	Dim source,nextSource As String
	source=bitext.Get(0)
	nextSource=nextBiText.Get(0)
	
	Dim fullsource,nextFullsource As String
	fullsource=bitext.Get(2)
	nextFullsource=nextBiText.Get(2)
	
	Dim showTag As Boolean=False
	If fullsource.Trim.EndsWith(">")=True Or nextFullsource.trim.StartsWith("<")=True Then
		Dim result As Int
		result=fx.Msgbox2(Main.MainForm,"Segments contain unshown tags, continue?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
		Log(result)
		'yes -1, no -2, cancel -3
		Select result
			Case -1
				showTag=True
			Case -2
				Return
			Case -3
				Return
		End Select

	End If
		
	Dim pane,nextPane As Pane

	pane=Main.editorLV.Items.Get(index)
	nextPane=Main.editorLV.Items.Get(index+1)
	Dim targetTa,nextSourceTa,nextTargetTa As TextArea
	nextSourceTa=nextPane.GetNode(0)
	nextTargetTa=nextPane.GetNode(1)
		
	Dim sourceWhitespace,targetWhitespace,fullsourceWhitespace As String
	sourceWhitespace=""
	targetWhitespace=""
	fullsourceWhitespace=""
	
	Dim pureText,nextPureText As String
	pureText=idmlUtils.getPureTextWithoutTrim(fullsource)
	nextPureText=idmlUtils.getPureTextWithoutTrim(nextFullsource)
	Dim sourceLang,targetLang As String
	sourceLang=Main.currentProject.projectFile.Get("source")
	targetLang=Main.currentProject.projectFile.Get("target")
	If Utils.LanguageHasSpace(sourceLang) Then
		If Regex.IsMatch("\s",pureText.CharAt(pureText.Length-1)) Or Regex.IsMatch("\s",nextPureText.CharAt(0)) Then
			sourceWhitespace=" "
		Else
			sourceWhitespace=""
		End If
		'If Regex.IsMatch("\w",sourceTextArea.Text.CharAt(sourceTextArea.Text.Length-1)) Or Regex.IsMatch("\w",nextSourceTa.Text.CharAt(0)) Then
		'	sourceWhitespace=" "
		'Else
		'	sourceWhitespace=""
		'End If
	End If
	If Utils.LanguageHasSpace(targetLang) Then
		targetWhitespace=" "
	End If

	If Utils.LanguageHasSpace(sourceLang) Then
		If Regex.IsMatch("\s",pureText.CharAt(pureText.Length-1)) Or Regex.IsMatch("\s",nextPureText.CharAt(0)) Then
			fullsourceWhitespace=" "
		End If
	End If
	

	If showTag Then
		source=fullsource&nextFullsource
		source=source.Replace(CRLF,"<br/>")
		source=Regex.Replace("</*p\d+>",source,"")
		fullsource=fullsource&nextFullsource
	Else
		source=source.Trim&sourceWhitespace&nextSourceTa.Text.Trim
		fullsource=Utils.rightTrim(fullsource)&fullsourceWhitespace&Utils.leftTrim(nextFullsource)
	End If
	
	sourceTextArea.Text=source
	sourceTextArea.Tag=source
		
	targetTa=pane.GetNode(1)
	targetTa.Text=targetTa.Text&targetWhitespace&nextTargetTa.Text


	bitext.Set(0,source)
	bitext.Set(1,targetTa.Text)
	
	bitext.Set(2,fullsource)

		
	Main.currentProject.segments.RemoveAt(index+1)
	Main.editorLV.Items.RemoveAt(Main.editorLV.Items.IndexOf(sourceTextArea.Parent)+1)
End Sub


Sub splitSegment(sourceTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.Items.IndexOf(sourceTextArea.Parent)
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
	bitext.Set(2,fullsource.SubString2(0,fullsource.IndexOf(sourceTextArea.Text)+sourceTextArea.Text.Length))
	
	
	newBiText.Initialize
	newBiText.Add(source)
	newBiText.Add("")
	newBiText.Add(fullsource.SubString2(fullsource.IndexOf(sourceTextArea.Text)+sourceTextArea.Text.Length,fullsource.Length))
	newBiText.Add(bitext.Get(3))
	newBiText.Add(bitext.Get(4))
	Main.currentProject.segments.set(index,bitext)
	Main.currentProject.segments.InsertAt(index+1,newBiText)


	Main.editorLV.Items.InsertAt(Main.editorLV.Items.IndexOf(sourceTextArea.Parent)+1,newSegmentPane)
End Sub


Sub previewText As String
	Dim text As StringBuilder
	text.Initialize
	If Main.editorLV.Items.Size<>Main.currentProject.segments.Size Then
		Return ""
	End If
	Dim previousStory as String
	For i=Max(0,Main.currentProject.lastEntry-3) To Min(Main.currentProject.lastEntry+7,Main.currentProject.segments.Size-1)
		Try
			Dim p As Pane
			p=Main.editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try

		Dim sourceTextArea As TextArea
		Dim targetTextArea As TextArea
		sourceTextArea=p.GetNode(0)
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=Main.currentProject.segments.Get(i)
		
		Dim source,target,fullsource,translation As String
		source=sourceTextArea.Text
		target=targetTextArea.Text
		fullsource=bitext.Get(2)

		If target="" Or target=source Then
			translation=fullsource
		Else
			source=source.Replace("<br/>",CRLF)
			target=target.Replace("<br/>",CRLF)
			If shouldAddSpace(Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),i,Main.currentProject.segments) Then
				target=target&" "
			End If
			If fullsource.Contains(C0TagAddedText(source,fullsource)) And idmlUtils.containsUnshownSpecialTaggedContent(target,source)=False Then
				translation=fullsource.Replace(C0TagAddedText(source,fullsource),C0TagAddedText(target,fullsource))
			Else
				'tags not match, remove tags
				If idmlUtils.containsUnshownC0Tag(source,fullsource) Then
					source=C0TagAddedText(source,fullsource)
				End If
				Dim tagReplaceMatcher As Matcher
				tagReplaceMatcher=Regex.Matcher2("<.*?>",32,target)
				Do While tagReplaceMatcher.Find
					target=target.Replace(tagReplaceMatcher.Match,"")
				Loop
				target=addNecessaryTags(target,fullsource)
				translation=fullsource.Replace(source,target)
			End If


			If Utils.LanguageHasSpace(Main.currentProject.projectFile.Get("target"))=False Then
				translation=segmentation.removeSpacesAtBothSides(Main.currentProject.path,Main.currentProject.projectFile.Get("target"),translation,Utils.getMap("settings",Main.currentProject.projectFile).GetDefault("remove_space",True))
			End If
		End If
		Dim story As String=bitext.Get(3)
		If previousStory<>story Then
			text.Append(CRLF)
			previousStory=story
		End If
		If i=Main.currentProject.lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		'text=text&translation
		text.Append(translation)
	Next
	Return text.ToString
End Sub