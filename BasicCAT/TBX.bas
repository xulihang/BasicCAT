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
	xmlMap=Utils.getXmlMap(File.ReadString(filepath,""))
	Dim martif As Map
	martif=xmlMap.Get("martif")
	Dim textMap As Map
	textMap=martif.Get("text")
	Dim body As Map
	body=textMap.Get("body")
	Dim termEntries As List
	termEntries=Utils.GetElements(body,"termEntry")
	For Each termEntry As Map In termEntries
		Dim langSets As List
		langSets=Utils.GetElements(termEntry,"langSet")
		
		Dim targetMap As Map
		targetMap.Initialize
		Dim termInfo As Map
		termInfo.Initialize
		Dim target,source,description As String
		For Each langSet As Map In langSets
			Log(langSet)
			Dim attributes As Map
			attributes=langSet.Get("Attributes")
			Dim lang As String
			lang=attributes.Get("xml:lang")
			If lang.StartsWith(sourceLang) Then
				source=getTermFromLangSet(langSet)
				description=getDescriptionFromLangSet(langSet,description)
				
			Else if lang.StartsWith(targetLang) Then
				target=getTermFromLangSet(langSet)
				description=getDescriptionFromLangSet(langSet,description)
			End If
		Next
		termInfo.Put("description",description)
		targetMap.Put(target,termInfo)
		termsMap.Put(source,targetMap)
	Next
	Log(termsMap)
End Sub

Sub getTermFromLangSet(langSet As Map) As String
	Dim termStr As String
	Dim ntigList As List
	ntigList=Utils.GetElements(langSet,"ntig")
	Dim ntigMap As Map
	ntigMap=ntigList.Get(0)
	Dim termGrpList As List
	termGrpList=Utils.GetElements(ntigMap,"termGrp")
	Dim termGrpMap As Map
	termGrpMap=termGrpList.Get(0)
	Dim termList As List
	termList=Utils.GetElements(termGrpMap,"term")
	Dim termMap As Map
	termMap=termList.Get(0)
	termStr=termMap.Get("Text")
	Return termStr
End Sub


Sub getDescriptionFromLangSet(langSet As Map,description As String) As String
    If langSet.ContainsKey("descripGrp")=True Then
		Dim descripGrpList As List
		descripGrpList=Utils.GetElements(langSet,"descripGrp")
		Dim descripGrpMap As Map
		descripGrpMap=descripGrpList.Get(0)
		Dim descripList As List
		descripList=Utils.GetElements(descripGrpMap,"descrip")
		Dim descripMap As Map
		descripMap=descripList.Get(0)
		description=descripMap.Get("Text")
    End If
	Return description
End Sub