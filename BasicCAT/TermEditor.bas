B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private sourceTextField As TextField
	Private TagComboBox As ComboBox
	Private TagTextField As TextField
	Private noteTextArea As TextArea
	Private targetTextField As TextField
	Dim result As Map
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(source As String,target As String,note As String,tag As String,taglist As List)
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("TermEditor")
	noteTextArea.Text=note
	TagComboBox.Items.AddAll(taglist)
	Log(tag)
	If tag.Trim<>"" Then
		TagComboBox.SelectedIndex=TagComboBox.Items.IndexOf(tag)
		Log(TagComboBox.Items.Get(TagComboBox.SelectedIndex))
	End If
	sourceTextField.Text=source
	targetTextField.Text=target
	result.Initialize
	result.Put("source",source)
	result.Put("target",target)
	result.Put("tag",tag)
	result.Put("note",note)
	
End Sub

Public Sub showAndWait As Map
	frm.ShowAndWait
	Return result
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	result.Put("source",sourceTextField.Text)
	result.Put("target",targetTextField.Text)
	If TagComboBox.SelectedIndex<>-1 Then
		result.Put("tag",TagComboBox.Items.Get(TagComboBox.SelectedIndex))
	End If
	result.Put("note",noteTextArea.Text)
	frm.Close
End Sub

Sub AddTagButton_MouseClicked (EventData As MouseEvent)
	If TagComboBox.Items.IndexOf(TagTextField.Text)=-1 Then
		TagComboBox.Items.Add(TagTextField.Text)
		TagComboBox.SelectedIndex=TagComboBox.Items.IndexOf(TagTextField.Text)
	End If
End Sub