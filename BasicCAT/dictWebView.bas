B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private WebView1 As WebView
	Private currentUrl As String
	Private dictComboBox As ComboBox
	Private dictMap As Map
	Private selected As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("dictWebview")

	dictMap.Initialize
	Dim dictList As List
	Dim configPath As String=File.Combine(projectPath,"config")
	If File.Exists(configPath,"dictList.txt") Then
		dictList=File.ReadList(configPath,"dictList.txt")
	Else
		dictList=File.ReadList(File.DirAssets,"dictList.txt")
	End If
	For Each line As String In dictList
		dictMap.Put(Regex.Split("	",line)(0),Regex.Split("	",line)(1))
	Next
	For Each key As String In dictMap.Keys
		dictComboBox.Items.Add(key)
	Next

End Sub

Public Sub show
	frm.AlwaysOnTop=False
	frm.AlwaysOnTop=True
	frm.Show
End Sub

Sub OpenButton_MouseClicked (EventData As MouseEvent)
	fx.ShowExternalDocument(currentUrl)
End Sub

Sub AddSelectedButton_MouseClicked (EventData As MouseEvent)
	addTextFromDict(getSelectedText)
End Sub

Sub getSelectedText As String
	Dim we As JavaObject
	we = asJO(WebView1).RunMethod("getEngine",Null)
	Dim jscode As String
	jscode=$"document.getSelection()+"";"$
	Return we.RunMethod("executeScript",Array As String(jscode))
End Sub

Sub addTextFromDict(text As String)
	If Main.currentProject.IsInitialized Then
		If Main.editorLV.Items.Size=0 Then
			Return
		End If
		Dim p As Pane
		p=Main.editorLV.Items.Get(Main.currentProject.lastEntry)
		If p.NumberOfNodes=0 Then
			Return
		End If
		Dim ta As RichTextArea
		ta=p.Getnode(1).Tag
		Dim endPos As Int=ta.SelectionEnd
		ta.Text=ta.Text.SubString2(0,endPos)&text&ta.Text.SubString2(endPos,ta.Text.Length)
		ta.SetSelection(endPos+text.Length,endPos+text.Length)
	End If
End Sub

Public Sub loadUrl(url As String,selectedText As String)
	selected=selectedText
	url=url.Replace("*",selectedText)
	WebView1.LoadUrl(url)
	currentUrl=url
End Sub

Sub WebView1_PageFinished (Url As String)
	currentUrl=Url
End Sub

Sub WebView1_LocationChanged (Location As String)

End Sub

Sub asJO(o As JavaObject) As JavaObject
	Return o
End Sub

Sub dictComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	Log(Value)
	loadUrl(dictMap.Get(Value),selected)
End Sub

Sub SetSelectedButton_MouseClicked (EventData As MouseEvent)
	selected=getSelectedText
End Sub