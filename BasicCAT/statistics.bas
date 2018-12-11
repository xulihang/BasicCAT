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
	Private totalSourceWords,totalTargetWords,totalSourceSentences,totalTargetSentences As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,200)
	frm.RootPane.LoadLayout("statistics")
End Sub

Public Sub Show
	frm.Show
	buildTable
End Sub

Sub fillData(filename As String) As String
	Dim sourceWords,targetWords,sourceSentences,targetSentences As Int
	Dim segments As List
	segments=Main.currentProject.getAllSegments(filename)
	For Each bitext As List In segments
		sourceWords=sourceWords+calculateWords(bitext.Get(0),Main.currentProject.projectFile.Get("source"))
		targetWords=targetWords+calculateWords(bitext.Get(1),Main.currentProject.projectFile.Get("target"))
		sourceSentences=sourceSentences+1
		If bitext.Get(1)<>"" Then
			targetSentences=targetSentences+1
		End If
	Next
	
	totalSourceWords=totalSourceWords+sourceWords
	totalTargetWords=totalTargetWords+targetWords
	totalSourceSentences=totalSourceSentences+sourceSentences
	totalTargetSentences=totalTargetSentences+targetSentences
	
	Dim percent As String
	percent=targetSentences/sourceSentences*100
	percent=percent.SubString2(0,Min(4,percent.Length))&"%"
	
	Dim one As String
	one=$"<tr>
	<td>${filename}</td>
	<td>${sourceWords}</td>
	<td>${targetWords}</td>
	<td>${sourceSentences}</td>
	<td>${targetSentences}</td>
	<td>${percent}</td>
	</tr>"$
	
	Return one
End Sub

Sub fillTotalData As String
	Dim percent As String
	percent=totalTargetSentences/totalSourceSentences*100
	percent=percent.SubString2(0,Min(4,percent.Length))&"%"
	
	Dim one As String
	one=$"<tr>
	<td>Total</td>
	<td>${totalSourceWords}</td>
	<td>${totalTargetWords}</td>
	<td>${totalSourceSentences}</td>
	<td>${totalTargetSentences}</td>
	<td>${percent}</td>
	</tr>"$
	
	Return one
End Sub

Sub buildTable
	Dim result As String
	Dim htmlhead As String
	htmlhead=$"<!DOCTYPE HTML>
	<html>
	<head>
	<meta charset="utf-8"/>
	<style type="text/css">
	p {font-size: 18px}
	table {width: 100%}
	</style>
	</head><body>
	<table border="1" cellpadding="0" cellspacing="1">
	<tr>
	<th rowspan="2">Filename</th>
	<th colspan="2">Words</th>
	<th colspan="2">Sentences</th>
	<th rowspan="2">Progress</th>

	</tr>
	<tr>
	<th>Source</th><th>Target</th>
	<th>Source</th><th>Target</th>

	</tr>"$
	result=result&htmlhead
	Dim htmlend As String
	htmlend="</table></body></html>"

	For Each filename As String In Main.currentProject.files
		result=result&fillData(filename)
	Next
	result=result&fillTotalData
	result=result&htmlend
	WebView1.LoadHtml(result)
End Sub

Sub calculateWords(text As String,lang As String) As Int
	If Utils.LanguageHasSpace(lang) Then
		Return calculateWordsForLanguageWithSpace(text)
	Else
		Return calculateHanzi(text)
	End If
End Sub

Sub calculateWordsForLanguageWithSpace(text As String) As Int
	Return Regex.Split(" ",text).Length
End Sub

Sub calculateHanzi(text As String) As Int
	Return text.Length
End Sub

