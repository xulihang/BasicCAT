B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private Label1 As Label
	Private TextArea1 As TextArea
	Private TextField1 As TextField
	Private rules As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("SegmentationRulesManager")
End Sub

Public Sub Show
	frm.Show
End Sub

Sub ChooseSRXButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("Rule",Array As String("*.srx"))
	Dim path As String
	path=fc.ShowOpen(frm)
	If File.Exists(path,"") Then
		TextField1.Text=path
		rules=SRX.readRules(path,"en")
	End If
End Sub

Sub TextArea1_TextChanged (Old As String, New As String)
	If rules.IsInitialized Then
		wait for (segmentation.segmentedTxtWithSpecifiedRules(New,True,"en",rules)) Complete (segments As List)
		Dim sb As StringBuilder
		sb.Initialize
		For Each segment As String In segments
			sb.Append("[")
			sb.Append(segment)
			sb.Append("]")
		Next
		Label1.Text=sb.ToString
	End If
End Sub

Sub ReloadButton_MouseClicked (EventData As MouseEvent)
	If File.Exists(TextField1.Text,"") Then
		rules=SRX.readRules(TextField1.Text,"en")
	End If
End Sub
