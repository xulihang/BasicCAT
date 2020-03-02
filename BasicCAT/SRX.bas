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


Sub readRules(filepath As String,lang As String) As List
	Dim srxString As String
	
	
	If filepath="" Or File.Exists(filepath,"")=False Then
		srxString=File.ReadString(File.DirAssets,"segmentationRules.srx")
	Else
		srxString=File.ReadString(filepath,"")
	End If
	
	Log(filepath)
	'Dim rules As Map
	'rules.Initialize
	Dim allRules As List
	allRules.Initialize

	Dim srxMap As Map
	srxMap.Initialize
	srxMap=XMLUtils.getXmlMap(srxString).Get("srx")
	Dim header As Map=srxMap.Get("header")
	Dim headerAttributes As Map
	headerAttributes=header.Get("Attributes")
	If headerAttributes.GetDefault("cascade","no")="no" Then
		segmentation.cascade=False
	Else
		segmentation.cascade=True
	End If
	
	Dim srxBody As Map
	srxBody.Initialize
	srxBody=srxMap.Get("body")
	
	'------ read maprules
	Dim mapRules As Map
	mapRules=srxBody.Get("maprules")
	Dim languageRuleNames As List
	languageRuleNames.Initialize
	Dim languageMaps As List
	languageMaps.Initialize
	languageMaps=XMLUtils.GetElements(mapRules,"languagemap")
	For Each languageMap As Map In languageMaps

		Dim attributes As Map
		attributes=languageMap.Get("Attributes")
		Dim languagePattern As String
		languagePattern=attributes.Get("languagepattern")
		Dim languageRuleName As String
		languageRuleName=attributes.Get("languagerulename")
		If Regex.IsMatch(languagePattern,lang) Then
			languageRuleNames.Add(languageRuleName)
		End If
	Next
	Log(languageRuleNames)
	'------ read languagerules
	Dim languageRules As List
	languageRules=XMLUtils.GetElements(srxBody.Get("languagerules"),"languagerule")

	For Each languageRule As Map In languageRules

		Dim attributes As Map
		attributes=languageRule.Get("Attributes")
		Dim languageRuleName As String
		languageRuleName=attributes.Get("languagerulename")
		If languageRuleNames.IndexOf(languageRuleName)<>-1 Then
			
			Dim oneLangRules As List
			oneLangRules=XMLUtils.GetElements(languageRule,"rule")

			For Each rule As Map In oneLangRules
				Dim tidyRule As Map
				tidyRule.Initialize
				tidyRule.Put("break",Utils.getMap("Attributes",rule).Get("break"))
				tidyRule.Put("beforebreak",rule.Get("beforebreak"))
				tidyRule.Put("afterbreak",rule.Get("afterbreak"))

				allRules.Add(tidyRule)
			Next
		End If
	Next
	
	Return allRules
End Sub
