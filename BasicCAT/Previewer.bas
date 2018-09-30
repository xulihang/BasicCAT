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
	If Main.editorLV.Size<>Main.currentProject.segments.Size Then
		Return
	End If
	For i=Max(0,Main.currentProject.lastEntry-3) To Min(Main.currentProject.lastEntry+7,Main.currentProject.segments.Size-1)

		Dim p As Pane
		p=Main.editorLV.GetPanel(i)
		Dim sourceTextArea As TextArea
		Dim targetTextArea As TextArea
		sourceTextArea=p.GetNode(0)
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=Main.currentProject.segments.Get(i)
		Dim source,target,fullsource,translation As String
		source=sourceTextArea.Text
		target=targetTextArea.Text
		fullsource=bitext.Get(2)
		If target="" Then
			translation=fullsource
		Else
			translation=fullsource.Replace(source,target)
			If Main.currentProject.projectFile.Get("source")="en" Then
				translation=translation.Replace(" ","")
			End If
		End If
		If i=Main.currentProject.lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
		End If
		text=text&translation
	Next
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
