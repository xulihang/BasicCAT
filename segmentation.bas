B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private segmentsList As List
	private segmentMarks as List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(path As String)
	If path.EndsWith(".txt") Then
		Dim source As String
		source=File.ReadString(path,"")
		
	End If
End Sub

Sub addSegmentsToEditor
	
End Sub

