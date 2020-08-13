B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Public Name As String
	Public Children As List
	Public Attributes As Map
	Public Closed As Boolean
	Public Parent As XmlNode
	Public Text As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub

Sub Get(key As String) As List
	Dim list1 As List
	list1.Initialize
	For Each node As XmlNode In Children
		If node.Name=key Then
			list1.Add(node)
		End If
	Next
	Return list1
End Sub

Sub Contains(key As String) As Boolean
	Dim list1 As List
	list1.Initialize
	For Each node As XmlNode In Children
		If node.Name=key Then
			Return True
		End If
	Next
	Return False
End Sub

Public Sub getinnerXML As String
	If Children.Size=1 Then
		Dim node As XmlNode=Children.Get(0)
		If node.Name="text" Then
			Return node.Text
		End If
	End If
	Dim xml As String=XMLUtils.asStringWithoutXMLHead(Me)
	Try
		Dim matcher As Matcher
		matcher=Regex.Matcher("(<.*?>).*(</.*?>)",xml)
		Dim parts As List
		parts.Initialize
		matcher.Find
		xml=xml.SubString2(0,matcher.GetStart(2))
		xml=xml.SubString2(matcher.GetEnd(1),xml.Length)
	Catch
		Log(LastException)
	End Try
	Return xml
End Sub

Public Sub setinnerXML(xml As String)
	If Children.Size=1 Then
		Dim node As XmlNode=Children.Get(0)
		If node.Name="text" Then
			node.Text=XMLUtils.EscapeXML(xml)
			Return
		End If
	End If
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<").Append(Name).Append(">")
	sb.append(xml)
	sb.Append("</").Append(Name).Append(">")
	Dim parser As XmlParser
	parser.Initialize
	Dim node As XmlNode=parser.Parse(EscapeXML(sb.ToString))
	If node.Name=Name Then
		node=node.Children.Get(0)
	End If
	Children=node.Children
	Attributes=node.Attributes
End Sub

Public Sub EscapeXML(xml As String) As String
	Dim st As SimpleTag
	st.Initialize
	Dim tags As List=st.getTags(xml)
	If tags.Size=0 Then
		Return XMLUtils.EscapeXml(xml)
	End If
	Dim parts As List
	parts.Initialize
	Dim previousEndIndex As Int=0
	For i=0 To tags.Size-1
		Dim tag As Tag=tags.Get(i)
		Dim textBefore As String=xml.SubString2(previousEndIndex,tag.index)
		textBefore=XMLUtils.EscapeXml(textBefore)
		If textBefore<>"" Then
			parts.Add(textBefore)
		End If
		parts.Add(tag.html)
		previousEndIndex=tag.index+tag.html.Length
	Next
	Dim textAfter As String
	textAfter=xml.SubString2(previousEndIndex,xml.Length)
	textAfter=XMLUtils.EscapeXml(textAfter)
	If textAfter<>"" Then
		parts.Add(textAfter)
	End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each s As String In parts
		sb.Append(s)
	Next
	'Log("escaped")
	'Log(sb.ToString)
	Return sb.ToString
End Sub
