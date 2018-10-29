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
End Sub

Sub segmentedTxt(text As String,Trim As Boolean,sourceLang As String,filetype As String) As List
	If rules.IsInitialized=False Then
		rules.Initialize
		rules=SRX.readRules("",sourceLang)
	End If
	
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
	Log(breakPositions)
	Log(nonbreakPositions)
	Log(finalBreakPositions)
	For Each index As Int In finalBreakPositions
		segments.Add(text.SubString2(previousText.Length,index))
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
	For Each rule As Map In rulesList
		Log(rule)

		Dim beforeBreak,afterBreak As String
		beforeBreak=rule.Get("beforebreak")
		afterBreak=rule.Get("afterbreak")

		Dim bbm As Matcher
		bbm=Regex.Matcher2(beforeBreak,32,text)

		If beforeBreak<>"null" Then
			
			Do While bbm.Find
				Log(bbm.Match)
				If afterBreak="null" Then
					breakPositions.Add(bbm.GetEnd(0))
				End If
			
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,text)
				Do While abm.Find
					If bbm.GetEnd(0)=abm.GetStart(0) Then
						breakPositions.Add(abm.GetEnd(0))
						Exit
					End If
				Loop
			Loop
		Else if afterBreak<>"null" Then
			Dim abm As Matcher
			abm=Regex.Matcher2(afterBreak,32,text)
			Do While abm.Find
				breakPositions.Add(abm.GetEnd(0))
			Loop
		End If
	Next
	
	Return breakPositions
End Sub

Public Sub segmentedTxtSimpleway(text As String,Trim As Boolean,sourceLang As String,filetype As String) As List
	
	File.WriteString(File.DirApp,"1-before",text)
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
	File.WriteString(File.DirApp,"1-after",after)
	Return out
End Sub