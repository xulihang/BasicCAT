B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "poFilter"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Tag)
	Select Tag
		Case "createWorkFile"
			wait for (createWorkFile(Params.Get("filename"),Params.Get("path"),Params.Get("sourceLang"),Params.Get("sentenceLevel"))) Complete (result As Boolean)
			Return result
		Case "generateFile"
			generateFile(Params.Get("filename"),Params.Get("path"),Params.Get("projectFile"),Params.Get("main"))
		Case "mergeSegment"
			mergeSegment(Params.Get("MainForm"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "splitSegment"
			splitSegment(Params.Get("main"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "previewText"
			Return previewText(Params.Get("editorLV"),Params.Get("segments"),Params.Get("lastEntry"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("path"),Params.Get("settings"))
	End Select
	Return ""
End Sub

Public Sub createWorkFile(filename As String,path As String,sourceLang As String,sentenceLevel As Boolean) As ResumableSub
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	
	Dim sourceFiles As List
	sourceFiles.Initialize
	
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
	Dim segmentsList As List
	segmentsList.Initialize
	Dim innerfileName As String
	innerfileName=filename
	
	Dim id As Int=0
	For Each msgid As String As List In readPO(path,filename)
		Dim inbetweenContent As String
		id=id+1
		wait for (segmentation.segmentedTxt(msgid,sentenceLevel,sourceLang,path)) Complete (segmentedText As List)
		Dim size As Int
		size=segmentedText.Size
		Dim index As Int=-1
		For Each source As String In segmentedText
			index=index+1
			Dim bitext As List
			bitext.Initialize
		    If source.Trim=""  And index<>size-1 Then 'newline or empty space
				inbetweenContent=inbetweenContent&source
				Continue
			else if filterGenericUtils.tagsRemovedText(source).Trim="" And index<>size-1 Then
				inbetweenContent=inbetweenContent&source
				Continue
			Else
				source=unescapeSpecialCharacters(source)
				Dim sourceShown As String=source
				If filterGenericUtils.tagsNum(sourceShown)=1 Then
					sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
				End If
				If filterGenericUtils.tagsNum(sourceShown)>=2 And Regex.IsMatch("<.*?>",sourceShown) Then
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
			If index=size-1 And filterGenericUtils.tagsRemovedText(sourceShown).Trim="" And segmentsList.Size>0 Then 'last segment contains tags but no text
				Dim previousBitext As List
				previousBitext=segmentsList.Get(segmentsList.Size-1)
				Dim previousExtra As Map
				previousExtra=previousBitext.Get(4) 'segments is at file level not msgid level, so needs verification
				If previousExtra.Get("id")=id Then
					Dim sourceShown As String
					sourceShown=previousBitext.Get(0)&source.Trim
					If filterGenericUtils.tagsNum(sourceShown)=1 Then
						sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
					End If
					If filterGenericUtils.tagsNum(sourceShown)>=2 And Regex.IsMatch("<.*?>",sourceShown) Then
						sourceShown=filterGenericUtils.tagsAtBothSidesRemovedText(sourceShown)
					End If
					previousBitext.Set(0,sourceShown)
					previousBitext.Set(2,previousBitext.Get(2)&bitext.Get(2))
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

	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
	Return True
End Sub

Sub unescapeSpecialCharacters(text As String) As String
	text=text.Replace("\n",CRLF)
	text=text.Replace("\t","	")
	text=text.Replace($"\""$,$"""$)
	Return text
End Sub

Sub escapeSpecialCharacters(text As String) As String
	text=text.Replace(CRLF,"\n")
	text=text.Replace("	","\t")
	text=text.Replace($"""$,$"\""$)
	Return text
End Sub



Sub readPO(path As String,filename As String) As List
	Dim msgidList As List

	msgidList.Initialize

	Dim textReader As TextReader
	textReader.Initialize(File.OpenInput(File.Combine(path,"source"),filename))
	Dim line As String
	line=textReader.ReadLine
	
	Dim msgid As String
	Dim isMsgid As Boolean=False
	Do While line<>Null
		Dim contentMatcher As Matcher
		contentMatcher=Regex.Matcher($""(.*?[^\\])""$,line)
		If line.StartsWith("msgid") Then
			isMsgid=True
			If contentMatcher.Find Then
				msgid=contentMatcher.Group(1)
			End If
		Else
			If line.StartsWith($"""$) And isMsgid Then
				If contentMatcher.Find Then
					msgid=msgid&contentMatcher.Group(1)
				End If
			Else
				If isMsgid Then
					msgidList.Add(msgid)
					msgid=""
				End If
				isMsgid=False
			End If
		End If
		line=textReader.ReadLine
	Loop
	textReader.Close
	'Log(msgidList)
	Return msgidList
End Sub

Sub countMsgStr(path As String,filename As String) As Int
	Dim times As Int
	Dim textReader As TextReader
	textReader.Initialize(File.OpenInput(File.Combine(path,"source"),filename))
	Dim line As String
	line=textReader.ReadLine
	Do While line<>Null
		If line.StartsWith("msgstr") Then
			times=times+1
		End If
		line=textReader.ReadLine
	Loop
	Return times
End Sub

Sub fillPO(msgstrList As List,path As String,filename As String) As String
	Dim content As StringBuilder
	content.Initialize
	

	Dim textReader As TextReader
	textReader.Initialize(File.OpenInput(File.Combine(path,"source"),filename))
	Dim line As String
	line=textReader.ReadLine
    Dim isMsgstr As Boolean=False
	Dim msgstrIndex As Int=0
	Do While line<>Null
		If line.StartsWith("msgstr") Then
			msgstrIndex=msgstrIndex+1
			isMsgstr=True
			Dim msgstr As String
			msgstr=msgstrList.Get(0)
			If msgstr="" Then
				msgstrList.RemoveAt(0)
				content.Append(line).Append(CRLF)
				line=textReader.ReadLine
				Continue
			End If
			If msgstr.Contains("\n") Then
				'Log(True)
				msgstr=handleMultiline(msgstr)
			End If
			content.Append("msgstr ").Append(Chr(34)).Append(msgstr).Append(Chr(34)).Append(CRLF).Append(CRLF)
			msgstrList.RemoveAt(0)
		else if isMsgstr And line.StartsWith($"""$) And msgstrIndex<>1 Then
			Log("escape this line")
		Else
			isMsgstr=False
			content.Append(line).Append(CRLF)
		End If
		line=textReader.ReadLine
	Loop
	textReader.Close
	Return content.ToString
End Sub

Sub handleMultiline(text As String) As String
	text=Chr(34)&CRLF&Chr(34)&text
	text=text.Replace("\n","\n"&Chr(34)&CRLF&Chr(34))
	Return text
End Sub

Sub generateFile(filename As String,path As String,projectFile As Map,BCATMain As Object)
	
	Dim addID As List
	addID.Initialize
	Dim idList As List
	idList.Initialize
	For i=1 To countMsgStr(path,filename)
		'Log(i)
		idList.Add(i)
	Next
	
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	Dim msgstrList As List
	msgstrList.Initialize
	Dim msgstr As String
	Dim currentID As Int=0
	Dim first As Boolean=True
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
			source=escapeSpecialCharacters(source)
			target=escapeSpecialCharacters(target)
			fullsource=escapeSpecialCharacters(fullsource)
			
			If target="" Or target=source Then
				translation=fullsource
			Else
				If shouldAddSpace(projectFile.Get("source"),projectFile.Get("target"),index,segmentsList) Then
					target=target&" "
				End If
				'translation=fullsource.Replace(source,target)
				translation=filterGenericUtils.relaceAtTheRightPosition(source,target,fullsource)
				If Utils.LanguageHasSpace(projectFile.Get("target"))=False Then
					translation=segmentation.removeSpacesAtBothSides(path,projectFile.Get("target"),translation,Utils.getMap("settings",projectFile).GetDefault("remove_space",True))
				End If
			End If
			'Log("translation"&translation)
			Dim extra As Map
			extra=bitext.Get(4)
			If extra.ContainsKey("neglected") Then
				If extra.get("neglected")="yes" Then
					translation=fullsource.Replace(source,"")
				End If
			End If
			
			Dim id As Int=extra.Get("id")
			

			

			If first Then
				currentID=id
				first=False
			End If


			If currentID<>id Then
				msgstrList.Add(msgstr)
				If id-currentID>1 Then
					Log(id)
					Log(currentID)
					Log(msgstr)
					Log(translation)
					For i=2 To id-currentID
						msgstrList.Add("")
						addID.add(currentID)
						currentID=currentID+1
					Next
				End If
				msgstr=translation
				addID.add(currentID)
				currentID=currentID+1
			Else
				msgstr=msgstr&translation
			End If
		Next
	Next
	
	msgstrList.Add(msgstr)
	addID.Add(idList.Get(idList.Size-1))
	For Each id As Int In idList
		If addID.IndexOf(id)=-1 Then
			msgstrList.InsertAt(id-1,"")
			addID.InsertAt(id-1,id)
		End If
	Next
	Log(msgstrList)
	File.WriteString(File.Combine(path,"target"),filename,fillPO(msgstrList,path,filename))
	CallSub2(BCATMain,"updateOperation",filename&" generated!")
End Sub

Sub mergeSegment(MainForm As Form,sourceTextArea As TextArea,editorLV As ListView,segments As List,projectFile As Map)
	Dim index As Int
	index=editorLV.Items.IndexOf(sourceTextArea.Parent)
	If index+1>segments.Size-1 Then
		Return
	End If
	Dim bitext,nextBiText As List
	bitext=segments.Get(index)
	nextBiText=segments.Get(index+1)
	Dim source,nextsource As String
	source=bitext.Get(0)
	nextsource=nextBiText.Get(0)
	Dim fullsource,nextFullSource As String
	fullsource=bitext.Get(2)
	nextFullSource=nextBiText.Get(2)
	
	If bitext.Get(3)<>nextBiText.Get(3) Then
		fx.Msgbox(MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
	Dim extra As Map
	extra=bitext.Get(4)
	Dim nextExtra As Map
	nextExtra=nextBiText.Get(4)
	If extra.Get("id")<>nextExtra.Get("id") Then
		fx.Msgbox(MainForm,"Cannot merge segments as these two belong to different units.","")
		Return
	End If
		
	If filterGenericUtils.tagsNum(source&nextsource)<>filterGenericUtils.tagsNum(fullsource&nextFullSource) And filterGenericUtils.tagsNum(fullsource&nextFullSource)>0 Then
		Dim result As Int
		result=fx.Msgbox2(MainForm,"Segments contain unshown tags, continue?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
		'Log(result)
		'yes -1, no -2, cancel -3
		Select result
			Case -2
				Return
			Case -3
				Return
		End Select

	End If
	
	Dim pane,nextPane As Pane

	pane=editorLV.Items.Get(index)
	nextPane=editorLV.Items.Get(index+1)
	Dim targetTa,nextTargetTa As TextArea
	nextTargetTa=nextPane.GetNode(1)
	
	bitext.Set(1,targetTa.Text)
	nextBiText.Set(1,nextTargetTa.Text)

	mergeInternalSegment(segments,index,projectFile.Get("source"),projectFile.Get("target"))
	
	
	sourceTextArea.Text=bitext.Get(0)
	sourceTextArea.Tag=sourceTextArea.Text
		
	targetTa=pane.GetNode(1)
	targetTa.Text=bitext.Get(1)

	editorLV.Items.RemoveAt(editorLV.Items.IndexOf(sourceTextArea.Parent)+1)
End Sub

Sub mergeInternalSegment(segments As List,index As Int,sourceLang As String,targetLang As String)

	Dim bitext,nextBiText As List
	bitext=segments.Get(index)
	nextBiText=segments.Get(index+1)
	Dim source As String
	source=bitext.Get(0)
	Dim target,nextTarget As String
	target=bitext.Get(1)
	nextTarget=nextBiText.Get(1)
	Dim fullsource,nextFullSource As String
	fullsource=bitext.Get(2)
	nextFullSource=nextBiText.Get(2)
	
	If bitext.Get(3)<>nextBiText.Get(3) Then
		'fx.Msgbox(MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
	Dim extra As Map
	extra=bitext.Get(4)
	Dim nextExtra As Map
	nextExtra=nextBiText.Get(4)
	If extra.Get("id")<>nextExtra.Get("id") Then
		'fx.Msgbox(MainForm,"Cannot merge segments as these two belong to different units.","")
		Return
	End If
		
	Dim targetWhitespace As String
	targetWhitespace=""
	
	If Utils.LanguageHasSpace(targetLang) Then
		targetWhitespace=" "
	End If
	
	source=fullsource&nextFullSource
	If filterGenericUtils.tagsNum(source)=1 Then
		source=filterGenericUtils.tagsAtBothSidesRemovedText(source)
	End If
	If filterGenericUtils.tagsNum(source)>=2 And Regex.IsMatch("<.*?>",source) Then
		source=filterGenericUtils.tagsAtBothSidesRemovedText(source)
	End If
	fullsource=fullsource&nextFullSource

	bitext.Set(0,source)
	bitext.Set(1,target&targetWhitespace&nextTarget)
	bitext.Set(2,fullsource)
	segments.RemoveAt(index+1)
End Sub

Sub splitSegment(BCATMain As Object,sourceTextArea As TextArea,editorLV As ListView,segments As List,projectFile As Map)
	Dim index As Int
	index=editorLV.Items.IndexOf(sourceTextArea.Parent)
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
	CallSub3(BCATMain,"addTextAreaToSegmentPane",newSegmentPane,source)
	Dim bitext,newBiText As List
	bitext=segments.Get(index)
	
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
	segments.set(index,bitext)
	segments.InsertAt(index+1,newBiText)


	editorLV.Items.InsertAt(editorLV.Items.IndexOf(sourceTextArea.Parent)+1,newSegmentPane)
End Sub

Sub shouldAddSpace(sourceLang As String,targetLang As String,index As Int,segmentsList As List) As Boolean
	Dim bitext As List=segmentsList.Get(index)
	Dim fullsource As String=bitext.Get(2)
	fullsource=Utils.getPureTextWithoutTrim(fullsource)
	Dim extra As Map
	extra=bitext.Get(4)
	Dim id As Int=extra.Get("id")
	If Utils.LanguageHasSpace(sourceLang)=False And Utils.LanguageHasSpace(targetLang)=True Then
		If index+1<=segmentsList.Size-1 Then
			Dim nextBitext As List
			nextBitext=segmentsList.Get(index+1)
			Dim nextfullsource As String=nextBitext.Get(2)
			nextfullsource=Utils.getPureTextWithoutTrim(nextfullsource)
			Dim nextExtra As Map=nextBitext.Get(4)
			Dim nextid As Int=nextExtra.Get("id")
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

Sub previewText(editorLV As ListView,segments As List,lastEntry As Int,sourceLang As String,targetLang As String,path As String,settings As Map) As String
	Log("Po preview")
	Dim text As StringBuilder
	text.Initialize
	If editorLV.Items.Size<>segments.Size Then
		Return ""
	End If
	Dim previousID As Int=-1
	For i=Max(0,lastEntry-3) To Min(lastEntry+7,segments.Size-1)
		Try
			Dim p As Pane
			p=editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try
		Dim sourceTextArea As TextArea
		Dim targetTextArea As TextArea
		sourceTextArea=p.GetNode(0)
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=segments.Get(i)
		Dim source,target,fullsource,translation As String
		source=sourceTextArea.Text
		target=targetTextArea.Text
		fullsource=bitext.Get(2)
		Dim extra As Map
		extra=bitext.Get(4)
		
		If target="" Then
			translation=fullsource
		Else
			If shouldAddSpace(sourceLang,targetLang,i,segments) Then
				target=target&" "
			End If
			translation=fullsource.Replace(source,target)
			If Utils.LanguageHasSpace(targetLang)=False Then
				translation=segmentation.removeSpacesAtBothSides(path,targetLang,translation,settings.GetDefault("remove_space",True))
			End If
		End If
		If i=lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		Dim id As Int
		id=extra.Get("id")

		If previousID<>id Then
			text.Append(CRLF)
			previousID=id
		End If
		text.Append(translation)
	Next
	Return text.ToString
End Sub