B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub stripPDFText(filepath As String) As String
	Dim PDDocument As JavaObject
	PDDocument.InitializeStatic("org.apache.pdfbox.pdmodel.PDDocument")
	Dim doc As JavaObject
	doc=PDDocument.RunMethodJO("load",Array(getFile(filepath)))
	Dim PDFTextStripper As JavaObject
	PDFTextStripper.InitializeNewInstance("org.apache.pdfbox.text.PDFTextStripper",Null)
	Dim text As String
	text=PDFTextStripper.RunMethod("getText",Array(doc))
	Log(text)
	Return text
End Sub

Sub getImage(dir As String,filename As String) As ResumableSub
	Dim files As List
	files.Initialize
	SetSystemProperty("sun.java2d.cmm", "sun.java2d.cmm.kcms.KcmsServiceProvider")
	Dim PDDocument As JavaObject
	PDDocument.InitializeStatic("org.apache.pdfbox.pdmodel.PDDocument")
	Dim doc As JavaObject
	doc=PDDocument.RunMethodJO("load",Array(getFile(File.Combine(dir,filename))))
	Dim pageNum As Int
	pageNum=doc.RunMethod("getNumberOfPages",Null)
	Dim PDFRenderer As JavaObject
	PDFRenderer.InitializeNewInstance("org.apache.pdfbox.rendering.PDFRenderer",Array(doc))
	For i=0 To 2
		Log(i)
		Sleep(0)
		Dim bi As JavaObject
		Dim dpi As Float
		dpi=150
		bi=PDFRenderer.RunMethodJO("renderImageWithDPI",Array(i,dpi))
		Dim out As OutputStream
		out=File.OpenOutput(dir,filename&"-"&i&".jpg",False)
		Dim imageIO As JavaObject
		imageIO.InitializeStatic("javax.imageio.ImageIO")
		imageIO.RunMethod("write",Array(bi,"jpg",out))
		out.Close
		files.Add(File.Combine(dir,filename&"-"&i&".jpg"))
	Next
	Return files
End Sub

Sub getFile(path As String) As JavaObject
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array(path))
	Return fileJO
End Sub