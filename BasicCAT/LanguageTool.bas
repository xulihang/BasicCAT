B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub


Sub check(text As String,langcode As String) As ResumableSub
	Dim matches As List
	matches.Initialize
	Dim address As String
	If Main.preferencesMap.ContainsKey("languagetool_address") Then
		address=Main.preferencesMap.Get("languagetool_address")
	Else
		Return matches
	End If
	
    If langcode="en" Then 
		langcode="en-US"
	else if langcode.StartsWith("zh") Then
		langcode="zh"
	Else
		langcode="auto" 'use auto detection
    End If
	
	Dim su As StringUtils
	Dim params As String
	params="?language="&langcode&"&text="&su.EncodeUrl(text,"UTF-8")
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download(address&params)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log("languagetool"&job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As Map
			result=json.NextObject
			matches=result.Get("matches")
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return matches
End Sub


