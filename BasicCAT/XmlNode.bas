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
	Children.Initialize
	Attributes.Initialize
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

Public Sub replaceChildren(nodeName As String,nodes As List)
	For i=0 To Children.Size-1
		Dim node As XmlNode=Children.Get(i)
		If node.Name=nodeName Then
			If nodes.Size<>0 Then
				Children.Set(i,nodes.Get(0))
				nodes.RemoveAt(0)
			Else
				Return
			End If
		End If
	Next
End Sub

Public Sub getinnerXML As String
	If Children.Size=0 Then
		Return ""
	End If
	Dim xml As String=XMLUtils.asStringWithoutXMLHead(Me)
	Try
		Dim matcher As Matcher
		matcher=Regex.Matcher2("(<.*?>).*(</.*?>)",32,xml)
		Dim parts As List
		parts.Initialize
		If matcher.Find Then
			xml=xml.SubString2(0,matcher.GetStart(2))
			xml=xml.SubString2(matcher.GetEnd(1),xml.Length)
		End If
	Catch
		Log(LastException)
	End Try
	Return xml
End Sub

Public Sub setinnerXML(xml As String)
	Dim parser As XmlParser
	parser.Initialize
	Dim node As XmlNode
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<").Append(Name).Append(">")
	sb.append(xml)
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
	Children=node.Children
End Sub

Public Sub setinnerText(s As String)
	'If XMLUtils.XmlNodeContainsOnlyText(Me) Then
	'	Children.Clear
	'	s=XMLUtils.DiscloseTagText(s,False)
	'	Children.Add(CreateTextNode(s))
	'	Return
	'End If
	Try
		setinnerXML(XMLUtils.TextToXML(s))
	Catch
		Log(LastException)
		Children.Clear
		Children.Add(CreateTextNode(s))
	End Try
End Sub

Sub CreateTextNode (s As String) As XmlNode
	Dim xe As XmlNode
	xe.Initialize
	xe.Children.Initialize
	xe.Name = "text"
	xe.Text=s
	Return xe
End Sub

Public Sub getinnerText As String
	'If XMLUtils.XmlNodeContainsOnlyText(Me) Then
	'	Return XMLUtils.EncloseTagText(XMLUtils.XmlNodeText(Me),False)
	'End If
	Return XMLUtils.XMLToText(getinnerXML)
End Sub