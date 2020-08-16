B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private Entities As Map
End Sub


Public Sub HandleXMLEntities(xml As String,escape As Boolean) As String
	Dim st As SimpleTag
	st.Initialize
	Dim tags As List=st.getTags(xml)
	If tags.Size=0 Then
		If escape Then
			Return EscapeXml(xml)
		Else
			Return UnescapeXml(xml)
		End If
	End If
	Dim parts As List
	parts.Initialize
	Dim previousEndIndex As Int=0
	For i=0 To tags.Size-1
		Dim tag As Tag=tags.Get(i)
		Dim textBefore As String=xml.SubString2(previousEndIndex,tag.index)
		If escape Then
			textBefore=EscapeXml(textBefore)
		Else
			textBefore=UnescapeXml(textBefore)
		End If
		
		If textBefore<>"" Then
			parts.Add(textBefore)
		End If
		parts.Add(tag.html)
		previousEndIndex=tag.index+tag.html.Length
	Next
	Dim textAfter As String
	textAfter=xml.SubString2(previousEndIndex,xml.Length)
	If textAfter<>"" Then
		If escape Then
			textAfter=EscapeXml(textAfter)
		Else
			textAfter=UnescapeXml(textAfter)
		End If
		parts.Add(textAfter)
	End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each s As String In parts
		sb.Append(s)
	Next
	Return sb.ToString
End Sub


Public Sub EscapeXml(Raw As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To Raw.Length - 1
		Dim c As Char = Raw.CharAt(i)
		Select c
			Case QUOTE
				sb.Append("&quot;")
			Case "'"
				sb.Append("&apos;")
			Case "<"
				sb.Append("&lt;")
			Case ">"
				sb.Append("&gt;")
			Case "&"
				sb.Append("&amp;")
			Case Else
				sb.Append(c)
		End Select
	Next
	Return sb.ToString
End Sub

Public Sub UnescapeXml(Raw As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim i As Int=0
	Dim n As Int=Raw.Length
	Do While i<n
		Dim appended As Boolean=False
		For Each key As String In getEntitiesMap.Keys
			If i+key.Length>n Then
				Continue
			End If
			Dim str As String=Raw.SubString2(i,i+key.Length)
			If str=key Then
				sb.Append(getEntitiesMap.Get(key))
				i=i+key.Length
				appended=True
				Exit
			End If
		Next
		If appended=False Then
			sb.Append(Raw.CharAt(i))
			i=i+1
		End If
	Loop
	Return sb.ToString
End Sub

Sub getEntitiesMap As Map
	If Entities.IsInitialized=False Then
		Entities.Initialize
		Entities.Put("&quot;",QUOTE)
		Entities.Put("&apos;","'")
		Entities.Put("&lt;","<")
		Entities.Put("&gt;",">")
		Entities.Put("&amp;","&")
	End If
	Return Entities
End Sub


Sub printChild(node As XmlNode)
	For Each children As XmlNode In node.Children
		Log(children.Name)
		printChild(children)
	Next
End Sub


Sub parse(xml As String) As XmlNode
	Dim parser As XmlParser
	parser.Initialize
	Dim root As XmlNode = parser.Parse(xml)
	If root.Children.Size=1 Then
		root=root.Children.Get(0)
		If root.Name="?xml" Then
			root=root.Children.Get(0)
		End If
	End If
	Return root
End Sub

Sub asString(Node As XmlNode) As String
	Dim builder As XMLBuilder2
	builder.Initialize
	buildNode(builder,Node,builder.Doc)
	Return builder.asString
End Sub

Sub asStringWithoutXMLHead(node As XmlNode) As String
	Return asString(node).Replace($"<?xml version="1.0" encoding="UTF-8" standalone="no"?>"$,"")
End Sub

Sub buildNode(builder As XMLBuilder2, node As XmlNode,Parent As JavaObject) As JavaObject
	Dim element As JavaObject=builder.e(node.Name)
	setAttr(builder,element,node.Attributes)
	builder.appendChild(Parent,element)
	For Each child As XmlNode In node.Children
		Dim childNode As JavaObject
		If child.Name="text" Then
			childNode=builder.t(child.Text)
		Else
			childNode=buildNode(builder,child,element)
		End If
		builder.appendChild(element,childNode)
	Next
	Return element
End Sub

Sub setAttr(builder As XMLBuilder2, element As JavaObject, attributes As Map)
	If attributes.IsInitialized Then
		For Each key As String In attributes.Keys
			builder.setAttributeNode(builder.createAttribute(key,attributes.Get(key)),element)
		Next
	End If
End Sub

Sub getXmlMap(xmlstring As String) As Map
	Dim ParsedData As Map
	Dim xm As Xml2Map
	xm.Initialize
	ParsedData = xm.Parse(xmlstring)
	Return ParsedData
End Sub

Sub getXmlFromMap(map1 As Map) As String
	Dim mx As Map2Xml
	mx.Initialize
	Return mx.MapToXml(map1)
End Sub

Sub getXmlFromMapWithoutIndent(map1 As Map) As String
	Dim mx As Map2Xml
	mx.Initialize
	Return mx.MapToXmlWithoutIndent(map1)
End Sub

Sub GetElements (m As Map, key As String) As List
	Dim res As List
	If m.ContainsKey(key) = False Then
		res.Initialize
		Return res
	Else
		Dim value As Object = m.Get(key)
		If value Is List Then Return value
		res.Initialize
		res.Add(value)
		Return res
	End If
End Sub

Sub escapedText(xmlstring As String,tagName As String,filetype As String) As String
	'Log("es"&tagName)
	Dim pattern As String
	pattern="<"&tagName&"\b.*?>(.*?)</"&tagName&">"
	Dim new As String
	new=xmlstring
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2(pattern,32,new)
	Dim replaceList As List
	replaceList.Initialize

	Do While sourceMatcher.Find
		'Log("match"&sourceMatcher.Match)
		Dim group As String=sourceMatcher.Group(1)
		Dim escapedGroup As String=escapeInlineTag(group,filetype)
		If escapedGroup.EqualsIgnoreCase(group)=False Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",sourceMatcher.GetStart(1))
			replacement.Put("end",sourceMatcher.GetEnd(1))
			replacement.Put("group",escapedGroup)
			replaceList.InsertAt(0,replacement)
		End If
	Loop
	'Log(replaceList)
	

	For Each replacement As Map In replaceList
		Dim startIndex,endIndex As Int
		Dim group As String
		startIndex=replacement.Get("start")
		endIndex=replacement.Get("end")
		group=replacement.Get("group")
	    Dim sb As StringBuilder
		sb.Initialize
		sb.Append(new.SubString2(0,startIndex))
		sb.Append(group)
		sb.Append(new.SubString2(endIndex,new.Length))
		new=sb.ToString
	Next
	'Log("esd"&tagName)
	'Log(new)
	Return new
End Sub

Sub unescapedText(xmlstring As String,tagName As String,filetype As String) As String
	Dim pattern As String
	pattern="<"&tagName&"\b.*?>(.*?)</"&tagName&">"
	Dim new As String
	new=xmlstring
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2(pattern,32,new)
	Dim replaceList As List
	replaceList.Initialize
		
	Do While sourceMatcher.Find
		Dim group As String=sourceMatcher.Group(1)
		Dim unescapedGroup As String=unescapeInlineTag(group,filetype)
		If unescapedGroup.EqualsIgnoreCase(group)=False Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",sourceMatcher.GetStart(1))
			replacement.Put("end",sourceMatcher.GetEnd(1))
			replacement.Put("group",unescapedGroup)
			replaceList.InsertAt(0,replacement)
		End If
	Loop
	'Log(replaceList)
	For Each replacement As Map In replaceList
		Dim startIndex,endIndex As Int
		Dim group As String
		startIndex=replacement.Get("start")
		endIndex=replacement.Get("end")
		group=replacement.Get("group")
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(new.SubString2(0,startIndex))
		sb.Append(group)
		sb.Append(new.SubString2(endIndex,new.Length))
		new=sb.ToString
	Next

	Return new
End Sub

Sub escapeInlineTag(text As String,filetype As String) As String
	Dim tags As String
	If filetype="xliff" Then
		tags="(bpt|ept|it|ph|g|bx|ex|x|sub|mrk)"
	else if filetype="tmx" Then
		tags="(bpt|ept|hi|it|ph|sub|ut)"
	End If
	
	text=Regex.Replace2("<(/?\b"&tags&"\b.*?)>",32,text,"&lt;$1&gt;")
	text=text.Replace($"""$,"&quot;")
	Return text
End Sub

Sub unescapeInlineTag(text As String,filetype As String) As String
	Dim tags As String
	If filetype="xliff" Then
		tags="(bpt|ept|it|ph|g|bx|ex|x|sub|mrk)"
	else if filetype="tmx" Then
		tags="(bpt|ept|hi|it|ph|sub|ut)"
	End If
	text=text.Replace("&quot;",$"""$)
	text=Regex.Replace2("&lt;(/?\b"&tags&"\b.*?)&gt;",32,text,"<$1>")
	Return text
End Sub

Sub pickSmallerXML(text As String,tag As String,trailTag As String) As String
	Dim xml As String
	Dim matcher As Matcher
	matcher=Regex.Matcher("</\b"&tag&"\b.*?>",text)
	Dim index As Int
	Dim endIndex As Int
	Do While matcher.Find
		index=index+1
		If index>5 Then
			Exit
		End If
		endIndex=matcher.GetEnd(0)+1
	Loop
	xml=text.SubString2(0,endIndex)
	
	matcher=Regex.Matcher("</\b"&trailTag&"\b.*?>",text)
	Dim startIndex As Int
	Do While matcher.Find
		startIndex=matcher.GetStart(0)
	Loop
	xml=xml&text.SubString2(startIndex,text.Length)
	Return xml
End Sub