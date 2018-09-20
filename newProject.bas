B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize (CurrentFont As Font)
	frm.Initialize("frm", 300, 500)
	frm.RootPane.LoadLayout("FontPicker")
	For Each f As String In fx.GetAllFontFamilies
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Font = fx.CreateFont(f, 14, False, False)
		lbl.Text = f
		ListView1.Items.Add(lbl)
		If lbl.Font.FamilyName = CurrentFont.FamilyName Then
			ListView1.SelectedIndex = ListView1.Items.Size - 1
			ListView1.ScrollTo(ListView1.Items.Size - 1)
		End If
	Next
End Sub

Public Sub ShowAndWait as Boolean
	frm.ShowAndWait
	If ListView1.SelectedIndex >= 0 Then
		Dim lbl As Label = ListView1.SelectedItem
		Return lbl.Font
	Else
		Return Null
	End If
End Sub