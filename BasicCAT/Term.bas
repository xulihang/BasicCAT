B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private terminology As KeyValueStore
	Private dictionary As KeyValueStore
	Private sourceLanguage As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String,source As String)
	terminology.Initialize(File.Combine(projectPath,"Term"),"term.db")
	dictionary.Initialize(File.Combine(projectPath,"Term"),"dict.db")
	sourceLanguage=source
End Sub

Sub termsInASentence(sentence As String) As List
	Dim result As List
	result.Initialize
	If sourceLanguage="EN" Then
		Log(sentence)
		sentence=Regex.Replace("[\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]",sentence,"")
		Log(sentence)
		Dim words() As String
		words=Regex.Split(" ",sentence)
		For Each word As String In words
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
	terminology.Put(source,target)
End Sub