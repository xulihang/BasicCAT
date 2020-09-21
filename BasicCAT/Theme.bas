B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Public Sub load(form As Form,dir As String)
	If File.IsDirectory(dir,"") Then
		For Each filename As String In File.ListFiles(dir)
			If filename.EndsWith(".css") Then
				form.Stylesheets.Add(File.GetUri(dir,filename))
			End If
		Next
	End If
End Sub

Public Sub WebViewBGColor(dir As String) As String
	If File.Exists(dir,"webview_bgcolor") Then
		Return File.ReadString(dir,"webview_bgcolor").Trim
	Else
		Return ""
	End If
End Sub

Public Sub WebViewTextColor(dir As String) As String
	If File.Exists(dir,"webview_textcolor") Then
		Return File.ReadString(dir,"webview_textcolor").Trim
	Else
		Return ""
	End If
End Sub

Public Sub RichTextColor(dir As String) As String
	If File.Exists(dir,"richtext_textcolor") Then
		Return File.ReadString(dir,"richtext_textcolor").Trim
	Else
		Return ""
	End If
End Sub

Public Sub RichTextBGColor(dir As String) As String
	If File.Exists(dir,"richtext_bgcolor") Then
		Return File.ReadString(dir,"richtext_bgcolor").Trim
	Else
		Return ""
	End If
End Sub