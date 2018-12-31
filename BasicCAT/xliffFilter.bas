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

Sub createWorkFile(filename As String,path As String,sourceLang As String)
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	Dim isSegEnabled As Boolean
	Dim sourceFiles As List
	sourceFiles.Initialize
	
	Dim files As List
	Dim xmlstring As String
	xmlstring=XMLUtils.escapedText(File.ReadString(File.Combine(path,"source"),filename),"source","xliff")
	xmlstring=XMLUtils.escapedText(File.ReadString(File.Combine(path,"source"),filename),"mrk","xliff")
	

	
	files=getFilesList(xmlstring)
	
	For Each fileMap As Map In files
		Try
			Dim body As Map
			body=fileMap.Get("body")
		Catch
			Continue
		End Try
		Dim sourceFileMap As Map
		sourceFileMap.Initialize
		Dim segmentsList As List
		segmentsList.Initialize
		Dim attributes As Map
		attributes=fileMap.Get("Attributes")
		Dim innerfileName As String
		innerfileName=attributes.Get("original")
		
		
		For Each tu As List In getTransUnits(fileMap)
			Dim inbetweenContent As String=""
			Dim text As String
			text=tu.Get(0)
			Dim id As String
			id=tu.Get(1)
			Dim index As Int=-1
			Dim segmentedText As List
			Dim mrkList As List
			mrkList=tu.Get(2)


			If mrkList.Size<>0 Then
				isSegEnabled=True
				segmentedText=getSegmentedSourceList(mrkList)
			Else
				isSegEnabled=False
				segmentedText=segmentation.segmentedTxt(text,False,sourceLang,path)
			End If

			For Each source As String In segmentedText
				Log("source"&source)
				index=index+1
				Dim bitext As List
				bitext.Initialize
				If source.Trim="" And index<>segmentedText.Size-1 And isSegEnabled=False Then 'newline or empty space
					inbetweenContent=inbetweenContent&source
					Continue
				else if filterGenericUtils.tagsRemovedText(source).Trim="" And index<>segmentedText.Size-1 And isSegEnabled=False Then
					inbetweenContent=inbetweenContent&source
					Continue
				Else
					Dim sourceShown As String=source
					If filterGenericUtils.tagsNum(sourceShown)=1 Then
						sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
					End If
					If filterGenericUtils.tagsNum(sourceShown)=2 And Regex.IsMatch("<.*?>",sourceShown) Then
						sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
					End If

					bitext.add(sourceShown.Trim)
					bitext.Add("")
					bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
					bitext.Add(innerfileName)
					Dim extra As Map
					extra.Initialize
					extra.Put("id",id)
					
					bitext.Add(extra)
					inbetweenContent=""

				End If
				If index=segmentedText.Size-1 And filterGenericUtils.tagsRemovedText(sourceShown).Trim="" And segmentsList.Size>0 And isSegEnabled=False Then 'last segment contains tags but no text
					Dim previousBitext As List
					previousBitext=segmentsList.Get(segmentsList.Size-1) 
					Dim previousExtra As Map
					previousExtra=previousBitext.Get(4) 'segments is at file level not trans-unit level, so needs verification
					If previousExtra.Get("id")=id Then
						Dim sourceShown As String
						sourceShown=previousBitext.Get(0)&source.Trim
						If filterGenericUtils.tagsNum(sourceShown)=1 Then
							sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
						End If
						If filterGenericUtils.tagsNum(sourceShown)=2 And Regex.IsMatch("<.*?>",sourceShown) Then
							sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
						End If
						previousBitext.Set(0,sourceShown)
						previousBitext.Set(2,previousBitext.Get(2)&bitext.Get(2))
						inbetweenContent=""
					End If
				Else if segmentsList.Size=0 And filterGenericUtils.tagsRemovedText(sourceShown).trim="" Then
					Continue
				Else
					segmentsList.Add(bitext)
				End If
				
			Next
		Next
		If segmentsList.Size<>0 Then
			sourceFileMap.Put(innerfileName,segmentsList)
			sourceFiles.Add(sourceFileMap)
		End If
	Next

	workfile.Put("files",sourceFiles)
	workfile.Put("seg_enabled",isSegEnabled)
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub getSegmentedSourceList(mrkList As List) As List
	Dim segmentedSourceList As List
	segmentedSourceList.Initialize
	For Each mrk As Map In mrkList
		'Dim attributes As Map
		'attributes=mrk.Get("Attributes")
		'Dim mid As Int
		'mid=attributes.Get("mid")
		Dim text As String
		text=mrk.Get("Text")
		segmentedSourceList.Add(text)
	Next
	Return segmentedSourceList
End Sub

Sub getTransUnits(fileMap As Map) As List
	Dim body As Map
	body=fileMap.Get("body")
	Dim tidyTransUnits As List
	tidyTransUnits.Initialize
	Dim transUnits As List
	transUnits=XMLUtils.GetElements(body,"trans-unit")
	For Each transUnit As Map In transUnits
		Log(transUnit)
		Dim attributes As Map
		attributes=transUnit.Get("Attributes")
		Dim id As String
		id=attributes.Get("id")
		Try
			Dim source As Map
			source=transUnit.Get("source")
			Dim text As String
			text=source.Get("Text")
		Catch
			Log(LastException)
			Dim text As String
			text=transUnit.Get("source")
		End Try
		Dim segSource As Map
		segSource.Initialize
		Dim mrkList As List
		mrkList.Initialize
		If transUnit.ContainsKey("seg-source") Then
			segSource=transUnit.Get("seg-source")
			mrkList=XMLUtils.GetElements(segSource,"mrk")
		End If
		
		Dim oneTransUnit As List
		oneTransUnit.Initialize
		oneTransUnit.Add(text)
		oneTransUnit.Add(id)
		oneTransUnit.Add(mrkList)
		tidyTransUnits.Add(oneTransUnit)
	Next
	Return tidyTransUnits
End Sub

Sub getFilesList(xmlstring As String) As List
	Log("read")
	Dim xmlMap As Map
	xmlMap=XMLUtils.getXmlMap(xmlstring)
	Log(xmlMap)
	Dim xliffMap As Map
	xliffMap=xmlMap.Get("xliff")
	Return XMLUtils.GetElements(xliffMap,"file")
End Sub


Sub generateFile(filename As String,path As String,projectFile As Map)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim isSegEnabled As Boolean=workfile.GetDefault("seg_enabled",False)
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	Dim translationMap As Map
	translationMap.Initialize
	For Each sourceFileMap As Map In sourceFiles
		Dim innerfilename As String
		innerfilename=sourceFileMap.GetKeyAt(0)
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
				If shouldAddSpace(projectFile.Get("source"),projectFile.Get("target"),index,segmentsList) Then
					target=target&" "
				End If
				target=addNecessaryTags(target,source)
				translation=fullsource.Replace(source,target)
				If Utils.LanguageHasSpace(projectFile.Get("target"))=False Then
					translation=segmentation.removeSpacesAtBothSides(Main.currentProject.path,Main.currentProject.projectFile.Get("target"),translation,Utils.getMap("settings",projectFile).GetDefault("remove_space",True))
				End If
			End If
			Dim extra As Map
			extra=bitext.Get(4)
			If extra.ContainsKey("neglected") Then
				If extra.get("neglected")="yes" Then
					translation=fullsource.Replace(source,"")
				End If
			End If
            
			Dim segmentKey As String
			segmentKey=extra.Get("id")&bitext.Get(3)

			If translationMap.ContainsKey(segmentKey) Then

				Dim dataMap As Map
				dataMap=translationMap.Get(segmentKey)
				Dim segList As List
				segList=dataMap.Get("seg") 'get previous
				If isSegEnabled Then
					Dim bitext As List
					bitext.Initialize
					bitext.Add(fullsource)
					bitext.Add(translation)
					segList.Add(bitext)
				End If

				translation=dataMap.Get("translation")&translation
				translationMap.put(segmentKey,CreateMap("translation":translation,"filename":innerfilename,"seg":segList))
			Else
				Dim segList As List
				segList.Initialize 'init
				If isSegEnabled Then
					Dim bitext As List
					bitext.Initialize
					bitext.Add(fullsource)
					bitext.Add(translation)
					segList.Add(bitext)
				End If
				
				translationMap.put(segmentKey,CreateMap("translation":translation,"filename":innerfilename,"seg":segList))
			End If
		Next
	Next
	Dim xmlString As String
	xmlString=XMLUtils.getXmlFromMapWithoutIndent(insertTranslation(translationMap,filename,path,isSegEnabled))
	xmlString=XMLUtils.unescapedText(xmlString,"source","xliff")
	xmlString=XMLUtils.unescapedText(xmlString,"target","xliff")
	xmlString=XMLUtils.unescapedText(xmlString,"mrk","xliff")
	Log(xmlString)
	File.WriteString(File.Combine(path,"target"),filename,xmlString)
	Main.updateOperation(filename&" generated!")
End Sub

Sub checkSegContinuous(xmlstring As String) As Boolean
	Dim firstMID0Index As Int=xmlstring.IndexOf($"mid="0""$)
	If firstMID0Index=-1 Then
		Return True
	Else
		Return False
	End If
End Sub

Sub insertTranslation(translationMap As Map,filename As String,path As String,isSegEnabled As Boolean) As Map
	Dim xmlstring As String
	xmlstring=File.ReadString(File.Combine(path,"source"),filename)
	xmlstring=XMLUtils.escapedText(xmlstring,"source","xliff")
	xmlstring=XMLUtils.escapedText(xmlstring,"target","xliff")
	xmlstring=XMLUtils.escapedText(xmlstring,"mrk","xliff")
	'Log("xml"&xmlstring)
	Dim isSegContinuous As Boolean=False
	isSegContinuous=checkSegContinuous(xmlstring)
	Log("iscontinuous"&isSegContinuous)
	Dim xmlMap As Map
	xmlMap=XMLUtils.getXmlMap(xmlstring)
	'Log("map"&xmlMap)
	Dim xliffMap As Map
	xliffMap=xmlMap.Get("xliff")
	Dim filesList As List
	filesList=XMLUtils.GetElements(xliffMap,"file")
	Dim addedMid As Int=1
	For Each innerFile As Map In filesList
		Dim body As Map
		Try
			body=innerFile.Get("body")
		Catch
			Log(LastException)
			Continue
		End Try
		Dim fileAttributes As Map
		fileAttributes=innerFile.Get("Attributes")
		Dim originalFilename As String
		originalFilename=fileAttributes.Get("original")
		Dim transUnits As List
		transUnits=XMLUtils.GetElements(body,"trans-unit")
		For Each transUnit As Map In transUnits
			Dim attributes As Map
			attributes=transUnit.Get("Attributes")
			'Dim segSource As Map
			'If transUnit.ContainsKey("seg-source") Then
			'	segSource=transUnit.Get("seg-source")	
			'End If
			Dim id As String
			id=attributes.Get("id")
			Log(transUnit)
			Dim targetType As String="Map"
			If transUnit.ContainsKey("target")=False Then
				transUnit.Put("target","")
				targetType="String"
			Else
				Try
					Dim targetMap As Map
					targetMap=transUnit.Get("target")
				Catch
					Log(LastException)
					targetType="String"
				End Try
			End If
            Dim segmentKey As String
			segmentKey=id&originalFilename
			If translationMap.ContainsKey(segmentKey) Then
				Dim dataMap As Map
				dataMap=translationMap.Get(segmentKey)
				Dim segList As List
				segList=dataMap.Get("seg")
				If originalFilename=dataMap.Get("filename") Then
					If targetType="Map" Then
						For Each key As String In targetMap.Keys
							If key<>"Attributes" Then
								targetMap.Remove(key)
							End If
						Next
						Dim bitext As List
						If isSegEnabled Then
							If segList.Size=1 Then
								bitext=segList.Get(0)
								If isSegContinuous Then
									'segSource.Put("mrk",buildMrk(addedMid,bitext.Get(0)))
									targetMap.Put("mrk",buildMrk(addedMid,bitext.Get(1)))
									addedMid=addedMid+1
								Else
									'segSource.Put("mrk",buildMrk(0,bitext.Get(0)))
									targetMap.Put("mrk",buildMrk(0,bitext.Get(1)))
								End If
							Else
								Dim mrkList As List
								mrkList.Initialize
								'Dim sourceMrkList As List
								'sourceMrkList.Initialize
								Dim mid As Int=0

								For Each bitext As List In segList
									If isSegContinuous Then
										'sourceMrkList.Add(buildMrk(addedMid,bitext.Get(0)))
										mrkList.Add(buildMrk(addedMid,bitext.Get(1)))
										addedMid=addedMid+1
									Else
										'sourceMrkList.Add(buildMrk(mid,bitext.Get(0)))
										mrkList.Add(buildMrk(mid,bitext.Get(1)))
										mid=mid+1
									End If

								Next
								'segSource.Put("mrk",sourceMrkList)
								targetMap.Put("mrk",mrkList)
							End If
						Else
							targetMap.Put("Text",dataMap.Get("translation"))
						End If
						
					Else
						transUnit.Put("target",dataMap.Get("translation"))
					End If
					Log("translation"&dataMap.Get("translation"))
				End If
			End If
		Next

		body.Put("trans-unit",transUnits)
	Next

	xliffMap.Put("file",filesList)
	xmlMap.Put("xliff",xliffMap)
	Log("xmlmap"&xmlMap)
	Return xmlMap
End Sub

Sub buildMrk(mid As Int,text As String) As Map
	Dim mrkMap As Map
	mrkMap.Initialize
	Dim attributes As Map
	attributes.Initialize
	attributes.Put("mid",mid)
	Log("mid"&mid)
	attributes.Put("mtype","seg")
	mrkMap.Put("Attributes",attributes)
	mrkMap.Put("Text",text)
	Return mrkMap
End Sub

Sub addNecessaryTags(target As String,source As String) As String
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("<.*?>",32,source)
	Dim tagsList As List
	tagsList.Initialize
	Do While tagMatcher.Find
		tagsList.Add(tagMatcher.Match)
	Loop
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("<.*?>",32,target)
	Do While tagMatcher.Find
		If tagsList.IndexOf(tagMatcher.Match)<>-1 Then
			tagsList.RemoveAt(tagsList.IndexOf(tagMatcher.Match))
		End If
	Loop
	For Each tag As String In tagsList
		target=target&tag
	Next
	Return target
End Sub


Sub shouldAddSpace(sourceLang As String,targetLang As String,index As Int,segmentsList As List) As Boolean
	Dim bitext As List=segmentsList.Get(index)
	Dim fullsource As String=bitext.Get(2)
	fullsource=Utils.getPureTextWithoutTrim(fullsource)
	Dim extra As Map
	extra=bitext.Get(4)
	Dim id As String=extra.Get("id")
	If Utils.LanguageHasSpace(sourceLang)=False And Utils.LanguageHasSpace(targetLang)=True Then
		If index+1<=segmentsList.Size-1 Then
			Dim nextBitext As List
			nextBitext=segmentsList.Get(index+1)
			Dim nextfullsource As String=nextBitext.Get(2)
			nextfullsource=Utils.getPureTextWithoutTrim(nextfullsource)
			Dim nextExtra As Map=nextBitext.Get(4)
			Dim nextid As String=nextExtra.Get("id")
			If nextid=id Then
				Try
					If Regex.IsMatch("\s",nextfullsource.CharAt(0))=False And Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1))=False Then
						Return True
					End If
				Catch
					Log(LastException)
				End Try
			End If
		End If
	End If
	Return False
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
	Dim source,nextsource As String
	source=bitext.Get(0)
	nextsource=nextBiText.Get(0)
	Dim fullsource,nextFullSource As String
	fullsource=bitext.Get(2)
	nextFullSource=nextBiText.Get(2)
	
	If bitext.Get(3)<>nextBiText.Get(3) Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
	Dim extra As Map
	extra=bitext.Get(4)
	Dim nextExtra As Map
	nextExtra=nextBiText.Get(4)
	If extra.Get("id")<>nextExtra.Get("id") Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different trans-units.","")
		Return
	End If
		
	Dim showTag As Boolean=False
	If filterGenericUtils.tagsNum(source&nextsource)<>filterGenericUtils.tagsNum(fullsource&nextFullSource) And filterGenericUtils.tagsNum(fullsource&nextFullSource)>0 Then
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
	
	Dim sourceLang,targetLang As String
	sourceLang=Main.currentProject.projectFile.Get("source")
	targetLang=Main.currentProject.projectFile.Get("target")
	If Utils.LanguageHasSpace(sourceLang) Then
		If Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\s",nextFullSource.CharAt(0)) Then
			sourceWhitespace=" "
		Else
			sourceWhitespace=""
		End If
	End If
	If Utils.LanguageHasSpace(targetLang) Then
		targetWhitespace=" "
	End If
	
	If Utils.LanguageHasSpace(sourceLang) Then
		If Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\s",nextFullSource.CharAt(0)) Then
			fullsourceWhitespace=" "
		End If
	End If
		
	If showTag Then
		source=fullsource&nextFullSource
		If filterGenericUtils.tagsNum(source)=1 Then
			source=filterGenericUtils.tagsAtBothSidesRemovedText(source)
		End If
		If filterGenericUtils.tagsNum(source)=2 And Regex.IsMatch("<.*?>",source) Then
			source=filterGenericUtils.tagsAtBothSidesRemovedText(source)
		End If
		fullsource=fullsource&nextFullSource
	Else
		source=source.Trim&sourceWhitespace&nextSourceTa.Text.Trim
		fullsource=Utils.rightTrim(fullsource)&fullsourceWhitespace&Utils.leftTrim(nextFullSource)
	End If
	sourceTextArea.Text=source
	sourceTextArea.Tag=sourceTextArea.Text
		
	targetTa=pane.GetNode(1)
	targetTa.Text=targetTa.Text&targetWhitespace&nextTargetTa.Text


	bitext.Set(0,sourceTextArea.Text)
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
	Dim bitext,newBiText As List
	bitext=Main.currentProject.segments.Get(index)
	If source.Trim="" Then
		Return
	End If
	
	Dim fullsource As String
	fullsource=bitext.Get(2)

	sourceTextArea.Text=sourceTextArea.Text.SubString2(0,sourceTextArea.SelectionEnd)
	sourceTextArea.Text=sourceTextArea.Text.Replace(CRLF,"")
	sourceTextArea.Tag=sourceTextArea.Text
	Main.currentProject.addTextAreaToSegmentPane(newSegmentPane,source,"")
	
	
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
	Dim previousID As String=""
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
		Dim extra As Map
		extra=bitext.Get(4)

		If target="" Then
			translation=fullsource
		Else
			If shouldAddSpace(Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),i,Main.currentProject.segments) Then
				target=target&" "
			End If
			translation=fullsource.Replace(source,target)
			If Utils.LanguageHasSpace(Main.currentProject.projectFile.Get("target"))=False Then
				translation=segmentation.removeSpacesAtBothSides(Main.currentProject.path,Main.currentProject.projectFile.Get("target"),translation,Utils.getMap("settings",Main.currentProject.projectFile).GetDefault("remove_space",True))
			End If
		End If

		Dim id As String
		id=extra.Get("id")
		If previousID<>id Then
			text.Append(CRLF)
			previousID=id
		End If
		If i=Main.currentProject.lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		text.Append(translation)
	Next
	Return text.ToString
End Sub