B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub TokenizedList(text As String,sourceLang As String) As List
	text=text.ToLowerCase
	Dim words As List
	words.Initialize
	If Utils.LanguageHasSpace(sourceLang) Then
		text=removePunctuation(text," ")
		words.AddAll(Regex.Split(" ",text))
	Else
		text=removePunctuation(text,"")
		words.AddAll(Regex.Split("",text))
	End If
    'Utils.removeDuplicated(words)
	Dim newList As List
	newList.Initialize
	For Each word As String In words
		If word.Trim="" Then
			Continue
		End If
		newList.Add(word)
	Next
	Return newList
End Sub

Sub addPhrases(words As List)
	Dim iterateList As List
	iterateList.Initialize
	iterateList.AddAll(words)
	For i=1 To 8
		Dim endnum As Int=iterateList.Size-i
		If endnum<=0 Then
			Exit
		End If
		For j=0 To endnum
			Dim word As String
			If j+i>iterateList.Size-1 Then
				Exit
			End If
			For k=j To j+i
				word=word&" "&iterateList.Get(k)
			Next
			word=word.Trim
			If words.IndexOf(word)=-1 Then
				words.Add(word)
			End If
		Next
	Next
End Sub

Sub addHanziWords(source As String) As List
	Dim words As List
	words.Initialize
	For i=1 To 8
		If source.Length-i<=0 Then
			Exit
		End If
		For j=0 To source.Length-i
			If j+i>source.Length Then
				Exit
			End If
			Dim word As String
			word=source.SubString2(j,j+i)
			words.Add(word)
		Next
	Next
	Return words
End Sub

Sub removePunctuation(source As String,replacement As String) As String
	source=Regex.Replace($"[。！？，“”'",\[\]\(\)\.\!\?\*\^\-:;\\|]"$,source,replacement)
	Return source
End Sub

Sub removeMultiBytesWords(words As List)
	Dim newList As List
	newList.Initialize
	For Each word As String In words
		If word.Length>1 Then
			If getBytesLength(word.CharAt(0))>1 Then
				Continue
			End If
		End If
		newList.Add(word)
	Next
	words.Clear
	words.AddAll(newList)
End Sub

Sub removeCharacters(source As List)
	Dim newList As List
	newList.Initialize
	For Each text As String In source
		If text.Length=1 Then
			If Regex.IsMatch("[a-z]",text.ToLowerCase)=True Then
				Continue
			End If
		End If
		newList.Add(text)
	Next
	source.Clear
	source.AddAll(newList)
End Sub

Sub getBytesLength(singleString As String) As Int
	Dim bytes() As Byte
	bytes=singleString.GetBytes("UTF-8")
	Return bytes.Length
End Sub
