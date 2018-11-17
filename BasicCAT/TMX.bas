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

Sub importedList(dir As String,filename As String) As List
	Dim segments As List
	segments.Initialize
	Dim tmxString As String
	tmxString=File.ReadString(dir,filename)
	Dim tmxMap As Map
	tmxMap=Utils.getXmlMap(tmxString)
	Log(tmxMap)
	Dim tmxroot As Map
	tmxroot=tmxMap.Get("tmx")
	Dim body As Map
	body=tmxroot.Get("body")
	Dim tuList As List
	tuList=Utils.GetElements(body,"tu")
	For Each tu As Map In tuList
		Dim bitext As List
		bitext.Initialize
		Dim tuvList As List
		tuvList=Utils.GetElements(tu,"tuv")
		For Each tuv As Map In tuvList
			bitext.Add(tuv.Get("seg"))
		Next
		bitext.Add(filename)
		segments.Add(bitext)
	Next
	Return segments
End Sub

Sub export(segments As List,sourceLang As String,targetLang As String,path As String,includeTag As Boolean)
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
				seg=Regex.Replace("<.*?>",seg,"")
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
	File.WriteString(path,"",Utils.getXmlFromMap(rootmap))
End Sub