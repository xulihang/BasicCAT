B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private TextArea1 As TextArea
	Private WebView1 As WebView
	Private frm As Form
	Private SourceComboBox As ComboBox
	Private TargetComboBox As ComboBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("MTCompare")
	fillComboBox
End Sub

Sub fillComboBox
	Dim langcodes As Map =Utils.readLanguageCode(File.Combine(File.DirData("BasicCAT"),"langcodes.txt"))
	For Each key As String In langcodes.Keys
		SourceComboBox.Items.Add(key)
		TargetComboBox.Items.Add(key)
	Next
End Sub

Public Sub show
	frm.Show
End Sub

Sub Button1_MouseClicked (EventData As MouseEvent)
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return
	End If
	Dim sourceLang,targetLang As String
	sourceLang=SourceComboBox.Items.Get(SourceComboBox.SelectedIndex)
	targetLang=TargetComboBox.Items.Get(TargetComboBox.SelectedIndex)
	Dim body As StringBuilder
	body.Initialize
	body.Append("<ol>")
	For Each engine As String In MT.getMTList
		If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
			wait for (MT.getMT(TextArea1.Text,sourceLang,targetLang,engine)) Complete (Result As String)
			If Result<>"" Then
				body.Append("<li>")
				body.Append("<p>")
				body.Append(engine)
				body.Append("</p>")
				body.Append("<p>")
				body.Append(Result)
				body.Append("</p>")
				body.Append("</li>")
				Sleep(50)
				WebView1.LoadHtml(buildHTML(body&"</ol>"))
			End If
		End If
	Next
	body.Append("</ol>")
	WebView1.LoadHtml(buildHTML(body))
End Sub

Sub buildHTML(body As String) As String
	Dim result As String
	Dim htmlhead As String
	htmlhead="<!DOCTYPE HTML><html><head><meta charset="&Chr(34)&"utf-8"&Chr(34)&" /><style type="&Chr(34)&"text/css"&Chr(34)&">p {font-size: 18px}</style></head><body>"
	Dim htmlend As String
	htmlend="</body></html>"
	result=htmlhead&body&htmlend
	Return result
End Sub