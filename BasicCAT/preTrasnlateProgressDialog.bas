B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private frm As Form
	Private percentLabel As Label
	Private sourceLabel As Label
	Private targetLabel As Label
End Sub

Sub Show
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("preTranslateProgress")
	frm.Show
	percentLabel.Text="0/0"
	sourceLabel.Text=""
	targetLabel.Text=""
End Sub

Sub update(currentSegment As Int,segmentSize As Int,source As String,target As String)
	percentLabel.Text=currentSegment&"/"&segmentSize
	sourceLabel.Text=source
	targetLabel.Text=target
End Sub

Sub close
	frm.Close
End Sub