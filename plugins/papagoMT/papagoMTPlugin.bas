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
	Return "papagoMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("Client ID")
			paramsList.Add("Client Secret")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
	End Select
	Return ""
End Sub

Sub ConvertLangCode(lang As String) As String
	If lang="zh" Then
		lang="zh-CN"
	End If
	Return lang
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	sourceLang=ConvertLangCode(sourceLang)
	targetLang=ConvertLangCode(targetLang)
	Dim target As String
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="text="&su.EncodeUrl(source,"UTF-8")&"&source="&sourceLang&"&target="&targetLang
	
	Dim clientid,clientsecret As String
	clientid=getMap("papago",getMap("mt",preferencesMap)).Get("Client ID")
	clientsecret=getMap("papago",getMap("mt",preferencesMap)).Get("Client Secret")
	
	Dim URL As String="https://openapi.naver.com/v1/papago/n2mt"
	job.PostString(URL,params)
	job.GetRequest.SetHeader("X-Naver-Client-Id",clientid)
	job.GetRequest.SetHeader("X-Naver-Client-Secret",clientsecret)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim message As Map=json.NextObject.Get("message")
			Dim result As Map=message.Get("result")
			target=result.Get("translatedText")
		Catch
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
