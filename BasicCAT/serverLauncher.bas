B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private languageToolPathTextField As TextField
	Private stanfordPathTextField As TextField
	Private languageToolShell As Shell
	Private corenlpShell As Shell
	Private launchCorenlpButton As Button
	Private launchLanguageToolButton As Button
	Private pathSetting As Map
	Private javaPath As String="java"
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("serverLanucher")
	testJavaPath
	If File.Exists(File.DirData("BasicCAT"),"serverpath") Then
		pathSetting=File.ReadMap(File.DirData("BasicCAT"),"serverpath")
		If pathSetting.ContainsKey("languagetool") Then
			languageToolPathTextField.Text=pathSetting.Get("languagetool")
		End If
		If pathSetting.ContainsKey("corenlp") Then
			stanfordPathTextField.Text=pathSetting.Get("corenlp")
		End If
	Else
		pathSetting.Initialize
	End If
End Sub

Public Sub show
	frm.Show
End Sub

Sub frm_CloseRequest (EventData As Event)
	Dim result As Int
	result=fx.Msgbox2(frm,"Servers will be closed, continue?","","Yes","Cancel","",fx.MSGBOX_CONFIRMATION)
	Select result
		'yes -1, no -2, cancel -3
		Case -3
			EventData.Consume
	End Select
	Try
		corenlpShell.KillProcess
	Catch
		Log(LastException)
	End Try
	Try
		languageToolShell.KillProcess
	Catch
		Log(LastException)
	End Try
End Sub

Sub testJavaPath As ResumableSub
	Dim sh1 As Shell
	sh1.Initialize("sh1","java",Array As String("-version"))
	sh1.Run(5000)
	wait for sh1_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		javaPath="java"
		Return True
	Else
		Log("Error: " & StdErr)
		Dim newPath As String
		Dim javaHomePath As String=GetSystemProperty("java.home","")
		Dim seperator As String=GetSystemProperty("file.separator","")
		newPath=javaHomePath&seperator&"/bin/java"
		Log(newPath)
		Dim sh2 As Shell
		sh2.Initialize("sh2",newPath,Array As String("-version"))
		sh2.Run(5000)
		wait for sh2_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
		If Success And ExitCode = 0 Then
			Log("Success")
			javaPath=newPath
			Return True
		Else
			Log("Error: " & StdErr)
			fx.Msgbox(frm,"java is not installed or path not been configured","")
			Return False
		End If
	End If
End Sub

Sub stanfordButton_MouseClicked (EventData As MouseEvent)
	Dim dc As DirectoryChooser
	dc.Initialize
	stanfordPathTextField.Text=dc.Show(frm)
	pathSetting.Put("corenlp",stanfordPathTextField.Text)
	File.WriteMap(File.DirData("BasicCAT"),"serverpath",pathSetting)
End Sub

Sub languageToolButton_MouseClicked (EventData As MouseEvent)
	Dim dc As DirectoryChooser
	dc.Initialize
	languageToolPathTextField.Text=dc.Show(frm)
	pathSetting.Put("languagetool",languageToolPathTextField.Text)
	File.WriteMap(File.DirData("BasicCAT"),"serverpath",pathSetting)
End Sub

Sub launchLanguageToolButton_MouseClicked (EventData As MouseEvent)
	If languageToolPathTextField.Text="" Then
		Return
	End If
	If launchLanguageToolButton.Text="Stop LanguageTool Server" Then
		languageToolShell.KillProcess
		launchLanguageToolButton.Text="Start LanguageTool Server"
	Else
		launchLanguageToolServer
		launchLanguageToolButton.Text="Stop LanguageTool Server"
	End If
	
End Sub

Sub launchCorenlpButton_MouseClicked (EventData As MouseEvent)
	If stanfordPathTextField.Text="" Then
		Return
	End If
	If launchCorenlpButton.Text="Stop CoreNLP Server" Then
		corenlpShell.KillProcess
		launchCorenlpButton.Text="Start CoreNLP Server"
	Else
		launchCorenlpServer
		launchCorenlpButton.Text="Stop CoreNLP Server"
	End If
	
End Sub

Sub launchLanguageToolServer
	languageToolShell.Initialize("languageToolShell",javaPath,Array As String("-cp","languagetool-server.jar","org.languagetool.server.HTTPServer","--port","8081"))
	languageToolShell.WorkingDirectory = languageToolPathTextField.Text
	languageToolShell.RunWithOutputEvents(-1)
End Sub

Sub launchCorenlpServer
	If GetSystemProperty("os.arch","")="x86" Then
		fx.Msgbox(frm,"You are currently running on an x86 version of java. The corenlp may be lack of memory.","")
		corenlpShell.Initialize("corenlpShell",javaPath,Array As String("-cp",$""*""$, "edu.stanford.nlp.pipeline.StanfordCoreNLPServer", "-port", "9000", "-timeout", "15000"))
		corenlpShell.WorkingDirectory = stanfordPathTextField.Text
		corenlpShell.RunWithOutputEvents(-1)
	Else
		corenlpShell.Initialize("corenlpShell",javaPath,Array As String("-mx4g","-cp",$""*""$, "edu.stanford.nlp.pipeline.StanfordCoreNLPServer", "-port", "9000", "-timeout", "15000"))
		corenlpShell.WorkingDirectory = stanfordPathTextField.Text
		corenlpShell.RunWithOutputEvents(-1)
	End If
End Sub
