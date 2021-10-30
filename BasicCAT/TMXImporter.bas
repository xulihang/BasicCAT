B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
Sub Class_Globals
	Private sax As SaxParser
	Private tuvs As List
	Private tus As List
	Private aSourceLang,aTargetLang As String
	Private numbers As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub

private Sub parse(dir As String,filename As String)
	tus.Initialize
	tuvs.Initialize
	sax.Initialize
	Dim in As InputStream
	in = File.OpenInput(dir, filename) 'This file was added with the file manager.
	sax.Parse(in, "Parser") '"Parser" is the events subs prefix.
	in.Close
	'Log("tus:"&tus)
End Sub

private Sub Parser_StartElement (Uri As String, Name As String, Attributes As Attributes)
	If Name="tuv" Or Name="tu" Then
		Dim map1 As Map
		map1.Initialize
		Dim attr As Map
		attr.Initialize
		For i=0 To Attributes.Size-1
			attr.Put(Attributes.GetName(i),Attributes.GetValue(i))
		Next
		map1.Put("Attributes",attr)
		Select Name
			Case "tuv"
				tuvs.Add(map1)
			Case "tu"
				tus.Add(map1)
		End Select
		
	End If
End Sub

private Sub Parser_EndElement (Uri As String, Name As String, Text As StringBuilder)
	If Name="seg" Then
		numbers=numbers+1
		Dim map1 As Map = tuvs.Get(tuvs.Size-1)
		Dim Attributes As Map =map1.Get("Attributes")
		'Log(Attributes.GetValue2("","xml:lang"))
		Dim lang As String
		If Attributes.ContainsKey("xml:lang") Then
			lang=Attributes.Get("xml:lang")
		else if Attributes.ContainsKey("lang") Then
			lang=Attributes.Get("lang")
		End If
		'Log("lang: "&lang)
		If lang.StartsWith(aSourceLang) Or lang.StartsWith(aTargetLang) Then
			map1.Put("Text",Text.ToString)
		Else
			tuvs.RemoveAt(tuvs.Size-1)
		End If
		'Log(map1)
		'Log(numbers)
	else if Name="note" Then
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("note",Text.ToString)
	Else if Name = "tu" Then
		Dim newList As List
		newList.Initialize
		newList.AddAll(tuvs)
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("tuv",newList)
		tuvs.Clear
	End If
End Sub

public Sub importedList(dir As String,filename As String, sourceLang As String,targetLang As String,quickMode As Boolean) As List
	If quickMode Then
		Return importedListQuick(dir,filename,sourceLang,targetLang)
	Else
		Return importedListAccurate(dir,filename,sourceLang,targetLang)
	End If
End Sub

public Sub importedListQuick(dir As String,filename As String, sourceLang As String,targetLang As String) As List
	Dim segments As List
	segments.Initialize
	parse(dir,filename)
	For Each tu As Map In tus
		Dim tuvList As List= tu.Get("tuv")
		Dim newtu As Map
		newtu.Initialize
		Dim targetMap As Map
		targetMap.Initialize
		For Each tuv As Map In tuvList
			Dim Attributes As Map =tuv.Get("Attributes")
			'Log(Attributes.GetValue2("","xml:lang"))
			Dim lang As String
			If Attributes.ContainsKey("xml:lang") Then
				lang=Attributes.Get("xml:lang")
			else if Attributes.ContainsKey("lang") Then
				lang=Attributes.Get("lang")
			End If
			newtu.Put(lang,tuv.Get("Text"))
		Next

		If tu.ContainsKey("note") Then
			newtu.Put("note",tu.Get("note"))
		End If
		Dim segment As List
		segment.Initialize
		segment.Add(newtu.Get(sourceLang))
		segment.Add(newtu.Get(targetLang))
		segment.Add(filename)
		segment.Add(targetMap)
		segments.Add(segment)
	Next
	Return segments
End Sub


public Sub getTransUnits(xml As String) As List
	Dim parser As XmlParser
	parser.Initialize
	Dim root As XmlNode=XMLUtils.Parse(xml)
	Dim body As XmlNode=root.Get("body").Get(0)
	Dim tus As List=body.Get("tu")
	Return tus
End Sub

public Sub importedListAccurate(dir As String, filename As String, sourceLang As String,targetLang As String) As List
	Dim xml As String=File.ReadString(dir,filename)
	Return importedAccurateList2(xml,filename,sourceLang,targetLang)
End Sub

public Sub importedAccurateList2(xml As String,filename As String,sourceLang As String,targetLang As String) As List
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
				segment.Set(0,getSegText(seg))
				addedTimes=addedTimes+1
			else if lang.StartsWith(targetLang) Then
				segment.Set(1,getSegText(seg))
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

private Sub getSegText(seg As XmlNode) As String
	If XMLUtils.XmlNodeContainsOnlyText(seg) Then
		Dim text As String=XMLUtils.XmlNodeText(seg)
		Return text
	End If
	Return XMLUtils.XMLToText(removeTMXTags(seg.innerXML))
End Sub

private Sub removeTMXTags(s As String) As String
	'<bpt i="1">&lt;g1&gt;</bpt>
	Dim sb As StringBuilder
	sb.Initialize
	Dim parts As List
	parts.Initialize
	Dim tags As String
	tags="(bpt|ept|ph)"
	Dim previousEndIndex As Int=0
	Dim matcher As Matcher
	matcher=Regex.Matcher($"<${tags}.*?>(.*?)</${tags}>"$,s)
	Do While matcher.Find
		Dim textBefore As String
		textBefore=s.SubString2(previousEndIndex,matcher.GetStart(0))
		If textBefore<>"" Then
			parts.Add(textBefore)
		End If
		parts.add(XMLUtils.UnescapeXml(matcher.Group(2)))
		previousEndIndex=matcher.GetEnd(0)
	Loop
	Dim textAfter As String
	textAfter=s.SubString2(previousEndIndex,s.Length)
	If textAfter<>"" Then
		parts.Add(textAfter)
	End If
	For Each part As String In parts
		sb.Append(part)
	Next
	Return Regex.Replace($"<${tags}.*?>"$,sb.ToString,"")
End Sub
