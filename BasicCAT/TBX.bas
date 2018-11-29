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

Sub readTermsIntoMap(filepath As String,sourceLang As String,targetLang As String,termsMap As Map)
	Dim xmlMap As Map
	xmlMap=XMLUtils.getXmlMap(File.ReadString(filepath,""))
	Dim martif As Map
	martif=xmlMap.Get("martif")
	Dim textMap As Map
	textMap=martif.Get("text")
	Dim body As Map
	body=textMap.Get("body")
	Dim termEntries As List
	termEntries=XMLUtils.GetElements(body,"termEntry")
	For Each termEntry As Map In termEntries
		Dim tag As String
		If termEntry.ContainsKey("descrip") Then
			Dim descripList As List
			descripList=XMLUtils.GetElements(termEntry,"descrip")
			For Each descrip As Map In descripList
				Dim attributes As Map
				attributes=descrip.Get("Attributes")
				If attributes.ContainsKey("type") Then
					If attributes.Get("type")="subjectField" Then
						tag=descrip.Get("Text")
					End If
				End If
			Next
		End If
		
		Dim langSets As List
		langSets=XMLUtils.GetElements(termEntry,"langSet")
		
		Dim targetMap As Map
		targetMap.Initialize

		
		Dim termInfo As Map
		termInfo.Initialize
		Dim target,source,description,note As String
		For Each langSet As Map In langSets
			Log(langSet)
			Dim attributes As Map
			attributes=langSet.Get("Attributes")
			Dim lang As String
			lang=attributes.Get("xml:lang")
			lang=lang.ToLowerCase
			If lang.StartsWith(sourceLang) Then
				source=getTermFromLangSet(langSet)
				description=getDescriptionFromLangSet(langSet,description)
				If termsMap.ContainsKey(source) Then
					targetMap=termsMap.Get(source)
				End If
			Else if lang.StartsWith(targetLang) Then
				target=getTermFromLangSet(langSet)
				note=getNoteFromLangSet(langSet)
				description=getDescriptionFromLangSet(langSet,description)
			End If
		Next
		If note.Trim<>"" Then
			termInfo.Put("note",note)
		End If
		If description.Trim<>"" Then
			termInfo.Put("description",description)
		End If
		If tag.Trim<>"" Then
			termInfo.Put("tag",tag)
		End If
		targetMap.Put(target,termInfo)
		termsMap.Put(source,targetMap)
	Next
	Log(termsMap)
End Sub

Sub getTermFromLangSet(langSet As Map) As String
	Dim termStr As String
	If langSet.ContainsKey("ntig") Then	
		Dim ntigList As List
		ntigList=XMLUtils.GetElements(langSet,"ntig")
		Dim ntigMap As Map
		ntigMap=ntigList.Get(0)
		Dim termGrpList As List
		termGrpList=XMLUtils.GetElements(ntigMap,"termGrp")
		Dim termGrpMap As Map
		termGrpMap=termGrpList.Get(0)
		Dim termList As List
		termList=XMLUtils.GetElements(termGrpMap,"term")
		Dim termMap As Map
		termMap=termList.Get(0)
		termStr=termMap.Get("Text")
	Else if langSet.ContainsKey("tig") Then
		Dim tigList As List
		tigList=XMLUtils.GetElements(langSet,"tig")
		Dim tigMap As Map
		tigMap=tigList.Get(0)
		Dim termMap As Map
		termMap=tigMap.Get("term")
		termStr=termMap.Get("Text")
	End If
	Return termStr
End Sub


Sub getNoteFromLangSet(langSet As Map) As String
	If langSet.ContainsKey("tig")=True Then
		Dim tigs As List
		tigs=XMLUtils.GetElements(langSet,"tig")
		Dim tigMap As Map
		tigMap=tigs.Get(0)
		If tigMap.ContainsKey("note") Then
			Dim note As Map
			note=tigMap.Get("note")
			Return note.Get("Text")
		End If
	End If
	Return ""
End Sub

Sub getDescriptionFromLangSet(langSet As Map,description As String) As String
    If langSet.ContainsKey("descripGrp")=True Then
		Dim descripGrpList As List
		descripGrpList=XMLUtils.GetElements(langSet,"descripGrp")
		Dim descripGrpMap As Map
		descripGrpMap=descripGrpList.Get(0)
		Dim descripList As List
		descripList=XMLUtils.GetElements(descripGrpMap,"descrip")
		Dim descripMap As Map
		descripMap=descripList.Get(0)
		description=descripMap.Get("Text")
	End If
	Return description
End Sub


Sub export(termsKVS As KeyValueStore,sourceLang As String,targetLang As String,path As String)
	Dim rootmap As Map
	rootmap.Initialize
	Dim martifMap As Map
	martifMap.Initialize
	martifMap.Put("Attributes",CreateMap("type":"TBX","xml:lang":"en-US"))
	Dim martifHeader As Map
	martifHeader.Initialize
	Dim fileDesc As Map
	fileDesc.Initialize
	Dim titleStmt As Map
	titleStmt.Initialize
	Dim title As Map
	title.Initialize
	title.Put("Text","Exported Term")
	titleStmt.Put("title",title)
	Dim sourceDesc As Map
	sourceDesc.Initialize
	sourceDesc.Put("p",CreateMap("Text":"Created by BasicCAT"))
	fileDesc.Put("titleStmt",titleStmt)
	fileDesc.Put("sourceDesc",sourceDesc)
	martifHeader.Put("fileDesc",fileDesc)
	martifMap.Put("martifHeader",martifHeader)
	Dim text As Map
	text.Initialize
	Dim body As Map
	body.Initialize
	Dim termEntryList As List
	termEntryList.Initialize
	Dim index As Int=0
	For Each source As String In termsKVS.ListKeys
		Dim targetMap As Map=termsKVS.Get(source)
		For Each target As String In targetMap.Keys
			Dim langSetList As List
			langSetList.Initialize
			Dim terminfo As Map
			terminfo=targetMap.Get(target)
			Dim note,tag As String
			If terminfo.ContainsKey("note") Then
				note=terminfo.Get("note")
			End If
			If terminfo.ContainsKey("tag") Then
				tag=terminfo.Get("tag")
			End If
			addOneLangSet(langSetList,source,sourceLang,"")
			addOneLangSet(langSetList,target,targetLang,note)
			addOneTermEntry(index,tag,langSetList,termEntryList)
			index=index+1
		Next
	Next
	
	body.Put("termEntry",termEntryList)
	text.Put("body",body)
	martifMap.Put("text",text)
	rootmap.Put("martif",martifMap)
	File.WriteString(path,"",XMLUtils.getXmlFromMap(rootmap))
End Sub

Sub addOneLangSet(langSetList As List,text As String,lang As String,note As String)
	Dim langSetMap As Map
	langSetMap.Initialize
	langSetMap.Put("Attributes",CreateMap("xml:lang":lang))
	Dim tig As Map
	tig.Initialize
	tig.Put("term",CreateMap("Text":text))
	If note.Trim<>"" Then
		tig.Put("note",CreateMap("Text":note))
	End If
	langSetMap.Put("tig",tig)
	langSetList.Add(langSetMap)
End Sub

Sub addOneTermEntry(id As String,tag As String,langSetList As List,termEntryList As List)
    Dim termEntry As Map
	termEntry.Initialize
	termEntry.Put("Attributes",CreateMap("id":"eid-BasicCAT-"&id))

	If tag.Trim<>"" Then
		Dim descrip As Map
		descrip.Initialize
		descrip.Put("Attributes",CreateMap("type":"subjectField"))
		descrip.Put("Text",tag)
		termEntry.Put("descrip",descrip)
	End If
	
	termEntry.Put("langSet",langSetList)
	termEntryList.Add(termEntry)
End Sub