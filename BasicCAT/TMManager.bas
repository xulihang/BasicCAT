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
	Private kvs As KeyValueStore
	Private externalTMRadioButton As RadioButton
	Private projectTMRadioButton As RadioButton
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
	setItems(False)
	Sleep(0)
	SearchView1.show
	addContextMenuToLV
End Sub


Sub setItems(isExternal As Boolean)
	Dim items As List
	items.Initialize
	For Each key As String In kvs.ListKeys
		'Log(key)
		If isExternal Then
			Dim list1 As List
			list1=kvs.Get(key)
			items.Add(buildItemText(key,list1.Get(0)))
		Else
			items.Add(buildItemText(key,kvs.Get(key)))
		End If
		
	Next
	SearchView1.SetItems(items)
End Sub

Sub addContextMenuToLV
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim mi As MenuItem
	mi.Initialize("Edit","mi")
	Dim mi2 As MenuItem
	mi2.Initialize("Remove","mi")
	cm.MenuItems.Add(mi)
	cm.MenuItems.Add(mi2)
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
	Select mi.Text
		Case "Edit"
			Dim p As Pane
			p=SearchView1.GetSelected
			Dim text As String
			text=p.Tag
			Dim source,target As String
			source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
			target=Regex.Split(CRLF&"- ",text)(1).Replace("target: ","")
			Dim tmEd As TMEditor
			tmEd.Initialize(source,target)
			Dim bitext As List
			bitext=tmEd.showAndWait
			If externalTMRadioButton.Selected Then
				Dim list1 As List
				list1=kvs.Get(bitext.Get(0))
				list1.Set(0,bitext.Get(1))
				kvs.Put(bitext.Get(0),list1)
			Else
				kvs.Put(bitext.Get(0),bitext.Get(1))
				Main.currentProject.projectTM.addPairToSharedTM(bitext.Get(0),bitext.Get(1))
			End If
			setItems(externalTMRadioButton.Selected)
			SearchView1.replaceItem(buildItemText(bitext.Get(0),bitext.Get(1)),SearchView1.GetSelectedIndex)
		Case "Remove"
			Dim result As Int=fx.Msgbox2(frm,"Will delete this entry, continue?","","Yes","","Cancel",fx.MSGBOX_CONFIRMATION)
			If result=fx.DialogResponse.POSITIVE Then
				Dim p As Pane
				p=SearchView1.GetSelected
				Dim text As String
				text=p.Tag
				Dim source As String
				source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
				kvs.Remove(source)
				Main.currentProject.projectTM.removeFromSharedTM(source)
				setItems(externalTMRadioButton.Selected)
				SearchView1.GetItems.RemoveAt(SearchView1.GetSelectedIndex)
			End If
	End Select
End Sub

Sub projectTMRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTM.translationMemory
		setItems(False)
		SearchView1.show
	End If
End Sub

Sub externalTMRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTM.externalTranslationMemory
		setItems(True)
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
	FileChooserUtils.AddExtensionFilters4(fc,Array As String("TMX","tab-delimitted text"),Array As String("*.tmx","*.txt"),False,"All",False)
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
		Dim list1 As List
		If externalTMRadioButton.Selected Then
			list1=kvs.Get(key)
			bitext.Add(list1.Get(0))
		Else
			bitext.Add(kvs.Get(key))
		End If
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
	Else
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
		Dim source As String=bitext.Get(0)
		Dim target As String=bitext.Get(1)
		If includeTags=False Then
			source=Regex.Replace("<.*?>",source,"")
			target=Regex.Replace("<.*?>",target,"")
		End If
		sb.Append(source).Append("	").Append(target).Append(CRLF)
	Next
	File.WriteString(path,"",sb.ToString)
End Sub