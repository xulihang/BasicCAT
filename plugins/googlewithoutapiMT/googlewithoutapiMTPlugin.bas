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
	Return "googlewithoutapiMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("use cn(yes or no)")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("use cn(yes or no)":"yes")
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim useCN As Boolean=True
	Try
		If getMap("googlewithoutapi",getMap("mt",preferencesMap)).GetDefault("use cn(yes or no)","yes")="yes" Then
			useCN=True
		Else
			useCN=False
		End If
	Catch
		Log(LastException)
	End Try
	Dim url As String
	If useCN Then
		url="https://translate.google.cn/translate_a/t?client=dict-chrome-ex"
	Else
		url="https://translate.google.com/translate_a/t?client=dict-chrome-ex"
	End If
	
	Dim params As String
	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	params="dt=t&dj=1&sl="&sourceLang&"&tl="&targetLang&"&q="&source
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download(url&"&"&params)
	job.GetRequest.SetHeader("Connection", "keep-alive")
	job.GetRequest.SetHeader("Cookie", "BL_D_PROV= BL_T_PROV=Google")
	job.GetRequest.SetHeader("Host", "translate.googleapis.com")
	job.GetRequest.SetHeader("Referer", "https://translate.google.com/")
	job.GetRequest.SetHeader("TE", "Trailers")
	job.GetRequest.SetHeader("Upgrade-Insecure-Requests", "1")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		'Log(job.GetString)
		target=job.GetString
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim sb As StringBuilder
		sb.Initialize
		Dim sentences As List=json.NextObject.Get("sentences")
		For Each sentence As Map In sentences
			sb.Append(sentence.GetDefault("trans","")).Append(CRLF)
		Next
		target=sb.ToString.Trim
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub