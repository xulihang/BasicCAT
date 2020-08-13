B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private parser As SaxParser
	Private elements As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	parser.Initialize
End Sub

Public Sub Parse(XML As String) As XmlNode
	Dim in As InputStream
	Dim b() As Byte = XML.GetBytes("UTF8")
	in.InitializeFromBytesArray(b, 0, b.Length)
	Return Parse2(in)
End Sub

Public Sub Parse2(Input As InputStream) As XmlNode
	Dim root As XmlNode=CreateElement("stub")
	elements.Initialize
	elements.Add(root)
	parser.Parse(Input, "parser")
	Return root
End Sub

Private Sub CreateElement (Name As String) As XmlNode
	Dim xe As XmlNode
	xe.Initialize
	xe.Children.Initialize
	xe.Name = Name
	Return xe
End Sub

Private Sub CreateTextNode (text As String) As XmlNode
	Dim xe As XmlNode
	xe.Initialize
	xe.Children.Initialize
	xe.Name = "text"
	xe.Text=text
	Return xe
End Sub
	
#if B4i
Private Sub Parser_StartElement (Uri As String, Name As String, Attributes As Map)
#Else
Private Sub Parser_StartElement (Uri As String, Name As String, Attributes As Attributes)
#End If
	'Log("Start")
	Dim Element As XmlNode = CreateElement(Name)
	If Attributes.IsInitialized And Attributes.Size > 0 Then
		Dim att As Map
		#if B4i
		att = Attributes
		#Else
		att.Initialize
		For i = 0 To Attributes.Size - 1
			att.Put(Attributes.GetName(i), Attributes.GetValue(i))
		Next
		#End If
		Element.Attributes = att
	End If
	GetLastElement.Children.Add(Element)
	elements.Add(Element)
End Sub

Private Sub GetLastElement As XmlNode
	Return elements.Get(elements.Size - 1)
End Sub

Private Sub Parser_EndElement (Uri As String, Name As String, Text As StringBuilder)
	'Log("end")
	elements.RemoveAt(elements.Size - 1)
End Sub

Private Sub Parser_Characters (Text As String)
	'Log("character")
	If TextWithoutCRLF(Text)<>"" Then
		GetLastElement.Children.Add(CreateTextNode(Text))
	End If
End Sub

Sub TextWithoutCRLF(s As String) As String
	Return s.Replace(CRLF,"")
End Sub