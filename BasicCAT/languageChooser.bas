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

Public Sub ShowAndWait As List
	frm.ShowAndWait
	Return ListView1.Items
End Sub

Sub OKButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub