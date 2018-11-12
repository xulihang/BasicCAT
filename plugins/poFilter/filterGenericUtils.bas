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

Sub tagsRemovedText(text As String) As String
	Return Regex.Replace("<.*?>",text,"")
End Sub

Sub tagsNum(text As String) As Int
	Dim num As Int
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher("<.*?>",text)
	Do While tagMatcher.Find
		num=num+1
	Loop
	Return num
End Sub

Sub tagsAtBothSidesRemovedText(text As String) As String
	Dim textList As List
	textList.Initialize
	text=Regex.replace("<.*?>",text,CRLF&"------$0"&CRLF&"------")
	textList.AddAll(Regex.Split(CRLF&"------",text))

    Dim newList As List
	newList.Initialize
	For Each item As String In textList
		If item<>"" Then
			newList.Add(item)
		End If
	Next

	Do While newList.Size>2 And tagsAreAPair(newList.Get(0),newList.Get(newList.Size-1))
		newList.RemoveAt(0)
		newList.RemoveAt(newList.Size-1)
	Loop
	
	text=""
	For Each item As String In newList
		text=text&item
	Next

	Return text
End Sub

Sub tagsAreAPair(tag1 As String,tag2 As String) As Boolean
	Dim tagType As Int
	Dim tag1Matcher As Matcher
	tag1Matcher=Regex.Matcher($"<.*?id="(.*?)">"$,tag1)
	Dim beginId As Int=-1
	If tag1Matcher.Find Then
		beginId=tag1Matcher.Group(1)
		tagType=0 '<g id="0">
	Else
		tag1Matcher=Regex.Matcher($"<[a-z].*?(\d+)>"$,tag1)
		If tag1Matcher.Find Then
			beginId=tag1Matcher.Group(1)
			tagType=1 '<g1>
		End If
	End If
	Log(beginId)
	Dim tag2Matcher As Matcher
	tag2Matcher=Regex.Matcher($"</[a-z].*?(\d*)>"$,tag2)
	Dim endId As Int=-1
	If tag2Matcher.Find Then
		Try
			endId=tag2Matcher.Group(1)
			Log(endId)
			If endId=beginId And tagType=1 Then
				Return True
			End If
		Catch
			If tagType=0 Then
				Return True
			End If
			Log(LastException)
		End Try
	Else
		Return False
	End If
	Return False
End Sub