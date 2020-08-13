B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private mDoc As JavaObject
	Private bc As ByteConverter 'ignore
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	Dim factory As JavaObject
	factory.InitializeStatic("javax.xml.parsers.DocumentBuilderFactory")
	Dim dbFactory As JavaObject
	dbFactory=factory.RunMethod("newInstance",Null)
	Dim builder As JavaObject
	builder=dbFactory.RunMethod("newDocumentBuilder",Null)
	mDoc=builder.RunMethod("newDocument",Null)
End Sub

Public Sub getDoc As JavaObject
	Return mDoc
End Sub

Public Sub e(name As String) As JavaObject
	Return createElement(name)
End Sub

Public Sub t(text As String) As JavaObject
	Return createTextNode(text)
End Sub

Public Sub a(name As String,value As String) As JavaObject
	Return createAttribute(name,value)
End Sub


Public Sub createElement(name As String) As JavaObject
	Return mDoc.RunMethod("createElement",Array(name))
End Sub

Public Sub createTextNode(text As String) As JavaObject
	Return mDoc.RunMethod("createTextNode",Array(text))
End Sub

Public Sub appendChild(rootElement As JavaObject, node As Object)
	rootElement.RunMethod("appendChild",Array(node))
End Sub

Public Sub createAttribute(name As String,value As String) As JavaObject
	Dim attr As JavaObject=mDoc.RunMethod("createAttribute",Array(name))
	attr.RunMethod("setValue",Array(value))
	Return attr
End Sub

Public Sub setAttributeNode(attr As Object,element As JavaObject)
	element.RunMethod("setAttributeNode",Array(attr))
End Sub

Public Sub asString As String
	Dim transformerFactory As JavaObject
	transformerFactory.InitializeStatic("javax.xml.transform.TransformerFactory")
	transformerFactory=transformerFactory.RunMethod("newInstance",Null)
	Dim transformer As JavaObject
	transformer=transformerFactory.RunMethod("newTransformer",Null)
	Dim source As JavaObject
	source.InitializeNewInstance("javax.xml.transform.dom.DOMSource",Array(mDoc))
	Dim out As OutputStream
	out=File.OpenOutput(File.DirTemp,"temp.xml",False)
	Dim result As JavaObject
	result.InitializeNewInstance("javax.xml.transform.stream.StreamResult",Array(out))
	transformer.RunMethod("transform",Array(source,result))
	out.Close
	If File.Exists(File.DirTemp,"temp.xml") Then
		Return File.ReadString(File.DirTemp,"temp.xml")
	End If
	Return ""
End Sub