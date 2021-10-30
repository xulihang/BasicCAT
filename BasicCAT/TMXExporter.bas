B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub


public Sub export(segments As List,sourceLang As String,targetLang As String,path As String,includeTag As Boolean,isTMXTags As Boolean)
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
				seg=XMLUtils.TagsRemoved(seg,False)
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

private Sub setNodeText(node As XmlNode,text As String,isTMXTags As Boolean)
	If isTMXTags=True Then
		Try
			text=XMLUtils.HandleXMLEntities(text,True)
			text=Regex.Replace2("`(&lt;.*?&gt;)`",32,text,"$1")
			node.innerXML=convertToTMXTags(text)
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

private Sub convertToTMXTags(xml As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim matcher As Matcher
	matcher=Regex.Matcher("</*(.*?)(\d+) */*>",xml)
	Dim previousEndIndex As Int=0
	Do While matcher.Find
		sb.Append(xml.SubString2(previousEndIndex,matcher.GetStart(0)))
		previousEndIndex=matcher.GetEnd(0)
		If matcher.Group(1).StartsWith("g") Then
			Dim id As Int
			id=matcher.Group(2)
			If matcher.match.Contains("/") Then
				sb.Append($"<ept i="${id}">"$)
				sb.Append(XMLUtils.EscapeXml(matcher.match))
				sb.Append("</ept>")
			Else
				sb.Append($"<bpt i="${id}">"$)
				sb.Append(XMLUtils.EscapeXml(matcher.match))
				sb.Append("</bpt>")
			End If
		Else If matcher.Group(1).StartsWith("x") Then
			sb.Append("<ph>")
			sb.Append(XMLUtils.EscapeXml(matcher.Match))
			sb.Append("</ph>")
		Else
			sb.Append(matcher.Match)
		End If
	Loop
	If previousEndIndex<>xml.Length-1 Then
		sb.Append(xml.SubString2(previousEndIndex,xml.Length))
	End If
	Return sb.ToString
End Sub

private Sub CreateNode(name As String) As XmlNode
	Dim node As XmlNode
	node.Initialize
	node.Name=name
	node.Attributes.Initialize
	node.Children.Initialize
	Return node
End Sub
