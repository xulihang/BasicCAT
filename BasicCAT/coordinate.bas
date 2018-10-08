B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public x As Int
	Public y As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(ItemTransformString As String)
	getXY(ItemTransformString)
End Sub

Sub getXY(itemtransform As String)
	'1 0 0 1 169 -208
	Dim seperatedBySpace As List
	seperatedBySpace=Regex.Split(" ",itemtransform)
	x=seperatedBySpace.Get(seperatedBySpace.Size-2)
	y=seperatedBySpace.Get(seperatedBySpace.Size-1)
End Sub