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

Sub relaceAtTheRightPosition(source As String,target As String,fullSource As String) As String
	Dim textSegments As List
	textSegments.Initialize
	Utils.splitByFind(fullSource,source,textSegments)
	Dim index As Int=0
	For Each segment As String In textSegments
		If segment=source Then
			Dim newSegments As List
			newSegments.Initialize
			newSegments.AddAll(textSegments)
			newSegments.Set(index,target)
			Dim translation As String
			translation=joinSegments(newSegments)
			If areTagsMatch(fullSource,translation) Then
				Return translation
			End If
		End If
		index=index+1
	Next
	Return fullSource
End Sub

Sub areTagsMatch(text1 As String,text2 As String) As Boolean
	Dim tagsInText1 As List
	tagsInText1.Initialize
	Dim tagMatcher As Matcher=Regex.Matcher("<.*?>",text1)
	Do While tagMatcher.Find
		tagsInText1.Add(tagMatcher.Match)
	Loop
	
	Dim tagsInText2 As List
	tagsInText2.Initialize
	Dim tagMatcher As Matcher=Regex.Matcher("<.*?>",text2)
	Do While tagMatcher.Find
		tagsInText2.Add(tagMatcher.Match)
	Loop
	
	For Each tag As String In tagsInText2
		Try
			tagsInText1.RemoveAt(tagsInText1.IndexOf(tag))
		Catch
			Log(LastException)
		End Try
	Next
    Return tagsInText1.Size=0
End Sub

Sub joinSegments(segments As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	For Each segment As String In segments
		sb.Append(segment)
	Next
	Return sb.ToString
End Sub

Sub tagsRemovedText(text As String) As String
	Return Regex.Replace2("<.*?>",32,text,"")
End Sub

Sub tagsNum(text As String) As Int
	Dim num As Int
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("<.*?>",32,text)
	Do While tagMatcher.Find
		num=num+1
	Loop
	Return num
End Sub

Sub tagsAtBothSidesRemovedText(text As String) As String
	Dim tagscount As Int
	tagscount=tagsNum(text)
	Dim textList As List
	textList.Initialize
	text=Regex.replace2("<.*?>",32,text,CRLF&"------$0"&CRLF&"------")
	textList.AddAll(Regex.Split2(CRLF&"------",32,text))

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
	
	'for single tag
	If tagscount=1 Then
		Dim firstItem,lastItem As String
		Try
			firstItem=newList.Get(0)
			lastItem=newList.Get(newList.Size-1)
			If Regex.IsMatch2("<.*?>",32,firstItem) Then
				newList.RemoveAt(0)
			End If
			If Regex.IsMatch2("<.*?>",32,lastItem) Then
				newList.RemoveAt(newList.Size-1)
			End If
		Catch
			Log(LastException)
		End Try
	End If
	text=""
	For Each item As String In newList
		text=text&item
	Next

	Return text
End Sub

Sub tagsAreAPair(tag1 As String,tag2 As String) As Boolean
	Dim tagType As Int
	Dim tag1Matcher As Matcher
	tag1Matcher=Regex.Matcher2($"<.*?id="(.*?)">"$,32,tag1)
	Dim beginId As Int=-1
	If tag1Matcher.Find Then
		beginId=tag1Matcher.Group(1)
		tagType=0 '<g id="0">
	Else
		tag1Matcher=Regex.Matcher2($"<[a-z].*?(\d+)>"$,32,tag1)
		If tag1Matcher.Find Then
			beginId=tag1Matcher.Group(1)
			tagType=1 '<g1>
		End If
	End If
	Log(beginId)
	Dim tag2Matcher As Matcher
	tag2Matcher=Regex.Matcher2($"</[a-z].*?(\d*)>"$,32,tag2)
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