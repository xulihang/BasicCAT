B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=3.5
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private btnCancel As Button
	Private FontListView As ListView
	Private FontSizeSpinner As Spinner
	Private Label1 As Label
End Sub

Public Sub Initialize (CurrentFont As Font)
	frm.Initialize("frm", 400, 600)
	frm.RootPane.LoadLayout("FontPicker")
	For Each f As String In fx.GetAllFontFamilies
		Log(f)
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Font = fx.CreateFont(f, 14, False, False)
		lbl.Text = f
		FontListView.Items.Add(lbl)
		If lbl.Font.FamilyName = CurrentFont.FamilyName Then
			FontListView.SelectedIndex = FontListView.Items.Size - 1
			FontListView.ScrollTo(FontListView.Items.Size - 1)
		End If
	Next
End Sub

Public Sub ShowAndWait As Font
	frm.ShowAndWait
	If FontListView.SelectedIndex >= 0 Then
		
		Return Label1.Font
	Else
		Return Null
	End If
End Sub

Sub btnCancel_Action
	FontListView.SelectedIndex = -1
	frm.Close
End Sub

Sub btnOK_Action
	frm.Close
End Sub

Sub FontSizeSpinner_ValueChanged (Value As Object)
	Label1.Font=fx.CreateFont(Label1.Font.FamilyName,Value,False,False)
End Sub

Sub FontListView_SelectedIndexChanged(Index As Int)
	Try
		Dim lbl As Label = FontListView.SelectedItem
		Label1.Font=fx.CreateFont(lbl.Font.FamilyName,Label1.Font.Size,False,False)
	Catch
		Log(LastException)
	End Try
End Sub