B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public terminology As KeyValueStore
	Private externalTerminology As KeyValueStore
	Private sourceLanguage As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String,source As String)
	terminology.Initialize(File.Combine(projectPath,"Term"),"term.db")
	externalTerminology.Initialize(File.Combine(projectPath,"Term"),"external-term.db")
	sourceLanguage=source
End Sub


Public Sub deleteExternalTerminology
	externalTerminology.DeleteAll
End Sub

Public Sub importExternalTerminology(termList As List)
	progressDialog.Show("Loading external terminology","loadterm")
	Dim termsMap As Map
	termsMap.Initialize
	For Each termfile As String In termList
		If termfile.EndsWith(".txt") Then
			importedTxt(termfile,termsMap)
		Else if termfile.EndsWith(".tbx") Then
			TBX.readTermsIntoMap(File.Combine(File.Combine(Main.currentProject.path,"Term"),termfile),sourceLanguage,Main.currentProject.projectFile.Get("target"),termsMap)
		End If
	Next

	If termsMap.Size<>0 Then
		Dim index As Int=0
		For Each source As String In termsMap.Keys
			index=index+1
			Sleep(0)
			progressDialog.update(index,termsMap.Size)
			externalTerminology.put(source,termsMap.Get(source))
		Next
	End If
	progressDialog.close
End Sub


Sub importedTxt(filename As String,termsMap As Map)
	Dim content As String
	content=File.ReadString(File.Combine(Main.currentProject.path,"Term"),filename)
	Dim segments As List
	segments=Regex.Split(CRLF,content)
	Dim result As List
	result.Initialize
	For Each line As String In segments

		Dim targetMap As Map
		targetMap.Initialize
		Dim source,target,descrip As String

		source=Regex.Split("	",line)(0)
		target=Regex.Split("	",line)(1)
		descrip=Regex.Split("	",line)(2)
		targetMap.Put(target,descrip)
		termsMap.Put(source,targetMap)
	Next
End Sub


Public Sub termsInASentence(sentence As String) As List
	Dim result As List
	result.Initialize
	For i=0 To 1 
		Dim kvs As KeyValueStore
		Select i 
			Case 0 
				kvs=terminology
			Case 1
				kvs=externalTerminology
		End Select
		
		For Each source As String In kvs.ListKeys
			If Regex.Matcher("\b"&source&"\b",sentence).Find=False Then
				If Main.nlp.IsInitialized And sourceLanguage="en" Then
					Dim lemmatized As String
					lemmatized=Main.nlp.lemmatizedSentence(source)
					If Regex.Matcher("\b"&lemmatized&"\b",sentence).Find=False Then
						Continue
					End If
				End If
			End If

			Dim targetMap As Map
			targetMap=kvs.Get(source)
			For Each target As String In targetMap.Keys
				Dim oneterm As List
				oneterm.Initialize
				oneterm.Add(source)
				oneterm.Add(target)
				oneterm.Add(targetMap.Get(target))
				result.Add(oneterm)
			Next
		Next
	Next
	
	Return result
End Sub

Sub termsInASentenceOld(sentence As String) As List
	Dim result As List
	result.Initialize
	If sourceLanguage="en" Then
		Log(sentence)
		sentence=Regex.Replace("[\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]",sentence,"")
		'Log(sentence)
		Dim words() As String
		words=Regex.Split(" ",sentence)
		For Each word As String In words
			'Log(word)
			If terminology.ContainsKey(word) Then
				Dim oneterm As List
				oneterm.Initialize
				oneterm.Add(word)
				oneterm.Add(terminology.Get(word))
				result.Add(oneterm)
			End If
		Next
	Else
		
	End If
	Return result
End Sub

Sub addTerm(source As String,target As String)
	Dim targetMap As Map
	targetMap.Initialize
	If terminology.ContainsKey(source) Then
		targetMap=terminology.Get(source)
	End If
	Dim termInfo As Map
	termInfo.Initialize
	targetMap.Put(target,termInfo)
	terminology.Put(source,targetMap)
End Sub

