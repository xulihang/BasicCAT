B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private SearchView1 As SearchView
	Private kvs As TMDB
	Private externalTMRadioButton As RadioButton
	Private projectTMRadioButton As RadioButton
	Private PhraseQueryCheckBox As CheckBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("TMManager")
	init
End Sub

Public Sub Show
	frm.Show
End Sub

Sub init
	kvs=Main.currentProject.projectTM.translationMemory
	wait for (setItems) complete (rst As Object)
	Sleep(0)
	SearchView1.show
	addContextMenuToLV
End Sub


Sub setItems As ResumableSub
	wait for (MatchedItems) complete (items As List)
	SearchView1.SetItems(items)
	Return ""
End Sub

Sub SearchView1_TextChanged(text As String)
	wait for (setItems) complete (rst As Object)
    SearchView1.TextChanged(text)
End Sub

Sub MatchedItems As ResumableSub
	Dim text As String=SearchView1.EtText.Trim
	Dim items As List
	items.Initialize
	If text<>"" Then
		If PhraseQueryCheckBox.Checked Then
			text=$""${text}""$
		End If
		wait for (kvs.GetMatchedMapAsync(text,True,True)) Complete (matchedMap As Map)
		For Each key As String In matchedMap.Keys
			'Log(key)
			Dim targetMap As Map
			targetMap=matchedMap.Get(key)
			items.Add(buildItemText(key,targetMap.Get("text")))
		Next
	Else
		Dim index As Int=0
		For Each key As String In kvs.ListKeys
			'Log(key)
			index=index+1
			Dim targetMap As Map
			targetMap=kvs.Get(key)
			items.Add(buildItemText(key,targetMap.Get("text")))
			If index=100 Then
				Exit
			End If
		Next
	End If
	Return items
End Sub

Sub addContextMenuToLV
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim mi As MenuItem
	mi.Initialize("Edit","mi")
	Dim mi2 As MenuItem
	mi2.Initialize("Remove","mi")
	Dim mi3 As MenuItem
	mi3.Initialize("Info","mi")
	cm.MenuItems.Add(mi)
	cm.MenuItems.Add(mi2)
	cm.MenuItems.Add(mi3)
	SearchView1.addContextMenuToLV(cm)
End Sub

Sub buildItemText(source As String,target As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("- source: ").Append(source).Append(CRLF)
	sb.Append("- target: ").Append(target)
	Return sb.ToString
End Sub

Sub mi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim p As Pane
	p=SearchView1.GetSelected
	Dim text As String
	text=p.Tag
	Dim source,target As String
	source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
	target=Regex.Split(CRLF&"- ",text)(1).Replace("target: ","")
	
	Select mi.Text
		Case "Edit"
			
			Dim tmEd As TMEditor
			tmEd.Initialize(source,target)
			Dim bitext As List
			bitext=tmEd.showAndWait
			
			Dim targetMap As Map
			targetMap=kvs.Get(bitext.Get(0))
			targetMap.Put("text",bitext.Get(1))
			kvs.Put(bitext.Get(0),targetMap)
			
			If externalTMRadioButton.Selected=False Then
				Main.currentProject.projectTM.addPairToSharedTM(bitext.Get(0),targetMap)
			End If
			wait for (setItems) complete (rst As Object)
			SearchView1.replaceItem(buildItemText(bitext.Get(0),bitext.Get(1)),SearchView1.GetSelectedIndex)
		Case "Remove"
			Dim result As Int=fx.Msgbox2(frm,"Will delete this entry, continue?","","Yes","","Cancel",fx.MSGBOX_CONFIRMATION)
			If result=fx.DialogResponse.POSITIVE Then
				kvs.Remove(source)
				Main.currentProject.projectTM.removeFromSharedTM(source)
				wait for (setItems) complete (rst As Object)
				SearchView1.GetItems.RemoveAt(SearchView1.GetSelectedIndex)
			End If
		Case "Info"
			Dim targetMap As Map
			targetMap=kvs.Get(source)
			Dim sb As StringBuilder
			sb.Initialize
			For Each key As String In targetMap.Keys
				sb.Append(key).Append("	").Append(targetMap.Get(key)).Append(CRLF)
			Next
		    fx.Msgbox(frm,sb.ToString,"")
	End Select
End Sub

Sub projectTMRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTM.translationMemory
		wait for (setItems) complete (rst As Object)
		SearchView1.show
	End If
End Sub

Sub externalTMRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTM.externalTranslationMemory
		wait for (setItems) complete (rst As Object)
		SearchView1.show
	End If
End Sub

Sub ExportButton_MouseClicked (EventData As MouseEvent)
	exportToFile
End Sub

Sub exportToFile
	Dim path As String
	Dim fc As FileChooser
	fc.Initialize
	'fc.SetExtensionFilter("tmx or tab-delimitted text",Array As String("*.tmx","*.txt"))
	FileChooserUtils.AddExtensionFilters4(fc,Array As String("TMX","XLSX","tab-delimitted text"),Array As String("*.tmx","*.xlsx","*.txt"),False,"All",False)
	path=fc.ShowSave(frm)
	If path="" Then
		Return
	End If

	Dim segments As List
	segments.Initialize

	For Each key As String In kvs.ListKeys
		Dim bitext As List
		bitext.Initialize
		bitext.Add(key)
		Dim targetMap As Map
		targetMap=kvs.Get(key)
		Dim target As String
		target=targetMap.Get("text")
		bitext.Add(target)
		bitext.Add(targetMap)
		segments.Add(bitext)
		
	Next
	Dim result As Int
	result=fx.Msgbox2(frm,"Include tags?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
	If result=fx.DialogResponse.CANCEL Then
		Return
	End If
	If path.EndsWith(".tmx") Then
		Select result
			Case fx.DialogResponse.NEGATIVE
				TMX.export(segments,Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),path,False,False)
			Case fx.DialogResponse.POSITIVE
				Dim result2 As Int
				result2=fx.Msgbox2(frm,"Convert tags to universal tags?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
				Select result2
					Case fx.DialogResponse.NEGATIVE
						TMX.export(segments,Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),path,True,False)
					Case fx.DialogResponse.POSITIVE
						TMX.export(segments,Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),path,True,True)
					Case fx.DialogResponse.CANCEL
						Return
				End Select
		End Select
	Else if path.EndsWith(".xlsx") Then
		Select result
			Case fx.DialogResponse.NEGATIVE
				exportToXLSX(segments,path,False)
			Case fx.DialogResponse.POSITIVE
				exportToXLSX(segments,path,True)
		End Select
	Else if path.EndsWith(".txt") Then
		Select result
			Case fx.DialogResponse.NEGATIVE
				exportToTXT(segments,path,False)
			Case fx.DialogResponse.POSITIVE
				exportToTXT(segments,path,True)
		End Select
	End If
	
	fx.Msgbox(frm,"exported","")
End Sub

Sub exportToTXT(segments As List,path As String,includeTags As Boolean)
	Dim sb As StringBuilder
	sb.Initialize
	For Each bitext As List In segments
		Dim tu As List = TMUnitToList(bitext,includeTags)
		For Each item As String In tu
			sb.Append(item).Append("	")
		Next
		sb.Append(CRLF)
	Next
	File.WriteString(path,"",sb.ToString)
End Sub

Sub exportToXLSX(segments As List,path As String,includeTags As Boolean)
	Dim wb As PoiWorkbook
	wb.InitializeNew(True)
	Dim sheet1 As PoiSheet = wb.AddSheet("Sheet1",0)
	Dim index As Int=0
	For Each bitext As List In segments
		Dim tu As List = TMUnitToList(bitext,includeTags)
		Dim row As PoiRow = sheet1.CreateRow(index)
		For i=0 To tu.Size-1
			row.CreateCellString(i,tu.Get(i))
		Next
		index=index+1
	Next
	wb.Save(path,"")
	wb.Close
End Sub

Sub TMUnitToList(bitext As List,includeTags As Boolean) As List
	Dim result As List
	result.Initialize
	Dim source As String = bitext.Get(0)
	Dim target As String = bitext.Get(1)
	
	If includeTags=False Then
		source=Regex.Replace("<.*?>",source,"")
		target=Regex.Replace("<.*?>",target,"")
	End If
	
	result.Add(source)
	result.Add(target)

	Dim targetMap As Map
	targetMap=bitext.Get(2)

	If targetMap.ContainsKey("creator") Then
		result.Add(targetMap.Get("creator"))
	Else
		result.Add("")
	End If
		
	If targetMap.ContainsKey("createdTime") Then
		Dim creationDate As String
		DateTime.DateFormat="yyyyMMdd"
		DateTime.TimeFormat="HHmmss"
		creationDate=DateTime.Date(targetMap.Get("createdTime"))&"T"&DateTime.Time(targetMap.Get("createdTime"))&"Z"
		result.Add(creationDate)
	Else
		result.add("")
	End If
		
	If targetMap.ContainsKey("note") Then
		result.add(targetMap.Get("note"))
	Else
		result.Add("")
	End If
	Return result
End Sub
