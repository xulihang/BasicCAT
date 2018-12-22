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
	icu4j.convert(File.Combine(path,"source"),filename)
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
	For Each source As String In segmentation.segmentedTxt(File.ReadString(File.Combine(path,"source"),filename),False,sourceLang,path)
		Dim bitext As List
		bitext.Initialize
		If source.Trim="" Then 'newline or empty space
			inbetweenContent=inbetweenContent&source
			Continue
		Else if source.Trim<>"" Then
			bitext.add(source.Trim)
			bitext.Add("")
			bitext.Add(inbetweenContent&source) 'inbetweenContent contains crlf and spaces between sentences
			bitext.Add(innerFilename)
			Dim extra As Map
			extra.Initialize
			bitext.Add(extra)
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
		Dim index As Int=-1
		For Each bitext As List In segmentsList
			index=index+1
			Dim source,target,fullsource,translation As String
			source=bitext.Get(0)
			target=bitext.Get(1)
			fullsource=bitext.Get(2)
			Dim extra As Map
			extra=bitext.Get(4)
			If extra.ContainsKey("translate") Then
				If extra.get("translate")="no" Then
					translation=fullsource.Replace(source,"")
				End If
			End If
			Log(source)
			Log(target)
			Log(fullsource)
			If target="" Then
				translation=fullsource
			Else
				If shouldAddSpace(projectFile.Get("source"), _ 
				                  projectFile.Get("target"), _ 
				                  index,segmentsList) Then
					target=target&" "
				End If
				translation=fullsource.Replace(source,target)
				
				If Utils.LanguageHasSpace(projectFile.Get("target"))=False Then
					translation=segmentation.removeSpacesAtBothSides(Main.currentProject.path,Main.currentProject.projectFile.Get("target"),translation,Utils.getMap("settings",projectFile).GetDefault("remove_space",True))
				End If
			End If

			result=result&translation
		Next
	Next
	
	File.WriteString(File.Combine(path,"target"),filename,result)
	Main.updateOperation(filename&" generated!")
End Sub


Sub shouldAddSpace(sourceLang As String,targetLang As String,index As Int,segmentsList As List) As Boolean
	Dim bitext As List=segmentsList.Get(index)
	Dim fullsource As String=bitext.Get(2)
	If Utils.LanguageHasSpace(sourceLang)=False And Utils.LanguageHasSpace(targetLang)=True Then
		If index+1<=segmentsList.Size-1 Then
			Dim nextBitext As List
			nextBitext=segmentsList.Get(index+1)
			Dim nextfullsource As String=nextBitext.Get(2)
			If fullsource.EndsWith(CRLF)=False And nextfullsource.StartsWith(CRLF)=False Then
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
	Dim source As String
	source=bitext.Get(0)
		
	If bitext.Get(3)<>nextBiText.Get(3) Then
		fx.Msgbox(Main.MainForm,"Cannot merge segments as these two belong to different files.","")
		Return
	End If
		
	Dim pane,nextPane As Pane

	pane=Main.editorLV.Items.Get(index)
	nextPane=Main.editorLV.Items.Get(index+1)
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
	
	Dim sourceLang,targetLang As String
	sourceLang=Main.currentProject.projectFile.Get("source")
	targetLang=Main.currentProject.projectFile.Get("target")
	If Utils.LanguageHasSpace(source)=True Then
		If Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1)) Or Regex.IsMatch("\s",nextFullSource.CharAt(0)) Then
			sourceWhitespace=" "
		Else
			sourceWhitespace=""
		End If
	End If
	If Utils.LanguageHasSpace(targetLang)=True Then
		targetWhitespace=" "
	End If
	
	If Utils.LanguageHasSpace(sourceLang)=True Then
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
	bitext.Set(2,sourceTextArea.Text)
	
	
	newBiText.Initialize
	newBiText.Add(source)
	newBiText.Add("")
	newBiText.Add(fullsource.Replace(sourceTextArea.Text,""))
	newBiText.Add(bitext.Get(3))
	newBiText.Add(bitext.Get(4))
	Main.currentProject.segments.set(index,bitext)
	Main.currentProject.segments.InsertAt(index+1,newBiText)


	Main.editorLV.Items.InsertAt(Main.editorLV.Items.IndexOf(sourceTextArea.Parent)+1,newSegmentPane)
End Sub

Sub previewText As String
	Dim text As String
	If Main.editorLV.Items.Size<>Main.currentProject.segments.Size Then
		Return ""
	End If
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

		If i=Main.currentProject.lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		text=text&translation
	Next
	Return text
End Sub