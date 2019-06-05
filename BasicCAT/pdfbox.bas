B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.32
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private th As Thread
	Private doc As JavaObject
	Private path As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(filePath As String)
	th.Initialise("th")
	path=filePath
	Dim PDDocument As JavaObject
	PDDocument.InitializeStatic("org.apache.pdfbox.pdmodel.PDDocument")
	doc=PDDocument.RunMethodJO("load",Array(getFile(filePath)))
End Sub

Public Sub stripPDFText(includePageNum As Boolean,isFacingPage As Boolean,affix As String,offset As Int) As String

	Dim PDFTextStripper As JavaObject
	PDFTextStripper.InitializeNewInstance("org.apache.pdfbox.text.PDFTextStripper",Null)
	Dim pageNum As Int
	pageNum=doc.RunMethod("getNumberOfPages",Null)
	Dim text As String
	If includePageNum Then

		For i=1 To pageNum
			PDFTextStripper.RunMethod("setStartPage",Array(i))
			PDFTextStripper.RunMethod("setEndPage",Array(i))
			Dim pageStart As String
			If i=1 Then
				pageStart=affix&" "&(i-offset)
			Else
				If isFacingPage Then
					pageStart=affix&" "&(i-offset+i-2)&"-"&(i+1-offset+i-2)
				Else
					pageStart=affix&" "&(i-offset)
				End If
			End If
			pageStart=CRLF&pageStart&CRLF&CRLF
			PDFTextStripper.RunMethod("setPageStart",Array(pageStart))
			text=text&PDFTextStripper.RunMethod("getText",Array(doc))
		Next
	Else
		text=PDFTextStripper.RunMethod("getText",Array(doc))
	End If
	Log(text)
	Return text
End Sub


Public Sub getPageNum As Int
	Dim files As List
	files.Initialize
	SetSystemProperty("sun.java2d.cmm", "sun.java2d.cmm.kcms.KcmsServiceProvider")
	Dim pageNum As Int
	pageNum=doc.RunMethod("getNumberOfPages",Null)
    Return pageNum
End Sub

Public Sub getImageAsync As ResumableSub
	th.Start(Me,"getImage",Array As Object("placeholder"))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Return endedOK
End Sub

Public Sub getImage(param As String)
	Dim files As List
	files.Initialize
	SetSystemProperty("sun.java2d.cmm", "sun.java2d.cmm.kcms.KcmsServiceProvider")
	Dim PDDocument As JavaObject
	PDDocument.InitializeStatic("org.apache.pdfbox.pdmodel.PDDocument")
	Dim pageNum As Int
	pageNum=doc.RunMethod("getNumberOfPages",Null)
	Dim PDFRenderer As JavaObject
	PDFRenderer.InitializeNewInstance("org.apache.pdfbox.rendering.PDFRenderer",Array(doc))
	For i=0 To pageNum-1
		Log(i)
		'Sleep(0)
		'files.Add(File.Combine(dir,i&".jpg"))
		renderImageToFile(PDFRenderer,File.GetFileParent(path),i)
	Next
	'Return files
End Sub

Sub renderImageToFile(PDFRenderer As JavaObject,dir As String,i As Int)
	Dim bi As JavaObject
	Dim dpi As Float
	dpi=150
	bi=PDFRenderer.RunMethodJO("renderImageWithDPI",Array(i,dpi))
	Dim out As OutputStream
	out=File.OpenOutput(dir,i&".jpg",False)
	Dim imageIO As JavaObject
	imageIO.InitializeStatic("javax.imageio.ImageIO")
	imageIO.RunMethod("write",Array(bi,"jpg",out))
	out.Close
End Sub

Sub getFile(filepath As String) As JavaObject
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array(filepath))
	Return fileJO
End Sub