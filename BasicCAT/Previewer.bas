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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("preview")
End Sub

Public Sub Show
	loadText
	frm.AlwaysOnTop=True
	frm.Show
End Sub

Public Sub isShowing As Boolean
	Return frm.Showing
End Sub

Public Sub loadText
	Dim text As String
	Dim currentFilename As String
	currentFilename=Main.currentProject.currentFilename
	If currentFilename.EndsWith(".txt") Then
		text=txtFilter.previewText
	else if currentFilename.EndsWith(".idml") Then
		text=idmlFilter.previewText
	End If
	loadHtml(text)
End Sub

Sub loadHtml(text As String)
	text=Regex.Replace("\r",text,"")
	text=Regex.Replace("\n",text,"<br/>")
	Dim htmlhead,htmlend As String
	htmlhead=$"<!DOCTYPE HTML>
	<html>
	<head>
	<meta charset="utf-8"/>
	<style type="text/css">
	#current {color:green;}
	</style>
 </head><body><p>
	"$
	
	htmlend=$"</p></body>
		<script language="javascript" type="text/javascript"> 
         window.location.hash = "#current";
    </script>
	</html>"$
	text=htmlhead&text&htmlend
	WebView1.LoadHtml(text)
	Log(text)
End Sub
