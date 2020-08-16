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

Sub getTransUnits(xml As String) As List
	Dim parser As XmlParser
	parser.Initialize
	Dim root As XmlNode=XMLUtils.Parse(xml)
	Dim body As XmlNode=root.Get("body").Get(0)
	Dim tus As List=body.Get("tu")
	Return tus
End Sub

Sub importedList(dir As String, filename As String, sourceLang As String,targetLang As String) As List
	Dim xml As String=File.ReadString(dir,filename)
	Return importedList2(xml,filename,sourceLang,targetLang)
End Sub

Sub importedList2(xml As String,filename As String,sourceLang As String,targetLang As String) As List
	Dim segments As List
	segments.Initialize
	sourceLang=sourceLang.ToLowerCase
	targetLang=targetLang.ToLowerCase
	Dim tus As List=getTransUnits(xml)
	For Each tu As XmlNode In tus
		Dim tuvList As List= tu.Get("tuv")
		Dim segment As List
		segment.Initialize
		Dim targetMap As Map
		targetMap.Initialize
		segment.Add("source")
		segment.Add("target")
		Dim addedTimes As Int=0
		For Each tuv As XmlNode In tuvList
			Dim lang As String
			Dim seg As XmlNode=tuv.Get("seg").Get(0)
			If tuv.Attributes.ContainsKey("xml:lang") Then
				lang=tuv.Attributes.Get("xml:lang")
			else if tuv.Attributes.ContainsKey("lang") Then
				lang=tuv.Attributes.Get("lang")
			End If
			lang=lang.ToLowerCase
			If lang.StartsWith(sourceLang) Then
				segment.Set(0,removeTMXTags(seg.innerText))
				addedTimes=addedTimes+1
			else if lang.StartsWith(targetLang) Then
				segment.Set(1,removeTMXTags(seg.innerText))
				addedTimes=addedTimes+1
			Else
				Continue
			End If
			If tuv.Attributes.ContainsKey("creationid") And tuv.Attributes.ContainsKey("creationdate") Then
				Try
					Dim creationdate As String
					creationdate=tuv.Attributes.Get("creationdate")
					DateTime.DateFormat="yyyyMMdd"
					DateTime.TimeFormat="HHmmss"
					Dim date As String
					Dim time As String
					date=creationdate.SubString2(0,creationdate.IndexOf("T"))
					time=creationdate.SubString2(creationdate.IndexOf("T")+1,creationdate.IndexOf("Z"))
					targetMap.Put("createdTime",DateTime.DateTimeParse(date,time))
					targetMap.Put("creator",tuv.Attributes.Get("creationid"))
				Catch
					Log(LastException)
				End Try
			End If
		Next
		If addedTimes<>2 Then
			Continue
		End If
		If tu.Contains("note") Then
			Dim node As XmlNode=tu.Get("note").Get(0)
			targetMap.Put("note",node.innerText)
		End If
		segment.Add(filename)
		segment.Add(targetMap)
		segments.Add(segment)
	Next
	Return segments
End Sub

Sub removeTMXTags(text As String) As String
	Dim tags As String
	tags="(bpt|ept)"
	text=Regex.Replace2($"</*${tags}.*?>"$,32,text,"")
	Return text
End Sub

Sub CreateNode(name As String) As XmlNode
	Dim node As XmlNode
	node.Initialize
	node.Name=name
	node.Attributes.Initialize
	node.Children.Initialize
	Return node
End Sub

Sub export(segments As List,sourceLang As String,targetLang As String,path As String,includeTag As Boolean,isTMXTags As Boolean)
	Dim tmxNode As XmlNode
	tmxNode=CreateNode("tmx")
	tmxNode.Attributes.Put("version","1.4")
	Dim header As XmlNode
	header=CreateNode("header")
	header.Attributes.Put("creationtool","BasicCAT")
	header.Attributes.Put("creationtoolversion","1.0.0")
	header.Attributes.put("adminlang",sourceLang)
	header.Attributes.put("srclang",sourceLang)
	header.Attributes.put("segtype","sentence")
	header.Attributes.put("o-tmf","BasicCAT")
	Dim body As XmlNode
	body=CreateNode("body")
	Dim tuList As List
	tuList.Initialize
	For Each segment As List In segments
		Dim tu As XmlNode
		tu=CreateNode("tu")
		Dim tuvList As List
		tuvList.Initialize
		Dim targetMap As Map
		targetMap=segment.Get(2)
		For i=0 To 1
			Dim seg As String=segment.Get(i)
			If includeTag=False Then
				seg=Regex.Replace2("<.*?>",32,seg,"")
			End If
			If i = 1 Then
				Dim targetTuv As XmlNode
				targetTuv=CreateNode("tuv")
				targetTuv.Attributes.Put("xml:lang",targetLang)
				If targetMap.ContainsKey("creator") Then
					targetTuv.attributes.Put("creationid",targetMap.Get("creator"))
				End If
				If targetMap.ContainsKey("createdTime") Then
					Dim creationDate As String
					DateTime.DateFormat="yyyyMMdd"
					DateTime.TimeFormat="HHmmss"
					creationDate=DateTime.Date(targetMap.Get("createdTime"))&"T"&DateTime.Time(targetMap.Get("createdTime"))&"Z"
					targetTuv.attributes.Put("creationdate",creationDate)
				End If
				Dim segNode As XmlNode
				segNode=CreateNode("seg")
				setNodeText(segNode,seg,isTMXTags)
				targetTuv.Children.Add(segNode)
				tuvList.Add(targetTuv)
			Else if i = 0 Then
				Dim sourceTuv As XmlNode
				sourceTuv=CreateNode("tuv")
				sourceTuv.Attributes.Put("xml:lang",sourceLang)
				Dim segNode As XmlNode
				segNode=CreateNode("seg")
				setNodeText(segNode,seg,isTMXTags)
				sourceTuv.Children.Add(segNode)
				tuvList.Add(sourceTuv)
			End If
		Next
		If targetMap.ContainsKey("note") Then
			If targetMap.Get("note")<>"" Then
				Dim note As XmlNode
				note=CreateNode("note")
				Dim textNode As XmlNode
				textNode=CreateNode("text")
				textNode.Text=targetMap.Get("note")
				note.Children.Add(textNode)
				tu.Children.InsertAt(0,note)
			End If
		End If
		tu.Children.AddAll(tuvList)
		tuList.Add(tu)
	Next
	body.Children=tuList
	tmxNode.Children.Add(header)
	tmxNode.Children.Add(body)
	File.WriteString(path,"",XMLUtils.asString(tmxNode))
End Sub

Sub setNodeText(node As XmlNode,text As String,isTMXTags As Boolean)
	If isTMXTags=True Then
		Try
			node.innerXML=convertToTMXTags(XMLUtils.HandleXMLEntities(text,True))
			Return
		Catch
			Log(LastException)
		End Try
    End If
	node.Children.Clear
	Dim textNode As XmlNode
	textNode.Initialize
	textNode.Name="text"
	textNode.Text=text
	node.Children.Add(textNode)
End Sub

Sub convertToTMXTags(xml As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim matcher As Matcher
	matcher=Regex.Matcher("</*(.*?)(\d+) *>",xml)
	Dim previousEndIndex As Int=0
	Do While matcher.Find
		sb.Append(xml.SubString2(previousEndIndex,matcher.GetStart(0)))
		previousEndIndex=matcher.GetEnd(0)
		If matcher.Group(1).StartsWith("g") Then
			Dim id As Int=matcher.Group(2)
			If matcher.match.Contains("/") Then
				sb.Append($"<ept i="${id}">"$)
				sb.Append(XMLUtils.EscapeXml(matcher.match))
				sb.Append("</ept>")
			Else
				sb.Append($"<bpt i="${id}">"$)
				sb.Append(XMLUtils.EscapeXml(matcher.match))
				sb.Append("</bpt>")
			End If
		Else
			sb.Append(matcher.Match)
		End If
	Loop
	If previousEndIndex<>xml.Length-1 Then
		sb.Append(xml.SubString2(previousEndIndex,xml.Length))
	End If
	Return sb.ToString
End Sub