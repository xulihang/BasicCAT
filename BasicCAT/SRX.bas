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


Sub readRules(filepath As String,lang As String) As Map
	Dim srxString As String
	
	
	If filepath="" Then
		srxString=File.ReadString(File.DirAssets,"default_rules.srx")
	Else
		srxString=File.ReadString(filepath,"")
	End If
	
	Log(filepath)
	Dim rules As Map
	rules.Initialize
	Dim breakRules As List
	breakRules.Initialize
	Dim nonbreakRules As List
	nonbreakRules.Initialize

	Dim srxMap As Map
	srxMap.Initialize
	srxMap=Utils.getXmlMap(srxString).Get("srx")
	Dim srxBody As Map
	srxBody.Initialize
	srxBody=srxMap.Get("body")
	
	'------ read maprules
	Dim mapRules As Map
	mapRules=srxBody.Get("maprules")
	Dim languageRuleNames As List
	languageRuleNames.Initialize
	Dim languageMaps As List
	languageMaps=mapRules.Get("languagemap")
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
	languageRules=Utils.GetElements(srxBody.Get("languagerules"),"languagerule")

	For Each languageRule As Map In languageRules

		Dim attributes As Map
		attributes=languageRule.Get("Attributes")
		Dim languageRuleName As String
		languageRuleName=attributes.Get("languagerulename")
		If languageRuleNames.IndexOf(languageRuleName)<>-1 Then
			
			Dim oneLangRules As List
			oneLangRules=Utils.GetElements(languageRule,"rule")

			For Each rule As Map In oneLangRules
				Dim tidyRule As Map
				tidyRule.Initialize
				tidyRule.Put("break",Utils.getMap("Attributes",rule).Get("break"))
				tidyRule.Put("beforebreak",rule.Get("beforebreak"))
				tidyRule.Put("afterbreak",rule.Get("afterbreak"))

				If tidyRule.Get("break")="yes" Then
					breakRules.Add(tidyRule)
				Else
					nonbreakRules.Add(tidyRule)
				End If
				
			Next
		End If
	Next
	
	
	rules.Put("breakRules",breakRules)
	rules.Put("nonbreakRules",nonbreakRules)
	Log(rules)
	Return rules
End Sub
