B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private TermListView As CustomListView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("TermManager")
	LoadTerm
End Sub

Sub ShowAndWait
	frm.ShowAndWait
End Sub

Sub frm_Resize (Width As Double, Height As Double)
	CallSubDelayed2(Utils,"ListViewParent_Resize",TermListView)
End Sub

Sub LoadTerm
	Dim termMap As KeyValueStore = Main.currentProject.projectTerm.terminology
	For Each source As String In termMap.ListKeys
		Dim targetMap As Map
		targetMap=termMap.Get(source)
		For Each target As String In targetMap.Keys
			TermListView.Add(CreatSegmentPane(source,target),"")
		Next
	Next
	CallSubDelayed2(Utils,"ListViewParent_Resize",TermListView)
End Sub


Public Sub CreatSegmentPane(source As String,target As String) As Pane
	Dim SegmentPane As Pane
	SegmentPane.Initialize("SegmentPane")
	SegmentPane.LoadLayout("TMsegment")
	SegmentPane.SetSize(TermListView.AsView.Width,50dip)
	Dim SourceLabel As Label
	SourceLabel=SegmentPane.GetNode(0)
	SourceLabel.Text=source
	SourceLabel.Tag=target
	addMenu(SourceLabel)
	Log(source)
	Dim TargetLabel As Label
	TargetLabel=SegmentPane.GetNode(1)
	TargetLabel.Text=target
	Return SegmentPane
End Sub

Sub addMenu(lbl As Label)
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim mi As MenuItem
	mi.Initialize("Remove","lblmenu")
	mi.Tag=lbl
	cm.MenuItems.Add(mi)
	lbl.ContextMenu=cm
End Sub

Sub lblmenu_Action
	Dim mi As MenuItem
	mi=Sender
	Dim lbl As Label
	lbl=mi.Tag
	Log(lbl.Text)
	Select mi.Text
		Case "Remove"
			Dim termMap As KeyValueStore = Main.currentProject.projectTerm.terminology
			Dim targetMap As Map
			targetMap=termMap.Get(lbl.Text)
			targetMap.Remove(lbl.Tag)
			termMap.Put(lbl.Text,targetMap)
			TermListView.RemoveAt(TermListView.GetItemFromView(lbl.Parent))
	End Select
End Sub
