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
	'unescape: <g1>&amp;</g1>-><g1>&</g1>
	Dim xml As String=HandleXMLEntities(XMLUtils.asStringWithoutXMLHead(Me),False)
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
			node.Text=xml
			Return
		End If
	End If

	Dim parser As XmlParser
	parser.Initialize
	'escape: <g1>&</g1>-><g1>&amp;</g1>
	Dim escaped As String=HandleXMLEntities(xml,True)
	Dim node As XmlNode
	Try
		node=parser.Parse(escaped)
	Catch
		Log(LastException.Message)
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append("<").Append(Name).Append(">")
		sb.append(escaped)
		sb.Append("</").Append(Name).Append(">")
		node=parser.Parse(sb.ToString)
		'Log("-------")
		'Log(sb.ToString)
		'Log(node.Name)
		'Log(Name)
		Dim child As XmlNode=node.Children.Get(0)
		If child.Name=Name Then
			node=node.Children.Get(0)
		End If
	End Try
	Children=node.Children
	Attributes=node.Attributes
End Sub

Public Sub HandleXMLEntities(xml As String,escape As Boolean) As String
	Dim st As SimpleTag
	st.Initialize
	Dim tags As List=st.getTags(xml)
	If tags.Size=0 Then
		If escape Then
			Return XMLUtils.EscapeXml(xml)
		Else
			Return XMLUtils.UnescapeXml(xml)
		End If
	End If
	Dim parts As List
	parts.Initialize
	Dim previousEndIndex As Int=0
	For i=0 To tags.Size-1
		Dim tag As Tag=tags.Get(i)
		Dim textBefore As String=xml.SubString2(previousEndIndex,tag.index)
		If escape Then
			textBefore=XMLUtils.EscapeXml(textBefore)
		Else
			textBefore=XMLUtils.UnescapeXml(textBefore)
		End If
		
		If textBefore<>"" Then
			parts.Add(textBefore)
		End If
		parts.Add(tag.html)
		previousEndIndex=tag.index+tag.html.Length
	Next
	Dim textAfter As String
	textAfter=xml.SubString2(previousEndIndex,xml.Length)
	If textAfter<>"" Then
		If escape Then
			textAfter=XMLUtils.EscapeXml(textAfter)
		Else
			textAfter=XMLUtils.UnescapeXml(textAfter)
		End If
		parts.Add(textAfter)
	End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each s As String In parts
		sb.Append(s)
	Next
	Return sb.ToString
End Sub
