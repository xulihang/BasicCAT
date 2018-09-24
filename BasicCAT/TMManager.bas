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
	CallSubDelayed(Me,"ListViewParent_Resize")
End Sub

Sub LoadTM
	Dim kvs As KeyValueStore = Main.currentProject.projectTM.translationMemory
	For Each key As String In kvs.ListKeys
		TMListView.Add(CreatSegmentPane(key,kvs.Get(key)),"")
		Log(key)
	Next
	CallSubDelayed(Me,"ListViewParent_Resize")
End Sub

Sub EditButton_MouseClicked (EventData As MouseEvent)
	
End Sub

Sub DelButton_MouseClicked (EventData As MouseEvent)
	
End Sub


Public Sub CreatSegmentPane(source As String,target As String) As Pane
	Dim SegmentPane As Pane
	SegmentPane.Initialize("SegmentPane")
	SegmentPane.LoadLayout("TMsegment")
	SegmentPane.SetSize(TMListView.AsView.Width,50dip)
	Dim SourceLabel As Label
	SourceLabel=SegmentPane.GetNode(0)
	SourceLabel.Text=source
	Log(source)
	Dim TargetLabel As Label
	TargetLabel=SegmentPane.GetNode(1)
	TargetLabel.Text=target
	Return SegmentPane
End Sub

Sub ListViewParent_Resize
	Dim clv As CustomListView
	clv=TMListView
	If clv.Size=0 Then
		Return
	End If
	Dim itemWidth As Double = clv.AsView.Width
	Log(itemWidth)
	For i =  0 To clv.Size-1
		Dim p As Pane
		p=clv.GetPanel(i)
		If p.NumberOfNodes=0 Then
			Continue
		End If
		Dim sourcelbl,targetlbl As Label
		sourcelbl=p.GetNode(0)
		sourcelbl.SetSize(itemWidth/2,10)
		sourcelbl.WrapText=True
		targetlbl=p.GetNode(1)
		targetlbl.SetSize(itemWidth/2,10)
		targetlbl.WrapText=True
		Dim jo As JavaObject = p
		'force the label to refresh its layout.
		jo.RunMethod("applyCss", Null)
		jo.RunMethod("layout", Null)
		Dim h As Int = Max(Max(50, sourcelbl.Height + 20), targetlbl.Height + 20)
		p.SetLayoutAnimated(0, 0, 0, itemWidth, h + 10dip)
		sourcelbl.SetLayoutAnimated(0, 0, 0, itemWidth/2, h+5dip)
		targetlbl.SetLayoutAnimated(0, itemWidth/2, 0, itemWidth/2, h+5dip)
		clv.ResizeItem(i,h+10dip)
	Next
End Sub
