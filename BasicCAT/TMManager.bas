B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private TMListView As CustomListView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("TMManager")
	LoadTM
End Sub

Sub ShowAndWait
    frm.ShowAndWait	
End Sub

Sub frm_Resize (Width As Double, Height As Double)
	CallSubDelayed2(Utils,"ListViewParent_Resize",TMListView)
End Sub

Sub LoadTM
	Dim tmMap As KeyValueStore = Main.currentProject.projectTM.translationMemory
	For Each key As String In tmMap.ListKeys
		TMListView.Add(CreateSegmentPane(key,tmMap.Get(key)),"")
		Log(key)
	Next
	CallSubDelayed2(Utils,"ListViewParent_Resize",TMListView)
End Sub

Public Sub CreateSegmentPane(source As String,target As String) As Pane
	Dim SegmentPane As Pane
	SegmentPane.Initialize("SegmentPane")
	SegmentPane.LoadLayout("TMsegment")
	SegmentPane.SetSize(TMListView.AsView.Width,50dip)
	Dim SourceLabel As Label
	SourceLabel=SegmentPane.GetNode(0)
	SourceLabel.Text=source
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
			Dim tmMap As KeyValueStore = Main.currentProject.projectTM.translationMemory
			tmMap.Remove(lbl.Text)
			TMListView.RemoveAt(TMListView.GetItemFromView(lbl.Parent))
	End Select
End Sub
