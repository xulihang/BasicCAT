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
public Sub Run(Tag As String, Params As Map) As Object
	Log("run"&Params)
	Select Tag
		Case "createWorkFile"
			createWorkFile(Params.Get("filename"),Params.Get("path"),Params.Get("sourceLang"))
		Case "generateFile"
			generateFile(Params.Get("filename"),Params.Get("path"),Params.Get("projectFile"))
		Case "mergeSegment"
			mergeSegment(Params.Get("MainForm"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "splitSegment"
			splitSegment(Params.Get("main"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "previewText"
			previewText(Params.Get("editorLV"),Params.Get("segments"),Params.Get("lastEntry"))
	End Select
	Return ""
End Sub

Sub createWorkFile(filename As String,path As String,sourceLang As String)
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
	Dim inbetweenContent As String
	Dim id As Int=0
	For Each msgid As String As List In readPO(path,filename)
		id=id+1
		For Each source As String In segmentation.segmentedTxt(msgid,False,sourceLang,path)
			Dim bitext As List
			bitext.Initialize
			If source.Trim="" Then 'newline or empty space
				inbetweenContent=inbetweenContent&source
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

	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
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
	Log(msgidList)
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
	Dim content As String
	

	Dim textReader As TextReader
	textReader.Initialize(File.OpenInput(File.Combine(path,"source"),filename))
	Dim line As String
	line=textReader.ReadLine

	Do While line<>Null
		If line.StartsWith("msgstr") Then
			Dim msgstr As String
			msgstr=msgstrList.Get(0)
			If msgstr="" Then
				msgstrList.RemoveAt(0)
				content=content&line&CRLF
				line=textReader.ReadLine
				Continue
			End If
			If msgstr.Contains("\n") Then
				Log(True)
				msgstr=handleMultiline(msgstr)
			End If
			content=content&"msgstr "&Chr(34)&msgstr&Chr(34)&CRLF&CRLF
			msgstrList.RemoveAt(0)
		Else
			content=content&line&CRLF
		End If
		line=textReader.ReadLine
	Loop
	textReader.Close
	Return content
End Sub

Sub handleMultiline(text As String) As String
	text=Chr(34)&CRLF&Chr(34)&text
	text=text.Replace("\n","\n"&Chr(34)&CRLF&Chr(34))
	Return text
End Sub

Sub generateFile(filename As String,path As String,projectFile As Map)
	
	Dim addID As List
	addID.Initialize
	Dim idList As List
	idList.Initialize
	For i=1 To countMsgStr(path,filename)
		Log(i)
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
		For Each bitext As List In segmentsList
			Dim source,target,fullsource,translation As String
			source=bitext.Get(0)
			target=bitext.Get(1)
			fullsource=bitext.Get(2)
			If target="" Then
				translation=fullsource
			Else
				translation=fullsource.Replace(source,target)
			End If
			Log("translation"&translation)
			Dim extra As Map
			extra=bitext.Get(4)
			If extra.ContainsKey("translate") Then
				If extra.get("translate")="no" Then
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
	
	File.WriteString(File.Combine(path,"target"),filename,fillPO(msgstrList,path,filename))
End Sub

Sub mergeSegment(MainForm As Form,sourceTextArea As TextArea,editorLV As CustomListView,segments As List,projectFile As Map)
	Dim index As Int
	index=editorLV.GetItemFromView(sourceTextArea.Parent)
	
	Dim bitext,nextBiText As List
	bitext=segments.Get(index)
	nextBiText=segments.Get(index+1)
	Dim source As String
	source=bitext.Get(0)
		
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
		
	Dim pane,nextPane As Pane

	pane=editorLV.GetPanel(index)
	nextPane=editorLV.GetPanel(index+1)
	Dim targetTa,nextSourceTa,nextTargetTa As TextArea
	nextSourceTa=nextPane.GetNode(0)
	nextTargetTa=nextPane.GetNode(1)
	
	Dim fullsource,nextFullSource As String
	fullsource=bitext.Get(2)
	nextFullSource=nextBiText.Get(2)
	
	Dim sourceWhitespace,targetWhitespace,fullsourceWhitespace As String
	sourceWhitespace=""
	targetWhitespace=""
	fullsourceWhitespace=""
	
	If projectFile.Get("source")="en" or Utils.isChinese(fullsource)=False Then
		If Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\s",nextFullSource.CharAt(0)) Then
			sourceWhitespace=" "
		Else
			sourceWhitespace=""
		End If
	else if projectFile.Get("target")="en" Then
		targetWhitespace=" "
	End If
	
	If projectFile.Get("source")="en" Then
		If Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\s",nextFullSource.CharAt(0)) Then
			fullsourceWhitespace=" "
		End If
	End If
		
	sourceTextArea.Text=source.Trim&sourceWhitespace&nextSourceTa.Text.Trim
	sourceTextArea.Tag=sourceTextArea.Text
		
	targetTa=pane.GetNode(1)
	targetTa.Text=targetTa.Text&targetWhitespace&nextTargetTa.Text


	bitext.Set(0,sourceTextArea.Text)
	bitext.Set(1,targetTa.Text)



	bitext.Set(2,Utils.rightTrim(fullsource)&fullsourceWhitespace&Utils.leftTrim(nextFullSource))

		
	segments.RemoveAt(index+1)
	editorLV.RemoveAt(editorLV.GetItemFromView(sourceTextArea.Parent)+1)
End Sub

Sub splitSegment(BCATMain As Object,sourceTextArea As TextArea,editorLV As CustomListView,segments As List,projectFile As Map)
	Dim index As Int
	index=editorLV.GetItemFromView(sourceTextArea.Parent)
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
	bitext.Set(2,sourceTextArea.Text)
	
	
	newBiText.Initialize
	newBiText.Add(source)
	newBiText.Add("")
	newBiText.Add(fullsource.Replace(sourceTextArea.Text,""))
	newBiText.Add(bitext.Get(3))
	newBiText.Add(bitext.Get(4))
	segments.set(index,bitext)
	segments.InsertAt(index+1,newBiText)


	editorLV.InsertAt(editorLV.GetItemFromView(sourceTextArea.Parent)+1,newSegmentPane,"")
End Sub

Sub previewText(editorLV As CustomListView,segments As List,lastEntry As Int) As String
	Dim text As String
	If editorLV.Size<>segments.Size Then
		Return ""
	End If
	For i=Max(0,lastEntry-3) To Min(lastEntry+7,segments.Size-1)

		Dim p As Pane
		p=editorLV.GetPanel(i)
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
		If target="" Then
			translation=fullsource
		Else
			translation=fullsource.Replace(source,target)
		End If
		If i=lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		text=text&translation
	Next
	Return text
End Sub