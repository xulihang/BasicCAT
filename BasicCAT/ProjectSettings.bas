B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private settings As Map
	Private applyButton As Button
	Private cancelButton As Button
	Private settingTabPane As TabPane
	Private AddTMButton As Button
	Private DeleteTMButton As Button
	Private TMListView As ListView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,400)
	frm.RootPane.LoadLayout("projectSetting")
	settings.Initialize
	settings=Main.currentProject.settings
	settingTabPane.LoadLayout("tmSetting","TM")
	TMListView.Items.AddAll(settings.Get("tmList"))
End Sub

Public Sub ShowAndWait As Map
	frm.ShowAndWait
	Return settings
End Sub

Sub settingTabPane_TabChanged (SelectedTab As TabPage)
	
End Sub

Sub cancelButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub

Sub applyButton_MouseClicked (EventData As MouseEvent)
	settings.Put("tmList",TMListView.Items)
	frm.Close
End Sub

Sub DeleteTMButton_MouseClicked (EventData As MouseEvent)
	TMListView.Items.RemoveAt(TMListView.SelectedIndex)
End Sub

Sub AddTMButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	
	Dim descriptionList,filterList As List
	descriptionList.Initialize
	filterList.Initialize

	descriptionList.Add("TAB-delimited Files")
	filterList.add("*.txt")
	descriptionList.Add("TMX Files")
	filterList.add("*.tmx")
	FileChooserUtils.AddExtensionFilters4(fc,descriptionList,filterList,False,"",True)
	Dim path As String
	path=fc.ShowOpen(frm)
	If path="" Then
		Return
	Else
		Dim filename As String
		filename=Main.getFilename(path)
		Wait For (File.CopyAsync(path,"",File.Combine(Main.currentProject.path,"TM"), filename)) Complete (Success As Boolean)
		Log("Success: " & Success)
		TMListView.Items.Add(filename)
	End If
End Sub