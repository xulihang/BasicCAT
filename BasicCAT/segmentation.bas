B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private rules As List
	Private previousLang As String
	Private previousText As String
	Public cascade As Boolean=False
End Sub

Sub readRulesOfProject(lang As String,projectPath As String)
	If rules.IsInitialized=False Then
		rules.Initialize
	End If
	If previousLang<>lang Then
		previousLang=lang
		Dim configPath As String=File.Combine(projectPath,"config")
		If File.Exists(configPath,"segmentationRules.srx") Then
			rules=SRX.readRules(File.Combine(configPath,"segmentationRules.srx"),lang)
		Else
			rules=SRX.readRules(File.Combine(File.DirAssets,"segmentationRules.srx"),lang)
		End If
	End If
End Sub

Public Sub UpdateRules(newRules As List)
	rules=newRules
End Sub

Public Sub ResetPreviousLang
	previousLang=""
End Sub

Sub segmentedTxt(text As String,sentenceLevel As Boolean,sourceLang As String,projectPath As String) As ResumableSub
	readRulesOfProject(sourceLang,projectPath)
	wait for (segmentedTxt2(text,sentenceLevel)) Complete (segments As List)
	Return segments
End Sub

Sub segmentedTxtWithSpecifiedRules(text As String,sentenceLevel As Boolean,sourceLang As String,specifiedRules As List) As ResumableSub
	UpdateRules(specifiedRules)
	wait for (segmentedTxt2(text,sentenceLevel)) Complete (segments As List)
	Return segments
End Sub

Sub segmentedTxt2(text As String,sentenceLevel As Boolean) As ResumableSub
	'Log("text"&text)
	Dim segments As List
	segments.Initialize
	If rules.IsInitialized=False Then
		Return segments
	End If
    If text.Trim="" Then
		segments.Add(text)
		Return segments
    End If
	Dim splitted As List
	splitted.Initialize
	splitted.AddAll(Regex.Split(CRLF,text))
	
	Dim paraIndex As Int=-1
	For Each para As String In splitted
		paraIndex=paraIndex+1
	    If sentenceLevel Then 
			wait for (paragraphInSegments(para)) Complete (resultList As List)
			segments.AddAll(resultList)
		Else
			segments.Add(para)
	    End If		
		'Log("paraIndex:"&paraIndex)
		AppendCRLF(segments,paraIndex,text,splitted)
	Next

	Return segments
End Sub

Sub AppendCRLF(segments As List,paraIndex As Int,text As String,splitted As List)
	If segments.Size>0 Then
		Dim last As String
		last=segments.Get(segments.Size-1)
		If paraIndex<>splitted.Size-1 Then
			last=last&CRLF
		Else if text.EndsWith(CRLF)=True Then
			last=last&CRLF
		End If
		segments.set(segments.Size-1,last)
	Else
		'Log("segments size = 0")
		'Log(splitted)
		Dim para As String=splitted.Get(paraIndex)
		segments.Add(para&CRLF) ' if there are several LFs at the beginning
	End If
End Sub



Sub paragraphInSegments(text As String) As ResumableSub
	Dim previousText As String
	Dim segments As List
	segments.Initialize
	
	Dim breakPositionsMap As Map
	breakPositionsMap.Initialize
	breakPositionsMap=getPositions("yes",text)
	
	Dim nonbreakPositionsMap As Map
	nonbreakPositionsMap.Initialize
	nonbreakPositionsMap=getPositions("no",text)

	Dim finalBreakPositions As List
	finalBreakPositions.Initialize
	For Each pos As Int In breakPositionsMap.Keys
		If nonbreakPositionsMap.ContainsKey(pos) Then
			If cascade=False Then
				If breakPositionsMap.Get(pos)<nonbreakPositionsMap.Get(pos) Then
					finalBreakPositions.Add(pos)
				End If
			End If
		Else
			finalBreakPositions.Add(pos)
		End If
	Next
	finalBreakPositions.Sort(True)
	'Log(text)
	'Log("start")
	'Log(breakPositionsMap)
	'Log(nonbreakPositionsMap)
	'Log(finalBreakPositions)
	For Each pos As Int In finalBreakPositions
		Dim textTobeAdded As String
		textTobeAdded=text.SubString2(previousText.Length,pos)
		segments.Add(textTobeAdded)
		previousText=text.SubString2(0,pos)
	Next
	If previousText.Length<>text.Length Then
		segments.Add(text.SubString2(previousText.Length,text.Length))
	End If
	
	Return segments
End Sub

Sub removeDuplicated(source As List)
	Dim newList As List
	newList.Initialize
	For Each index As Int In source
		If newList.IndexOf(index)=-1 Then
			newList.Add(index)
		End If
	Next
	source.Clear
	source.AddAll(newList)
End Sub

Sub getPositions(break As String,text As String) As Map
	Dim breakPositions As Map
	breakPositions.Initialize
	'Dim textLeft As String
	Dim index As Int=-1
	For Each rule As Map In rules
		index=index+1
		If rule.Get("break")<>break Then
			Continue
		End If
		'textLeft=text
		Dim beforeBreak,afterBreak As String
		beforeBreak=rule.Get("beforebreak")
		afterBreak=rule.Get("afterbreak")

		Dim bbm As Matcher
		bbm=Regex.Matcher2(beforeBreak,32,text)

		If beforeBreak<>"null" Then
			Do While bbm.Find
				If afterBreak="null" Then
					addPosition(bbm.GetEnd(0),breakPositions,index)
				End If
			
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,text)
				Do While abm.Find
					If bbm.GetEnd(0)=abm.GetStart(0) Then
						addPosition(bbm.GetEnd(0),breakPositions,index)
						Exit
					End If
				Loop
			Loop
		Else if afterBreak<>"null" Then
			Dim abm As Matcher
			abm=Regex.Matcher2(afterBreak,32,text)
			Do While abm.Find
				addPosition(abm.GetStart(0),breakPositions,index)
			Loop
		End If
	Next
	
	Return breakPositions
End Sub

Sub addPosition(pos As Int,breakPositions As Map,ruleIndex As Int)
	If breakPositions.ContainsKey(pos) Then
		If breakPositions.Get(pos)<ruleIndex Then
			breakPositions.Put(pos,ruleIndex)
		End If
	Else
		breakPositions.Put(pos,ruleIndex)
	End If
End Sub

Sub removeSpacesAtBothSides(projectPath As String,targetLang As String,text As String,removeRedundantSpaces As Boolean) As String
	readRulesOfProject(targetLang,projectPath)
	Dim breakPositionsMap As Map=getPositions("yes",previousText&text)
	Dim breakPositions As List
	breakPositions.Initialize
	For Each pos As Int In breakPositionsMap.Keys
		pos=pos-previousText.Length
		breakPositions.Add(pos)
	Next
	breakPositions.Sort(False)
	
	For Each position As Int In breakPositions
		Try
			'Log(position)
			'Log(text)
			'Log("charat"&text.CharAt(position))
			'Log("remove space:")
			'Log(text.CharAt(position)=" ")
			Dim offsetToRight As Int=0
			For i=0 To Max(text.Length-1-position,0)
				If position+i<=text.Length-1 Then
					If text.CharAt(position+i)=" " Then
						offsetToRight=offsetToRight+1
					Else
						Exit
					End If
				End If
			Next
			Dim rightText As String
			If position+offsetToRight<=text.Length-1 Then
				rightText=text.SubString2(position+offsetToRight,text.Length)
			End If
			text=text.SubString2(0,position)&rightText
		Catch
			Log(LastException)
		End Try
	Next
	
	If removeRedundantSpaces Then
		text=Regex.Replace2("\b *\B",32,text,"")
		text=Regex.Replace2("\B *\b",32,text,"")
	End If
	previousText=text
	Return text
End Sub

Public Sub segmentedTxtSimpleway(text As String,Trim As Boolean,sourceLang As String,filetype As String) As List
	
	'File.WriteString(File.DirApp,"1-before",text)
	Dim segmentationRule As List
	If filetype="idml" Then
		segmentationRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&"_idml.conf")
	Else
		segmentationRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&".conf")
	End If
	
	Dim segmentationExceptionRule As List
	segmentationExceptionRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&"_exception.conf")
	
	Dim seperator As String
	seperator="------"&CRLF
	
	Dim seperated As String
	seperated=text
	For Each rule As String In segmentationRule
		seperated=Regex.Replace(rule,seperated,"$0"&seperator)
	Next

	For Each rule As String In segmentationExceptionRule
		seperated=seperated.Replace(rule&seperator,rule)
	Next
	Dim out As List
	out.Initialize
	For Each sentence As String In Regex.Split(seperator,seperated)
		If Trim Then
			sentence=sentence.Trim
		End If
		out.Add(sentence)
	Next
	
	Dim after As String
	For Each sentence As String In out
		after=after&sentence
	Next
	'File.WriteString(File.DirApp,"1-after",after)
	Return out
End Sub