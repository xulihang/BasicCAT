B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private rules As Map
	Private previousLang As String
End Sub

Sub segmentedTxt(text As String,Trim As Boolean,sourceLang As String,path As String) As List
	'Log("text"&text)
	If rules.IsInitialized=False Then
		rules.Initialize
	End If
	If previousLang<>sourceLang Then
		previousLang=sourceLang
		If File.Exists(path,"segmentationRules.srx") Then
			rules=SRX.readRules(File.Combine(path,"segmentationRules.srx"),sourceLang)
		Else
			rules=SRX.readRules(File.Combine(File.DirAssets,"default_rules.srx"),sourceLang)
		End If
	End If


	

	Dim segments As List
	segments.Initialize
    If text.Trim="" Then
		segments.Add(text)
		Return segments
    End If
	Dim splitted As List
	splitted.Initialize
	splitted.AddAll(Regex.Split(CRLF,text))
	Dim index As Int=-1
	For Each para As String In splitted
		index=index+1
	    segments.AddAll(paragraphInSegments(para))
		'Log(segments)
		'Log(segments.Size)
	    Dim last As String
	    last=segments.Get(segments.Size-1)

		If index<>splitted.Size-1 Then
			last=last&CRLF
		Else if text.EndsWith(CRLF)=True Then
			last=last&CRLF
		End If
		segments.set(segments.Size-1,last)
	Next
    'Log(segments)
	Return segments
End Sub



Sub paragraphInSegmentsCas(text As String) As List
	Dim breakRules,nonbreakRules As List
	breakRules=rules.Get("breakRules")
	nonbreakRules=rules.Get("nonbreakRules")
	
	Dim allRulesList As List
	allRulesList.Initialize
	allRulesList.Addall(nonbreakRules)
	allRulesList.Addall(breakRules)

	Dim previousText As String
	Dim segments As List
	segments.Initialize
	For i=0 To text.Length-1
		previousText=""
		'Log(i)

		For Each seg As String In segments

			previousText=previousText&seg
		Next
		Dim currentText As String
		currentText=text.SubString2(previousText.Length,i)
		'Log("ct"&currentText)
		'Log("pt"&previousText)
		'Log(currentText.Length+previousText.Length)
		'Log(text.Length)
		Dim matched As Boolean=False
		For Each rule As Map In allRulesList

			If matched Then
				Exit
			End If
			
			Dim beforeBreak,afterBreak As String
			beforeBreak=rule.Get("beforebreak")
			afterBreak=rule.Get("afterbreak")
			Dim bbm As Matcher
			bbm=Regex.Matcher2(beforeBreak,32,currentText)
			If beforeBreak<>"null" Then
				Do While bbm.find
					Log(i)
					Log(bbm.Match)
					'Log("end"&bbm.GetEnd(0))
					'Log("i"&i)
					If matched Then
						Exit
					End If
					If bbm.GetEnd(0)+previousText.Length<>i Then
						Continue
					End If
					'Log("bbmfind")
					'Log(bbm.Match)
					'Log(beforeBreak)

					If afterBreak="null" Then
						If rule.Get("break")="yes" Then
							segments.Add(currentText)
							'Log(currentText)
							'Log(rule)
						End If
						
						matched=True
						Exit
					End If
					
					Dim abm As Matcher
					abm=Regex.Matcher2(afterBreak,32,text.SubString2(previousText.Length,text.Length))
					'Log("at"&text.SubString2(previousText.Length,text.Length))
					Do While abm.Find
						Log("ab"&abm.Match)
						If abm.GetStart(0)=bbm.GetEnd(0) Then
							Log("abm")
							If rule.Get("break")="yes" Then
								segments.Add(currentText)
								'Log(currentText)
								'Log(rule)
							End If
							matched=True
							Exit
						End If
						If abm.GetStart(0)>currentText.Length Then
							Exit
						End If
					Loop
				Loop
			Else if afterBreak<>"null" Then
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,text.SubString2(previousText.Length,text.Length))
				Do While abm.Find
					If abm.GetStart(0)=bbm.GetEnd(0) Then
						If rule.Get("break")="yes" Then
							segments.Add(currentText)
							'Log(currentText)
							'Log(rule)
						End If
						matched=True
						Exit
					End If
                    If abm.GetStart(0)>currentText.Length Then
						Exit
                    End If
				Loop
			End If
		Next
	Next
	
	'Log(segments)
	previousText=""
	For Each seg As String In segments
		previousText=previousText&seg
	Next
	If previousText.Length<>text.Length Then
		segments.Add(text.SubString2(previousText.Length,text.Length))
	End If
	'Log(segments)
	Return segments
End Sub

Sub paragraphInSegments(text As String) As List

	Dim breakRules,nonbreakRules As List
	breakRules=rules.Get("breakRules")
	nonbreakRules=rules.Get("nonbreakRules")
	Dim previousText As String
	Dim segments As List
	segments.Initialize
	

	Dim breakPositions As List
	breakPositions.Initialize
	breakPositions.AddAll(getPositions(breakRules,text))
	breakPositions.Sort(True)
	removeDuplicated(breakPositions)
	
	Dim nonbreakPositions As List
	nonbreakPositions.Initialize
	nonbreakPositions.AddAll(getPositions(nonbreakRules,text))
	nonbreakPositions.Sort(True)
	removeDuplicated(nonbreakPositions)

	Dim finalBreakPositions As List
	finalBreakPositions.Initialize
	For Each index As Int In breakPositions
		If nonbreakPositions.IndexOf(index)=-1 Then
			finalBreakPositions.Add(index)
		End If
	Next
	'Log(breakPositions)
	'Log(nonbreakPositions)
	'Log(finalBreakPositions)
	For Each index As Int In finalBreakPositions
		Dim textTobeAdded As String
		textTobeAdded=text.SubString2(previousText.Length,index)
		segments.Add(textTobeAdded)
		previousText=text.SubString2(0,index)
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

Sub getPositions(rulesList As List,text As String) As List
	Dim breakPositions As List
	breakPositions.Initialize
	Dim textLeft As String
	For Each rule As Map In rulesList
		'Log(rule)
		textLeft=text
		Dim beforeBreak,afterBreak As String
		beforeBreak=rule.Get("beforebreak")
		afterBreak=rule.Get("afterbreak")

		Dim bbm As Matcher
		bbm=Regex.Matcher2(beforeBreak,32,textLeft)

		If beforeBreak<>"null" Then
			Do While bbm.Find
				If afterBreak="null" Then
					breakPositions.Add(bbm.GetEnd(0)+text.Length-textLeft.Length)
					textLeft=textLeft.SubString2(bbm.GetEnd(0),textLeft.Length)
					bbm=Regex.Matcher2(beforeBreak,32,textLeft)

				End If
			
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,textLeft)
				Do While abm.Find
					If bbm.GetEnd(0)=abm.GetStart(0) Then
						breakPositions.Add(abm.GetEnd(0)+text.Length-textLeft.Length)
						textLeft=textLeft.SubString2(abm.GetEnd(0),textLeft.Length)
						abm=Regex.Matcher2(afterBreak,32,textLeft)
						bbm=Regex.Matcher2(beforeBreak,32,textLeft)

						Exit
					End If
				Loop
			Loop
		Else if afterBreak<>"null" Then
			Dim abm As Matcher
			abm=Regex.Matcher2(afterBreak,32,textLeft)
			Do While abm.Find
				breakPositions.Add(abm.GetEnd(0)+text.Length-textLeft.Length)
				textLeft=textLeft.SubString2(abm.GetEnd(0),textLeft.Length)
				abm=Regex.Matcher2(afterBreak,32,textLeft)
			Loop
		End If
	Next
	
	Return breakPositions
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