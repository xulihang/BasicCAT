B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public terminology As KeyValueStore
	Private dictionary As KeyValueStore
	Private sourceLanguage As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String,source As String)
	terminology.Initialize(File.Combine(projectPath,"Term"),"term.db")
	dictionary.Initialize(File.Combine(projectPath,"Term"),"dict.db")
	sourceLanguage=source
End Sub


Public Sub termsInASentence(sentence As String) As List
	Dim result As List
	result.Initialize
	For Each source As String In terminology.ListKeys
		If sentence.Contains(source)=False Then
            If Main.nlp.IsInitialized And sourceLanguage="en" Then
				Dim lemmatized As String
				lemmatized=Main.nlp.lemmatizedSentence(source)
				If sentence.Contains(lemmatized)=False And sentence<>lemmatized Then
					Continue
			    End If
			End If
		End If

		Dim targetMap As Map
		targetMap=terminology.Get(source)
		For Each target As String In targetMap.Keys
			Dim oneterm As List
			oneterm.Initialize
			oneterm.Add(source)
			oneterm.Add(target)
			result.Add(oneterm)
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