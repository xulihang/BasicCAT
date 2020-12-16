B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private RecordFilesListView As ListView
	Private ConditionsListView As ListView
	Private mSearchAndReplaceDialog As searchAndReplaceDialog
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(from As searchAndReplaceDialog)
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("SearchAndReplaceRecorder")
	mSearchAndReplaceDialog=from
End Sub

Public Sub Show
	frm.Show
End Sub

Public Sub Close
	frm.Close
End Sub

Public Sub Showing As Boolean
	Return frm.Showing
End Sub

Sub ShowResultsButton_MouseClicked (EventData As MouseEvent)
	For Each conditions As Map In ConditionsListView.Items
		mSearchAndReplaceDialog.LoadConditions(conditions)
		mSearchAndReplaceDialog.search(False)
	Next
End Sub

Sub ReplaceButton_MouseClicked (EventData As MouseEvent)
	ReplaceUsingOneRecord
	fx.Msgbox(frm,"Done","")
End Sub

Sub BatchReplaceButton_MouseClicked (EventData As MouseEvent)
	For Each lbl As Label In RecordFilesListView.Items
		ConditionsListView.Items.Clear
		Dim conditionsList As List=lbl.Tag
		ConditionsListView.Items.Addall(conditionsList)
		ReplaceUsingOneRecord
	Next
	fx.Msgbox(frm,"Done","")
End Sub

Sub ReplaceUsingOneRecord 
	For Each conditions As Map In ConditionsListView.Items
		mSearchAndReplaceDialog.LoadConditions(conditions)
		mSearchAndReplaceDialog.search(False)
		mSearchAndReplaceDialog.replaceAll(False)
	Next
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	fc.InitialDirectory=PathSaver.previousPath("records")
	fc.SetExtensionFilter("Search and replace records",Array As String("*.srr"))
	Dim path As String=fc.ShowSave(frm)
	PathSaver.savePath("records",path)
	Dim conditionsList As List
	conditionsList=ConditionsListView.Items
	Dim json As JSONGenerator
	json.Initialize2(conditionsList)
	File.WriteString(path,"",json.ToPrettyString(4))
End Sub

Sub ReadButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	fc.InitialDirectory=PathSaver.previousPath("records")
	fc.SetExtensionFilter("Search and replace records",Array As String("*.srr"))
	Dim files As List=fc.ShowOpenMultiple(frm)
	For Each path As String In files
		PathSaver.savePath("records",path)
		Dim json As JSONParser
		json.Initialize(File.ReadString(path,""))
		Dim lbl As Label
		lbl.Initialize("lbl")
		lbl.Text=path
		lbl.Tag=json.NextArray
		RecordFilesListView.Items.Add(lbl)
	Next
End Sub

Sub RecordFilesListView_Action
	If RecordFilesListView.SelectedIndex<>-1 Then
		Dim mi As MenuItem=Sender
		Select mi.Text
			Case "Replace"
				loadConditionsList(RecordFilesListView.SelectedIndex)
				ReplaceUsingOneRecord
			Case "Load selected record's conditions"
				loadConditionsList(RecordFilesListView.SelectedIndex)
			Case "Delete"
				RecordFilesListView.Items.RemoveAt(RecordFilesListView.SelectedIndex)
		End Select
	End If

End Sub

Sub loadConditionsList(index As Int)
	Dim lbl As Label=RecordFilesListView.Items.Get(index)
	Dim conditionsList As List=lbl.Tag
	ConditionsListView.Items.Clear
	ConditionsListView.Items.AddAll(conditionsList)
End Sub

Public Sub AddConditions(conditions As Map)
	ConditionsListView.Items.Add(conditions)
End Sub

Sub ConditionsListView_Action
	If ConditionsListView.SelectedIndex<>-1 Then
		Dim mi As MenuItem=Sender
		Select mi.Text
			Case "Delete"
				ConditionsListView.Items.RemoveAt(ConditionsListView.SelectedIndex)
			Case "Load this conditions"
				mSearchAndReplaceDialog.LoadConditions(ConditionsListView.SelectedItem)
			Case "Show results of this conditions"
				mSearchAndReplaceDialog.LoadConditions(ConditionsListView.SelectedItem)
				mSearchAndReplaceDialog.search(False)
		End Select
	End If
End Sub
