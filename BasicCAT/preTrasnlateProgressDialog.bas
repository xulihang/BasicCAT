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
End Sub

Sub Show(index As Int)
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("preTranslateProgress")
	frm.Show

End Sub

Sub update(completed As Int,segmentSize As Int)
	Label1.Text=completed&"/"&segmentSize
End Sub

Sub close
	frm.Close
End Sub