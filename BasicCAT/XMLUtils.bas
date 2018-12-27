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
	Log("es"&tagName)
	Dim pattern As String
	pattern="<"&tagName&"\b.*?>(.*?)</"&tagName&">"
	Dim new As String
	new=xmlstring
	Dim sourceMatcher As Matcher
	sourceMatcher=Regex.Matcher2(pattern,32,new)
	Dim replaceList As List
	replaceList.Initialize

	Do While sourceMatcher.Find
		Log("match"&sourceMatcher.Match)
		Dim group As String=sourceMatcher.Group(1)
		Dim escapedGroup As String=escapeInlineTag(group,filetype)
		If escapedGroup<>group Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",sourceMatcher.GetStart(1))
			replacement.Put("end",sourceMatcher.GetEnd(1))
			replacement.Put("group",escapedGroup)
			replaceList.InsertAt(0,replacement)
		End If
	Loop
	Log(replaceList)
	

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
	Log("esd"&tagName)
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
		If unescapedGroup<>group Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",sourceMatcher.GetStart(1))
			replacement.Put("end",sourceMatcher.GetEnd(1))
			replacement.Put("group",unescapedGroup)
			replaceList.InsertAt(0,replacement)
		End If
	Loop
	Log(replaceList)
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