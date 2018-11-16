B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=5.9
@EndOfDesignText@
'v1.00
Sub Class_Globals
	Private builder As XMLBuilder
End Sub

Public Sub Initialize
	
End Sub

Public Sub MapToXml (m As Map) As String
	For Each k As String In m.Keys
		builder = builder.create(k)
		HandleElement("", m.Get(k))
		Exit
	Next
	builder = builder.up
#if B4J or B4A
	Dim props As Map
	props.Initialize
	props.Put("{http://xml.apache.org/xslt}indent-amount", "4")
	props.Put("indent", "yes")
	Return builder.asString2(props)
#else
	Return builder.AsString
#end if
End Sub

Private Sub HandleMapElement (m As Map)
	Dim attributes As Map = m.Get("Attributes")
	If attributes.IsInitialized Then
		For Each attr As String In attributes.Keys
			builder.attribute(attr, attributes.Get(attr))
		Next
		If m.ContainsKey("Text") Then builder.text(m.Get("Text"))
		m.Remove("Attributes")
		m.Remove("Text")
	End If
	For Each k As String In m.Keys
		Dim value As Object = m.Get(k)
		HandleElement(k, value)
	Next
End Sub

Private Sub HandleElement (key As String, value As Object)
	If value Is Map Then
		If key <> "" Then builder = builder.element(key)
		HandleMapElement(value)
		If key <> "" Then builder = builder.up
	Else if value Is List Then
		HandleListElement (key, value)
	Else
		builder = builder.element(key)
		builder = builder.text(value)
		builder = builder.up
	End If
End Sub

Private Sub HandleListElement (key As String, lst As List)
	For Each value As Object In lst
		HandleElement(key, value)
	Next
End Sub