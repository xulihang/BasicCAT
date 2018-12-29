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
	Return "watsonMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("apiKey")
			paramsList.Add("url")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim apiKey,url As String
	apiKey=getMap("watson",getMap("mt",preferencesMap)).Get("apiKey")
	url=getMap("watson",getMap("mt",preferencesMap)).Get("url")
	Dim params As Map
	params.Initialize
	params.Put("text",source)
	params.Put("model_id",sourceLang&"-"&targetLang)
	Dim JSONGenerator As JSONGenerator
	JSONGenerator.Initialize(params)
	
	
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Username="apikey"
	job.Password=apiKey
	job.PostString(url&"/v3/translate?version=2018-05-01",JSONGenerator.ToString)
	job.GetRequest.SetContentType("application/json")
	

	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim translations As List
			translations=json.NextObject.Get("translations")
			Dim result As Map
			result=translations.Get(0)
			target=result.Get("translation")
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