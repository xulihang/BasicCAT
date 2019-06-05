B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private Label1 As Label
	Private ListView1 As ListView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("languageChooser")
	For Each lang As String In File.ReadList(File.DirAssets,"lang.conf")
		Dim chkBox As CheckBox
		chkBox.Initialize("chkBox")
		chkBox.Checked=False
		chkBox.Text=lang
		ListView1.Items.Add(chkBox)
	Next
End Sub

Public Sub ShowAndWait As String
	frm.ShowAndWait
	Dim langsParam As String
	For Each chkBox As CheckBox In ListView1.Items
		If chkBox.Checked Then
			langsParam=langsParam&chkBox.Text&"+"
		End If
	Next
	If langsParam.EndsWith("+") Then
		langsParam=langsParam.SubString2(0,langsParam.Length-1)
	End If
	Log(langsParam)
	Return langsParam
End Sub

Sub OKButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub

Sub frm_CloseRequest (EventData As Event)
	ListView1.Items.Clear
	frm.Close
End Sub