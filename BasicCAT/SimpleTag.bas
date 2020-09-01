B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private index As Int
	Private xml As String
	Type Tag(html As String,name As String,ID As Int,kind As Int,index As Int)
	Private TagsCount As Map
	Private StartTags As List
	'self-closing <x/>
	'tagPair <g id="1"><x/></g> <g1><g1/>
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	StartTags.Initialize
	TagsCount.Initialize
End Sub


Public Sub Convert(pXml As String,revert As Boolean,original As String) As String
	Try
		TagsCount.Clear
		Dim tags As List=getTags(pXml)
		If tags.Size=0 Then
			Return pXml
		End If
		Dim originalTags As List=getTags(original)
		Dim parts As List
		parts.Initialize
		Dim previousEndIndex As Int=0
		For i=0 To tags.Size-1
			Dim tag As Tag=tags.Get(i)
			Dim textBefore As String=pXml.SubString2(previousEndIndex,tag.index)
			If textBefore<>"" Then
				parts.Add(textBefore)
			End If
			If revert Then
				parts.Add(FindEquavalentTag(tag,originalTags).html)
			Else
				parts.Add(SimplifiedTagString(tag))
			End If
		
			previousEndIndex=tag.index+tag.html.Length
		Next
		Dim textAfter As String
		textAfter=pXml.SubString2(previousEndIndex,pXml.Length)
		If textAfter<>"" Then
			parts.Add(textAfter)
		End If
		Dim sb As StringBuilder
		sb.Initialize
		For Each s As String In parts
			sb.Append(s)
		Next
		Return sb.ToString
	Catch
		Log(LastException)
	End Try
	Return pXml
End Sub

Sub FindEquavalentTag(tag As Tag,originalTags As List) As Tag
	For Each originaltag As Tag In originalTags
		Dim subtractedName As String=tag.name
		Dim id As Int=-1
		For i=0 To tag.name.Length-1
			If IsNumber(tag.name.CharAt(i))=True Then
				Try
					id=subtractedName.SubString2(i,tag.name.Length)
					subtractedName=subtractedName.SubString2(0,i)
				Catch
					Log(LastException)
				End Try
				Exit
			End If
		Next
		If id=originaltag.ID And subtractedName=originaltag.name And tag.kind=originaltag.kind Then
			Return originaltag
		End If
	Next
	Return tag
End Sub

Sub SimplifiedTagString(tag As Tag) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<")
	If tag.kind=TagKind.EndTag Then
		sb.Append("/")
	End If
	sb.Append(tag.name)
	sb.Append(tag.ID)
	If tag.kind=TagKind.SelfClosingTag Then
		sb.Append("/")
	End If
	sb.Append(">")
	Return sb.ToString
End Sub


Public Sub getTags(pXml As String) As List
	StartTags.Clear
	xml=pXml
	Dim tagsList As List
	tagsList.Initialize
	For index=0 To xml.Length-1
		If CurrentChar="<" Then
			If PreviousChar="`" Then 'do not process tags like `<g>` 
				If HasClosingBackquote(TextUntil("`")) Then
					Continue
				End If
			End If
			Dim result As Map=getTagNameAndKind(TextUntil(">"))
			If result.ContainsKey("name") Then
				If isXLIFFTag(result.Get("name")) Then
					Dim kind As Int=result.Get("kind")
					If kind=TagKind.StartTag Then
						tagsList.Add(TagStart(result))
					Else
						tagsList.Add(TagEnd(result))
					End If
				End If
			End If
		End If
	Next
	Return tagsList
End Sub

Sub HasClosingBackquote(s As String) As Boolean
	If s.IndexOf("<")<>s.LastIndexOf("<") Then
		Return False
	End If
	If (s.IndexOf(">")+1)=s.IndexOf("`") Then
		Return True
	Else
		Return False
	End If
End Sub

Sub isXLIFFTag(tagName As String) As Boolean
	For Each name As String In Regex.Split(",","bpt,ept,it,ph,g,bx,ex,x,sub,mrk")
		If Regex.Replace("\d",tagName,"")=name Then
			Return True
		End If
	Next
	Return False
End Sub

Sub CreateTag(result As Map) As Tag
	Dim tag As Tag
	tag.Initialize
	tag.html=TextUntil(">")
	tag.name=result.Get("name")
	tag.kind=result.Get("kind")
	tag.ID=TagsCount.GetDefault(tag.name,0)+1
	tag.index=index
	Return tag
End Sub

Sub TagStart(result As Map) As Tag
	Dim tag As Tag=CreateTag(result)
	StartTags.Add(tag)
	IncreaseCount(tag)
	Return tag
End Sub

Sub IncreaseCount(tag As Tag)
	Dim count As Int=TagsCount.GetDefault(tag.name,0)
	count=count+1
	TagsCount.Put(tag.name,count)
End Sub

Sub TagEnd(result As Map) As Tag
	Dim tag As Tag=CreateTag(result)
	If result.Get("kind")=TagKind.EndTag Then
		Try
			Dim StartTag As Tag
			StartTag=StartTags.Get(StartTags.Size-1)
			StartTags.RemoveAt(StartTags.Size-1)
			tag.ID=StartTag.ID
		Catch
			Log(LastException)
			tag.ID=-1
		End Try
	Else
		IncreaseCount(tag)
	End If
	Return tag
End Sub


Sub getTagNameAndKind(tagHtml As String) As Map
	Dim result As Map
	result.Initialize
	Dim kind As Int
	Dim name As String
	If tagHtml.Contains(">")=False Then
		Return result
	End If
	If tagHtml.SubString2(1,tagHtml.Length).Contains("<") Then
		Return result
	End If
	If tagHtml.Contains("/") Then 'end tag <x1/></g>
		If tagHtml.LastIndexOf("/")+1=tagHtml.LastIndexOf(">") Then
			kind=TagKind.SelfClosingTag
			If tagHtml.Contains(" ") Then
				name=tagHtml.SubString2(1,tagHtml.IndexOf(" "))
			Else
				name=tagHtml.SubString2(1,tagHtml.IndexOf("/"))
			End If
		Else
			kind=TagKind.EndTag
			name=tagHtml.SubString2(tagHtml.IndexOf("/")+1,tagHtml.LastIndexOf(">"))
		End If
	Else 'start tag <g id="1"> <g1>
		kind=TagKind.StartTag
		If tagHtml.Contains(" ") Then
			name=tagHtml.SubString2(1,tagHtml.IndexOf(" "))
		Else
			name=tagHtml.SubString2(1,tagHtml.IndexOf(">"))
		End If
	End If
	result.Put("kind",kind)
	result.Put("name",name)
	Return result
End Sub

Sub TextUntil(EndStr As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim textLeft As String=xml.SubString2(index,xml.Length)
	If textLeft.Contains(EndStr) Then
		For i=index To xml.Length-1
			Dim s As String=xml.CharAt(i)
			sb.Append(s)
			If s=EndStr Then
				Exit
			End If
		Next
	End If
	Return sb.ToString
End Sub

Sub CurrentChar As String
	Return xml.CharAt(index)
End Sub


Sub PreviousChar As String
	Try
		If index>0 Then
			Return xml.CharAt(index-1)
		Else
			Return ""
		End If
	Catch
		Log(LastException)
	End Try
    Return ""
End Sub
