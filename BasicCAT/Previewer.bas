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
	Private fontsize As Int=16
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
	Dim filenameLowercase As String
	filenameLowercase=currentFilename.ToLowerCase
	If filenameLowercase.EndsWith(".txt") Then
		text=txtFilter.previewText
	else if filenameLowercase.EndsWith(".idml") Then
		text=idmlFilter.previewText
	else if filenameLowercase.EndsWith(".xlf") Then
		text=xliffFilter.previewText
	Else
		Dim params As Map
		params.Initialize
		params.Put("editorLV",Main.editorLV)
		params.Put("segments",Main.currentProject.segments)
		params.Put("lastEntry",Main.currentProject.lastEntry)
		params.Put("projectFile",Main.currentProject.projectFile)
		params.Put("path",Main.currentProject.path)
		params.Put("filename",currentFilename)
		wait for (Main.currentProject.runFilterPluginAccordingToExtension(currentFilename,"previewText",params)) Complete (result As String)
		text=result
	End If
	'Log("preview"&text)
	loadHtml(text)
End Sub

Sub loadHtml(text As String)
	text=Regex.Replace("\r",text,"")
	text=Regex.Replace("\n",text,"<br/>")
	fontsize=getFontSize
	Dim htmlhead,htmlend As String
	htmlhead=$"<!DOCTYPE HTML>
	<html>
	<head>
	<meta charset="utf-8"/>
	<style type="text/css">
	#current {color:green;}
	#content {font-size:${fontsize}px;}
	</style>
	<script language="javascript" type="text/javascript"> 
         function zoomin(){
            var s=document.getElementById("content").style.fontSize;
            if (s==""){
                s=16;
            }
            var size=parseInt(s)+1;
            console.log(size);
           document.getElementById("content").style.fontSize=size+"px";
         }
         function zoomout(){
            var s=document.getElementById("content").style.fontSize;
            if (s==""){
                s=16;
            }
            var size=parseInt(s)-1;
            console.log(size);
           document.getElementById("content").style.fontSize=size+"px";
         }
    </script>
 </head><body>
 <a href="javascript:void(0);" onclick="zoomin()">zoom in</a>/
 <a href="javascript:void(0);" onclick="zoomout()">zoom out</a>
 <p id="content">
	"$
	
	htmlend=$"</p></body>
		<script language="javascript" type="text/javascript"> 
         window.location.hash = "#current";
    </script>
	</html>"$
	text=htmlhead&text&htmlend

	WebView1.LoadHtml(text)
	
	'Log(text)
End Sub

Sub getFontSize As Int
	Dim currentSize As Int=16
	Dim we As JavaObject
	we = asJO(WebView1).RunMethod("getEngine",Null)
	Dim jscode As String
	jscode=$"document.getElementById("content").style.fontSize;"$
	Try
		Dim sizeString As String=we.RunMethod("executeScript",Array As String(jscode))
		currentSize=sizeString.Replace("px","")
		Log(currentSize&"currentsize")
	Catch
		Log("get")
		Log(LastException)
		currentSize=16
	End Try
	Return currentSize
End Sub

Sub setFontSize(size As Int)
	Dim we As JavaObject
	we = asJO(WebView1).RunMethod("getEngine",Null)
	Dim jscode As String
	Dim sizeString As String=size
	jscode=$"document.getElementById("content").style.fontSize="${sizeString}px";"$
	Log(jscode)
	Try
		we.RunMethod("executeScript",Array As String(jscode))
	Catch
		Log("set")
		Log(LastException)
	End Try
	
End Sub

Sub asJO(o As JavaObject) As JavaObject
	Return o
End Sub

Sub WebView1_PageFinished (Url As String)
	setFontSize(fontsize)
End Sub