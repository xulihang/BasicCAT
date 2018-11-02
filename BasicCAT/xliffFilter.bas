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
	
	Dim sourceFiles As List
	sourceFiles.Initialize
	
	Dim files As List
	files=getFilesList(escapedText(File.ReadString(File.Combine(path,"source"),filename)))
	
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
		Dim inbetweenContent As String
		For Each tu As List In getTransUnits(fileMap)
			Dim text As String
			text=tu.Get(0)
			Dim id As String
			id=tu.Get(1)
			For Each source As String In segmentation.segmentedTxt(text,False,sourceLang,"xliff")
				Dim bitext As List
				bitext.Initialize
				If source.Trim="" Then 'newline
					inbetweenContent=inbetweenContent&CRLF
					Continue
				Else if source.Trim<>"" Then
					bitext.add(source.Trim)
					bitext.Add("")
					bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
					bitext.Add(innerfileName)
					Dim extra As Map
					extra.Initialize
					extra.Put("id",id)
					bitext.Add(extra)
					inbetweenContent=""
				End If
				segmentsList.Add(bitext)
			Next
		Next
		If segmentsList.Size<>0 Then
			sourceFileMap.Put(innerfileName,segmentsList)
			sourceFiles.Add(sourceFileMap)
		End If
	Next

	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
End Sub


Sub getTransUnits(fileMap As Map) As List
	Dim body As Map
	body=fileMap.Get("body")
	Dim tidyTransUnits As List
	tidyTransUnits.Initialize
	Dim transUnits As List
	transUnits=Utils.GetElements(body,"trans-unit")
	For Each transUnit As Map In transUnits
		Log(transUnit)
		Dim attributes As Map
		attributes=transUnit.Get("Attributes")
		Dim id As String
		id=attributes.Get("id")
		Dim source As Map
		source=transUnit.Get("source")
		Dim text As String
		text=source.Get("Text")
		Dim oneTransUnit As List
		oneTransUnit.Initialize
		oneTransUnit.Add(text)
		oneTransUnit.Add(id)
		tidyTransUnits.Add(oneTransUnit)
	Next
	Return tidyTransUnits
End Sub

Sub getFilesList(xmlstring As String) As List
	Dim xmlMap As Map
	xmlMap=Utils.getXmlMap(xmlstring)
	Log(xmlMap)
	Dim xliffMap As Map
	xliffMap=xmlMap.Get("xliff")
	Return Utils.GetElements(xliffMap,"file")
End Sub

Sub escapedText(xmlstring As String) As String
	Dim new As String
	new=xmlstring
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2("<source.*?>(.*?)</source>",32,new)
	Dim times As Int=0
	Do While sourceMatcher.Find
		times=times+1
	Loop
	Dim replacedTimes As Int=0
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2("<source.*?>(.*?)</source>",32,new)

    Dim oldText As String=new
	Do While sourceMatcher.find
		'Log("match"&sourceMatcher.Group(1))
		If replacedTimes>=times Then
			Exit
		End If
		Dim before As String
		before=new.SubString2(0,sourceMatcher.GetStart(1))
		Dim mid As String
		mid=escapeInlineTag(sourceMatcher.Group(1))
		Dim after As String
		after=new.SubString2(sourceMatcher.GetEnd(1),new.Length)
		new=before&mid&after
		If oldText<>new Then
			sourceMatcher=Regex.Matcher2("<source.*?>(.*?)</source>",32,new)
			replacedTimes=0
			oldText=new
		Else
			replacedTimes=replacedTimes+1
		End If
		
		
    Loop
	Return new
End Sub

Sub unescapedText(xmlstring As String,tagName As String) As String
	Dim pattern As String
	pattern="<"&tagName&".*?>(.*?)</"&tagName&">"
	Dim new As String
	new=xmlstring
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2(pattern,32,new)
	Dim times As Int=0
	Do While sourceMatcher.Find
		times=times+1
	Loop
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2(pattern,32,new)
    Dim replacedTimes As Int=0
    Dim oldText As String=new
	Do While sourceMatcher.Find

		If replacedTimes>=times Then
			Exit
		End If

		Dim before As String
		before=new.SubString2(0,sourceMatcher.GetStart(1))
		Dim mid As String
		mid=unescapeInlineTag(sourceMatcher.Group(1))
		Dim after As String
		after=new.SubString2(sourceMatcher.GetEnd(1),new.Length)
		new=before&mid&after
		If oldText<>new Then
			sourceMatcher=Regex.Matcher2(pattern,32,new)
			replacedTimes=0
			oldText=new
		Else
		    replacedTimes=replacedTimes+1
		End If
	Loop

	Return new
End Sub

Sub escapeInlineTag(text As String) As String
	Dim tags As String
	tags="(bpt|ept|it|ph|g|bx|ex|x|sub)"
	text=Regex.Replace2("<(.*?"&tags&".*?)>",32,text,"&lt;$1&gt;")
	text=text.Replace($"""$,"&quot;")
	Return text
End Sub

Sub unescapeInlineTag(text As String) As String
	Dim tags As String
	tags="(bpt|ept|it|ph|g|bx|ex|x|sub)"
	text=text.Replace("&quot;",$"""$)
	text=Regex.Replace2("&lt;(.*?"&tags&".*?)&gt;",32,text,"<$1>")
	Return text
End Sub

Sub generateFile(filename As String,path As String,projectFile As Map)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	Dim translationMap As Map
	translationMap.Initialize
	For Each sourceFileMap As Map In sourceFiles
		Dim innerfilename As String
		innerfilename=sourceFileMap.GetKeyAt(0)
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
				target=addNecessaryTags(target,source)
				translation=fullsource.Replace(source,target)
			End If
			Dim extra As Map
			extra=bitext.Get(4)
			If translationMap.ContainsKey(extra.Get("id")) Then
				Dim dataMap As Map
				dataMap=translationMap.Get(extra.Get("id"))
				translation=dataMap.Get("translation")&translation
				translationMap.put(extra.Get("id"),CreateMap("translation":translation,"filename":innerfilename))
			Else
				translationMap.put(extra.Get("id"),CreateMap("translation":translation,"filename":innerfilename))
			End If
		Next
	Next
	Dim xmlString As String
	xmlString=Utils.getXmlFromMap(insertTranslation(translationMap,filename,path))
	xmlString=unescapedText(xmlString,"source")
	xmlString=unescapedText(xmlString,"target")
	Log(xmlString)
	File.WriteString(File.Combine(path,"target"),filename,xmlString)
End Sub

Sub insertTranslation(translationMap As Map,filename As String,path As String) As Map
	Dim xmlstring As String
	xmlstring=escapedText(File.ReadString(File.Combine(path,"source"),filename))
	Dim xmlMap As Map
	xmlMap=Utils.getXmlMap(xmlstring)
	Dim xliffMap As Map
	xliffMap=xmlMap.Get("xliff")
	Dim filesList As List
	filesList=Utils.GetElements(xliffMap,"file")
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
		transUnits=Utils.GetElements(body,"trans-unit")
		For Each transUnit As Map In transUnits
			Dim attributes As Map
			attributes=transUnit.Get("Attributes")
			Dim id As String
			id=attributes.Get("id")
			Dim target As Map
			target=transUnit.Get("target")
			If translationMap.ContainsKey(id) Then
				Dim dataMap As Map
				dataMap=translationMap.Get(id)
				If originalFilename=dataMap.Get("filename") Then
					For Each key As String In target.Keys
						If key<>"Attributes" Then
							target.Remove(key)
						End If
					Next
					target.Put("Text",dataMap.Get("translation"))
					Log(dataMap.Get("translation"))
				End If
			End If
		Next

		body.Put("trans-unit",transUnits)
	Next

	xliffMap.Put("file",filesList)
	xmlMap.Put("xliff",xliffMap)
	Log(xmlMap)
	Return xmlMap
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
	Dim extra As Map
	extra=bitext.Get(4)
	Dim nextExtra As Map
	nextExtra=nextBiText.Get(4)
	If extra.Get("id")<>nextExtra.Get("id") Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different trans-units.","")
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
	bitext.Set(2,sourceTextArea.Text)
	
	
	newBiText.Initialize
	newBiText.Add(source)
	newBiText.Add("")
	newBiText.Add(fullsource.Replace(sourceTextArea.Text,""))
	newBiText.Add(bitext.Get(3))
	newBiText.Add(bitext.Get(4))
	Main.currentProject.segments.set(index,bitext)
	Main.currentProject.segments.InsertAt(index+1,newBiText)


	Main.editorLV.InsertAt(Main.editorLV.GetItemFromView(sourceTextArea.Parent)+1,newSegmentPane,"")
End Sub

Sub previewText As String
	Dim text As String
	If Main.editorLV.Size<>Main.currentProject.segments.Size Then
		Return ""
	End If
	For i=Max(0,Main.currentProject.lastEntry-3) To Min(Main.currentProject.lastEntry+7,Main.currentProject.segments.Size-1)

		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
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
		If target="" Then
			translation=fullsource
		Else
			translation=fullsource.Replace(source,target)
		End If
		If i=Main.currentProject.lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		text=text&translation
	Next
	Return text
End Sub