B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private DelButton As Button
	Private EditButton As Button
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
	Dim tmMap As KeyValueStore = Main.currentProject.projectTerm.terminology
	For Each key As String In tmMap.ListKeys
		TermListView.Add(CreatSegmentPane(key,tmMap.Get(key)),"")
		Log(key)
	Next
	CallSubDelayed2(Utils,"ListViewParent_Resize",TermListView)
End Sub

Sub EditButton_MouseClicked (EventData As MouseEvent)
	
End Sub

Sub DelButton_MouseClicked (EventData As MouseEvent)
	
End Sub


Public Sub CreatSegmentPane(source As String,target As String) As Pane
	Dim SegmentPane As Pane
	SegmentPane.Initialize("SegmentPane")
	SegmentPane.LoadLayout("TMsegment")
	SegmentPane.SetSize(TermListView.AsView.Width,50dip)
	Dim SourceLabel As Label
	SourceLabel=SegmentPane.GetNode(0)
	SourceLabel.Text=source
	Log(source)
	Dim TargetLabel As Label
	TargetLabel=SegmentPane.GetNode(1)
	TargetLabel.Text=target
	Return SegmentPane
End Sub
