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
	Private FacingPageCheckBox As CheckBox
	Private IncludePageNumCheckBox As CheckBox
	Private PageAffixTextField As TextField
	Private offsetTextField As TextField
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
	Dim pdfbox1 As pdfbox
	pdfbox1.Initialize(label1.Text)
	If IncludePageNumCheckBox.Checked Then
		If offsetTextField.Text="" Or PageAffixTextField.Text=""  Then
			fx.Msgbox(frm,"Please fill affix and offset first.","")
			Return
		End If
		TextArea1.text=pdfbox1.stripPDFText(True,FacingPageCheckBox.Checked,PageAffixTextField.Text,offsetTextField.Text)
	Else
		TextArea1.text=pdfbox1.stripPDFText(False,False,"",0)
	End If
End Sub

Sub reflowButton_MouseClicked (EventData As MouseEvent)
	TextArea1.text=removeLines(TextArea1.Text)
	If IncludePageNumCheckBox.Checked Then
		TextArea1.Text=Regex.Replace(PageAffixTextField.Text&" "&"\d+-*\d*",TextArea1.Text,CRLF&CRLF&"$0"&CRLF&CRLF)
	End If
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
	If IncludePageNumCheckBox.Checked Then
		If offsetTextField.Text="" Or PageAffixTextField.Text=""  Then
			fx.Msgbox(frm,"Please fill affix and offset first.","")
			Return
		End If
	End If
	wait for (testTesseractPath) complete (exists As Boolean)
	If exists=False Then
		Return
	End If
	
	Dim lc As languageChooser
	lc.Initialize
	Dim langsParam As String=lc.ShowAndWait
	If langsParam="" Then
		Return
	End If

	Label2.Text="Converting pdf to images..."
	Dim files As List
	files.Initialize
	Dim dir As String=File.GetFileParent(label1.Text)
	Dim filename As String=File.GetName(label1.Text)
	Dim pdfbox1 As pdfbox
	pdfbox1.Initialize(File.Combine(dir,filename))
	wait for (pdfbox1.getImageAsync()) complete (result As Object)
	For i=0 To pdfbox1.PageNum-1
		files.Add(File.Combine(dir,i&".jpg"))
	Next

	Label2.Text="OCRing..."
	If IncludePageNumCheckBox.Checked Then
		wait for (ocrWithPagenum(files,langsParam,PageAffixTextField.Text,offsetTextField.Text)) complete (text As String)
	Else
		wait for (ocr(files,langsParam)) complete (text As String)
	End If
	Label2.Text="Completed"
	TextArea1.Text=text
End Sub

Sub testTesseractPath As ResumableSub
	Dim path As String
	If File.Exists(File.DirData("BasicCAT"),"tesseractPath") Then
		path=File.ReadString(File.DirData("BasicCAT"),"tesseractPath")
	Else
		path="tesseract"
	End If
	
	Dim sh1 As Shell
	sh1.Initialize("sh1",path,Null)
	sh1.Run(-1)
	Dim exist As Boolean=False
	wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		exist=True
		Log("Success")
		File.WriteString(File.DirData("BasicCAT"),"tesseractPath",path)
	Else
		Log("Error: " & StdErr)
		Dim result As Int
		result=fx.Msgbox2(frm,"Tesseract is not installed or path not been configured."&CRLF&"Choose existing tesseract executable?","","Yes","Cancel","",fx.MSGBOX_CONFIRMATION)
		If result=fx.DialogResponse.POSITIVE Then
			Dim fc As FileChooser
			fc.Initialize
			fc.Title="Choose tesseract.exe on windows"
			Dim path As String=fc.ShowOpen(frm)
			Dim sh1 As Shell
			sh1.Initialize("sh1",path,Null)
			sh1.Run(-1)
			wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
			If Success And ExitCode = 0 Then
				Log("Success")
				exist=True
				File.WriteString(File.DirData("BasicCAT"),"tesseractPath",path)
			Else
				Log("Error: " & StdErr)
			End If
		End If
	End If
	Return exist
End Sub

Sub ocrWithPagenum(files As List,langsParam As String,affix As String,offset As Int) As ResumableSub
	Dim dir As String
	dir=File.GetFileParent(label1.Text)
	Dim pdfFilename As String
	pdfFilename=File.GetName(label1.Text)
	Dim path As String
	If File.Exists(File.DirData("BasicCAT"),"tesseractPath") Then
		path=File.ReadString(File.DirData("BasicCAT"),"tesseractPath")
	Else
		path="tesseract"
	End If
	Dim contentSB As StringBuilder
	contentSB.Initialize
	Dim pdfnum As Int=0
	For i=0 To files.Size-1
		pdfnum=pdfnum+1
		Dim pageStart As String
		If pdfnum=1 Then
			pageStart=affix&" "&(pdfnum-offset)
		Else
			If FacingPageCheckBox.Checked Then
				pageStart=affix&" "&(pdfnum-offset+pdfnum-2)&"-"&(pdfnum+1-offset+pdfnum-2)
			Else
				pageStart=affix&" "&(pdfnum-offset)
			End If
		End If
		Dim args As List
		args.Initialize
		args.AddAll(Array As String(i&".jpg",i,"-l",langsParam))
		

		Dim sh1 As Shell
		sh1.Initialize("sh1",path,args)
		sh1.WorkingDirectory = dir
		sh1.Run(-1)

		wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
		If Success And ExitCode = 0 Then
			Log("Success")
			Log(StdOut)
			contentSB.Append(pageStart).Append(CRLF)
			contentSB.Append(CRLF).Append(File.ReadString(dir,i&".txt"))
			'removeLines
		Else
			Log("Error: " & StdErr)
		End If
		

	Next
	
	Return contentSB.ToString
End Sub

Sub ocr(files As List,langsParam As String) As ResumableSub
	Dim dir As String
	dir=File.GetFileParent(label1.Text)
	Dim pdfFilename As String
	pdfFilename=File.GetName(label1.Text)
	File.WriteList(dir,"imgList",files)
	Dim path As String
	If File.Exists(File.DirData("BasicCAT"),"tesseractPath") Then
		path=File.ReadString(File.DirData("BasicCAT"),"tesseractPath")
	Else
		path="tesseract"
	End If
	Dim args As List
	args.Initialize
	args.AddAll(Array As String("imgList",pdfFilename,"-l",langsParam))
	Dim sh1 As Shell
	sh1.Initialize("sh1",path,args)
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

Sub IncludePageNumCheckBox_CheckedChange(Checked As Boolean)
	FacingPageCheckBox.Enabled=Checked
	PageAffixTextField.Enabled=Checked
	offsetTextField.Enabled=Checked
End Sub
