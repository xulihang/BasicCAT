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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("dictWebview")
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
	Dim we As JavaObject
	we = asJO(WebView1).RunMethod("getEngine",Null)
	Dim jscode As String
	jscode=$"document.getSelection()+"";"$
	addTextFromDict(we.RunMethod("executeScript",Array As String(jscode)))
End Sub


Sub addTextFromDict(text As String)
	If Main.currentProject.IsInitialized Then
		If Main.editorLV.Size=0 Then
			Return
		End If
		Dim p As Pane
		p=Main.editorLV.GetPanel(Main.currentProject.lastEntry)
		If p.NumberOfNodes=0 Then
			Return
		End If
		Dim ta As TextArea
		ta=p.Getnode(1)
		Dim endPos As Int=ta.SelectionEnd
		ta.Text=ta.Text.SubString2(0,endPos)&text&ta.Text.SubString2(endPos,ta.Text.Length)
		ta.SetSelection(endPos+text.Length,endPos+text.Length)
	End If
End Sub

Public Sub loadUrl(url As String)
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