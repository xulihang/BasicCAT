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

Sub importedList(dir As String,filename As String,sourceLang As String,targetLang As String) As List
	Dim segments As List
	segments.Initialize
	Dim tmxString As String
	tmxString=XMLUtils.escapedText(File.ReadString(dir,filename),"seg","tmx")
	Dim tmxMap As Map
	tmxMap=XMLUtils.getXmlMap(tmxString)
	Log(tmxMap)
	Dim tmxroot As Map
	tmxroot=tmxMap.Get("tmx")
	Dim body As Map
	body=tmxroot.Get("body")
	Dim tuList As List
	tuList=XMLUtils.GetElements(body,"tu")
	For Each tu As Map In tuList
		Dim bitext As List
		bitext.Initialize
		Dim tuvList As List
		tuvList=XMLUtils.GetElements(tu,"tuv")
		bitext.Add("source")
		bitext.Add("target")
		For Each tuv As Map In tuvList
			Dim attributes As Map
			attributes=tuv.Get("Attributes")
			Dim lang As String
			If attributes.ContainsKey("lang") Then
				lang=attributes.Get("lang")
			else if attributes.ContainsKey("xml:lang") Then
				lang=attributes.Get("xml:lang")
			End If
			lang=lang.ToLowerCase
			If lang.StartsWith(sourceLang) Then
				bitext.Set(0,tuv.Get("seg"))
			else if lang.StartsWith(targetLang) Then
				bitext.Set(1,tuv.Get("seg"))
			End If
		Next
		bitext.Add(filename)
		segments.Add(bitext)
	Next
	Return segments
End Sub

Sub export(segments As List,sourceLang As String,targetLang As String,path As String,includeTag As Boolean,isUniversal As Boolean)
	Dim rootmap As Map
	rootmap.Initialize
	Dim tmxMap As Map
	tmxMap.Initialize
	tmxMap.Put("Attributes",CreateMap("version":"1.4"))
	Dim headerAttributes As Map
	headerAttributes.Initialize
	headerAttributes.Put("creationtool","BasicCAT")
	headerAttributes.Put("creationtoolversion","1.0.0")
	headerAttributes.put("adminlang",sourceLang)
	headerAttributes.put("srclang",sourceLang)
	headerAttributes.put("segtype","sentence")
	headerAttributes.put("o-tmf","BasicCAT")
	tmxMap.Put("header",headerAttributes)
	Dim body As Map
	body.Initialize
	Dim tuList As List
	tuList.Initialize
	For Each bitext As List In segments
		Dim tuvMap As Map
		tuvMap.Initialize
		Dim tuvList As List
		tuvList.Initialize
		Dim index As Int=0
		For Each seg As String In bitext
			If includeTag=False Then
				seg=Regex.Replace2("<.*?>",32,seg,"")
			End If
			index=index+1
			If index Mod 2=0 Then
				tuvList.Add(CreateMap("Attributes":CreateMap("xml:lang":targetLang),"seg":seg))
			Else
				tuvList.Add(CreateMap("Attributes":CreateMap("xml:lang":sourceLang),"seg":seg))
			End If
		Next
		tuvMap.Put("tuv",tuvList)
		tuList.Add(tuvMap)
	Next
	body.Put("tu",tuList)
	tmxMap.Put("body",body)
	rootmap.Put("tmx",tmxMap)
	Dim tmxstring As String
	Try
		tmxstring=XMLUtils.getXmlFromMap(rootmap)
	Catch
		fx.Msgbox(Main.MainForm,"export failed because of tag problem","")
		Return
		Log(LastException)
	End Try

	If includeTag=True And isUniversal=True Then
		tmxstring=XMLUtils.unescapedText(tmxstring,"seg","tmx")
		tmxstring=convertTags(tmxstring)
		
	End If
	
	File.WriteString(path,"",tmxstring)
End Sub

Sub convertTags(xmlstring As String) As String
	Dim inSegMatcher As Matcher
	inSegMatcher=Regex.Matcher2("<seg>(.*?)</seg>",32,xmlstring)
	Dim replacements As List
	replacements.Initialize
	Do While inSegMatcher.Find

		Dim group As String 
		group=convertOneSeg(inSegMatcher.Group(1))
		If group<>inSegMatcher.Group(1) Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",inSegMatcher.GetStart(1))
			replacement.Put("end",inSegMatcher.GetEnd(1))
			replacement.Put("group",group)
			replacements.InsertAt(0,replacement)
		End If
	Loop
	
	Dim new As String=xmlstring
	For Each replacement As Map In replacements
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

Sub convertOneSeg(seg As String) As String
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("<(bpt|ept|hi|it|ph|sub|ut).*?>",32,seg)
	Dim replacements As List
	replacements.Initialize
	Do While tagMatcher.Find
		Dim group As String
		If tagMatcher.Match.Contains("/>")=False Then
			group=convertToUniversalTag(tagMatcher.Group(0)&"</"&tagMatcher.Group(1)&">")
			group=group.Replace("</"&tagMatcher.Group(1)&">","")
			group=group.Replace("/>",">")
		Else
			group=convertToUniversalTag(tagMatcher.Group(0))
		End If
		If group<>tagMatcher.Group(0) Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",tagMatcher.GetStart(0))
			replacement.Put("end",tagMatcher.GetEnd(0))
			replacement.Put("group",group)
			replacements.InsertAt(0,replacement)
		End If

	Loop
	
	Dim new As String=seg
	For Each replacement As Map In replacements
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

Sub convertToUniversalTag(xmlstring As String) As String
	Log("xml"&xmlstring)
	Try
		Dim inlineTagMap As Map
		inlineTagMap=XMLUtils.getXmlMap(xmlstring)
		
		Dim innerMap As Map
		innerMap=inlineTagMap.GetValueAt(0)

		Dim attributes As Map
		attributes=innerMap.Get("Attributes")
		If attributes.ContainsKey("id") And attributes.ContainsKey("x")=False Then
			attributes.Put("x",attributes.Get("id"))
		End If
	
		Dim keys As List
		keys.Initialize
		For Each key As String In attributes.keys
			keys.add(key)
		Next
	
		For Each key As String In keys
			If key<>"x" And key<>"pos" And key<>"datatype" And key<>"i" And key<>"assoc" And key<>"type" Then
				attributes.Remove(key)
			End If
		Next

		Dim result As String=XMLUtils.getXmlFromMap(inlineTagMap)
		result=Regex.Replace("<\?xml.*?>",result,"")
		result=result.Trim

	Catch
		Log(LastException)
		result=xmlstring
		
	End Try
	Log(result&"result")
	Return result
End Sub
