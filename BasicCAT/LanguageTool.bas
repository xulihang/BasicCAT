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


Sub check(text As String,entry As Int,langcode As String) As ResumableSub
	Dim values As List
	values.Initialize
    
	Dim address As String
	If Main.preferencesMap.ContainsKey("languagetool_address") Then

		address=Main.preferencesMap.Get("languagetool_address")
	Else
		Return values
	End If
	

	Select langcode
		Case "en"
			langcode="en-US"
	End Select
	Dim su As StringUtils
	Dim params As String
	params="?language="&langcode&"&text="&su.EncodeUrl(text,"UTF-8")
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("http://"&address&"/v2/check"&params)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Log("languagetool"&job.GetString)
		values=showResult(job.GetString,entry,text)
	End If
	job.Release
	Return values
End Sub

Sub showResult(jsonstring As String,entry As Int,text As String) As List
	Dim values As List
	values.Initialize
	Dim json As JSONParser
	json.Initialize(jsonstring)
	Dim result As Map
	result=json.NextObject
	Dim matches As List
	matches=result.Get("matches")
	If matches.Size=0 Then
		Main.noErrors
		Return values
	Else
		Dim match As Map=matches.Get(0)
		Log("match"&match)
		'match.Get("shortMessage")
		'Dim context As Map
		Dim message As String
		message=match.Get("message")
		'context=match.Get("context")
		Dim replacements As List
		replacements=match.Get("replacements")
		Dim offset,length As Int
		offset=match.Get("offset")
		length=match.Get("length")
		values.Add(offset)
		values.Add(length)
		values.Add(replacements)
		values.Add(entry)
		Main.addCheckList(replacements,message,offset,length,text,entry)
	End If
	Return values
End Sub

