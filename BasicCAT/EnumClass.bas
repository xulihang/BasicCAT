B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private EnumJO As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(ClassName As String)
	EnumJO.InitializeStatic(ClassName)
End Sub
'Return the Constant for a given Constant String Text
Sub ValueOf(Text As String) As Object
	Return EnumJO.RunMethod("valueOf",Array(Text))
End Sub
'Returns an array containing the constants of this enum type, in the order they are declared.
Sub Values As Object()
	Return EnumJO.RunMethod("values",Null)
End Sub
'Returns an array containing a string representation of the constants of this enum type, in the order they are declared.
Sub ValueStrings As String()
	Dim ValueObjects() As Object = Values
	Dim JO As JavaObject
	Dim ReturnStrings(ValueObjects.Length) As String
	For i = 0 To ValueObjects.Length - 1
		JO = ValueObjects(i)
		ReturnStrings(i) = JO.RunMethod("toString",Null)
	Next
	Return ReturnStrings
End Sub