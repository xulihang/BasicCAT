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

Public Sub ScrollBarWidth(dir As String) As Double
	If File.Exists(dir,"scrollbar_width") Then
		Return File.ReadString(dir,"scrollbar_width").Trim
	End If
	Return 20dip
End Sub

Public Sub StatusBarColor(dir As String) As Paint
	If File.Exists(dir,"statusbar_bgcolor") Then
		Dim rgb As String=File.ReadString(dir,"statusbar_bgcolor").Trim
		Return getPaintFromRGB(rgb,fx.Colors.White)
	End If
	Return fx.Colors.White
End Sub

Public Sub RichTextHighLightColor(dir As String) As Paint
	If File.Exists(dir,"richtext_highlightcolor") Then
		Dim rgb As String=File.ReadString(dir,"richtext_highlightcolor").Trim
		Return getPaintFromRGB(rgb,fx.Colors.DarkGray)
	End If
	Return fx.Colors.DarkGray
End Sub

Sub getPaintFromRGB(rgb As String,default As Paint) As Paint
	Try
		Dim r,g,b As Int
		r=Regex.Split(",",rgb)(0)
		g=Regex.Split(",",rgb)(1)
		b=Regex.Split(",",rgb)(2)
		Return fx.Colors.Rgb(r,g,b)
	Catch
		Log(LastException)
	End Try
	Return default
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

Public Sub RichTextBGColor(dir As String) As Paint
	If File.Exists(dir,"richtext_bgcolor") Then
		Dim rgb As String=File.ReadString(dir,"richtext_bgcolor").Trim
		Return getPaintFromRGB(rgb,fx.Colors.White)
	End If
	Return fx.Colors.White
End Sub