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


	Private Label1 As Label
	Private ProgressBar1 As ProgressBar
End Sub

Sub Show(title As String)
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("progress")
	frm.Title=title
	frm.Show

End Sub

Sub update(completed As Int,segmentSize As Int)
	Label1.Text=completed&"/"&segmentSize
	ProgressBar1.Progress=completed/segmentSize
End Sub

Sub close
	frm.Close	
End Sub

Sub frm_CloseRequest (EventData As Event)
	Main.currentProject.completed=Main.currentProject.segments.Size
	fx.Msgbox(frm,"The process is canceled.","")
	Return
End Sub