B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "cloudtranslationMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("placeholder - put any character")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"))) complete (result As String)
			Return result
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String) As ResumableSub
	Dim target As String
	Dim params As String
	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	params="lang="&sourceLang&"_"&targetLang&"&src="&source
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("http://sz-nmt-1.cloudtrans.org:2201/nmt?"&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		target=job.GetString
	Else
		target=""
	End If
	job.Release
	Return target
End Sub