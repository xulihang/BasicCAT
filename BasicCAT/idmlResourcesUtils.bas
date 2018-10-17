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


Sub changeFontsFromEnToZhOfStyleFile(ParsedData As Map)
	Dim GroupName,styleName As String
	For i=0 To 1
		If i=0 Then
			GroupName="RootCharacterStyleGroup"
			styleName="CharacterStyle"
		Else
			GroupName="RootParagraphStyleGroup"
			styleName="ParagraphStyle"
		End If

		Dim root As Map = ParsedData.Get("idPkg:Styles")
		Dim styleGroup As Map = root.Get(GroupName)
		Dim styles As List
		styles=Utils.GetElements(styleGroup,styleName)
		For Each style As Map In styles
			Dim attributes As Map
			attributes=style.Get("Attributes")
			Dim name As String
			name=attributes.Get("Name")

			If attributes.ContainsKey("FontStyle") Then
				Dim FontStyle As String
				FontStyle=attributes.Get("FontStyle")

				If Regex.Matcher("[0-9]",FontStyle).Find Then
					Dim weight As String
					Dim matcher As Matcher
					matcher=Regex.Matcher("[0-9]",FontStyle)
					Do While matcher.Find
						weight=weight&matcher.Match
					Loop
					FontStyle=FontWeightNumToNameForSourceHS(weight)
					
				End If
				FontStyle=FontWeightNameToNameForSourceHS(FontStyle)
				attributes.Put("FontStyle",FontStyle)
			End If
			

			If style.ContainsKey("Properties") Then
				Dim Properties,AppliedFont As Map
				Properties=style.Get("Properties")
				If Properties.ContainsKey("AppliedFont") Then
					AppliedFont=Properties.get("AppliedFont")
					Log("font "&AppliedFont.Get("Text"))
					AppliedFont.Put("Text","思源宋体")
					'Properties.Put("AppliedFont",AppliedFont)
					'characterStyle.Put("Properties",Properties)
				End If
			End If
		Next
	Next

End Sub


Sub FontWeightNumToNameForSourceHS(weight As Int) As String
	Log(weight)
	Select weight
		Case 100
			Return "ExtraLight"
		Case 200
			Return "ExtraLight"
		Case 300
			Return "Light"
		Case 400
			Return "Regular"
		Case 500
			Return "Medium"
		Case 600
			Return "SemiBold"
		Case 700
			Return "Bold"
		Case 800
			Return "Heavy"
		Case 900
			Return "Heavy"
	End Select
	Return "Regular"
End Sub

Sub FontWeightNameToNameForSourceHS(name As String) As String
	Select name
		Case "Normal"
			Return "Regular"
		Case "Black"
			Return "Heavy"
	End Select
	Return name
End Sub