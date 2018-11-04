B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private TextArea1 As TextArea
	Private label1 As Label
	Private Label2 As Label
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,500)
	frm.RootPane.LoadLayout("pdf2txt")
End Sub

Public Sub Show
	frm.Show
End Sub

Sub StripButton_MouseClicked (EventData As MouseEvent)
	If label1.Text="" Then
		fx.Msgbox(frm,"Please choose a pdf file first.","")
		Return
	End If
	TextArea1.text=pdfbox.stripPDFText(label1.Text)
End Sub

Sub reflowButton_MouseClicked (EventData As MouseEvent)
	TextArea1.text=removeLines(TextArea1.Text)
End Sub

Sub choosePDFButton_MouseClicked (EventData As MouseEvent)
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("PDF",Array As String("*.pdf"))
	label1.Text=fc.ShowOpen(frm)

End Sub


Sub removeLines(input As String) As String
	Dim result As String
	Dim list1 As List
	list1.Initialize
	list1.AddAll(Regex.Split(CRLF,input))
	Log(list1)

	For Each line As String In list1
		line=line.Trim
		Log(line)
		If line="" Or line=" " Then
			Continue
		End If
		If isSentenceEnd(line)=False Then
			result=result&" "&line
		Else
			result=result&" "&line&CRLF
		End If
	Next



	Dim list2 As List
	list2.Initialize
	list2.AddAll(Regex.Split(CRLF,result))
	result=""
	For Each line As String In list2
		result=result&line.Trim&CRLF&CRLF
	Next
	Return result
End Sub

Sub isSentenceEnd(line As String) As Boolean
	If line.EndsWith(".") Or line.EndsWith("!") Or line.EndsWith("?") Or line.EndsWith(";") Or line.EndsWith(Chr(34)) Then
		Return True
	Else
		Return False
	End If
End Sub


Sub ocrButton_MouseClicked (EventData As MouseEvent)
	If label1.Text="" Then
		fx.Msgbox(frm,"Please choose a pdf file first.","")
		Return
	End If
	wait for (testTesseractPath) complete (exists As Boolean)
	If exists=False Then
		Return
	End If
	
	Dim lc As languageChooser
	lc.Initialize
	Dim langs As List
	langs=lc.ShowAndWait
	Dim langsParam As String
	For Each chkBox As CheckBox In langs
		If chkBox.Checked Then
			langsParam=langsParam&chkBox.Text&"+"
		End If
	Next
	If langsParam.EndsWith("+") Then
		langsParam=langsParam.SubString2(0,langsParam.Length-1)
	End If
	Log(langsParam)
	If langsParam="" Then
		Return
	End If

	Label2.Text="Convert pdf to images..."
	Dim files As List
	wait for (pdfbox.getImage(File.GetFileParent(label1.Text),File.GetName(label1.Text))) complete (result As List)
	files=result
	Label2.Text="OCRing..."
	wait for (scan(files,langsParam)) complete (text As String)
	Label2.Text="Completed"
	TextArea1.Text=text
End Sub

Sub testTesseractPath As ResumableSub
	Dim sh1 As Shell
	sh1.Initialize("sh1","tesseract",Null)
	sh1.Run(500)
	wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		Return True
	Else
		Log("Error: " & StdErr)
		fx.Msgbox(frm,"Tesseract is not installed or path not been configured","")
		Return False
	End If
End Sub

Sub scan(files As List,langsParam As String) As ResumableSub
	Dim dir As String
	dir=File.GetFileParent(label1.Text)
	Dim pdfFilename As String
	pdfFilename=File.GetName(label1.Text)
	File.WriteList(dir,"imgList",files)
	Dim args As List
	args.Initialize
	args.AddAll(Array As String("imgList",pdfFilename,"-l",langsParam))
	Dim sh1 As Shell
	sh1.Initialize("sh1","tesseract",args)
	sh1.WorkingDirectory = dir
	sh1.Run(-1)

	wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		Log(StdOut)
	Else
		Log("Error: " & StdErr)
		fx.Msgbox(frm,StdErr,"")
	End If
	Return File.ReadString(dir,pdfFilename&".txt")
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	Dim dir As String
	dir=File.GetFileParent(label1.Text)
	Dim pdfFilename As String
	pdfFilename=File.GetName(label1.Text)
	File.WriteString(dir,pdfFilename&".txt",TextArea1.Text)
	fx.Msgbox(frm,"File exported to "&dir,"")
End Sub