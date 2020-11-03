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
	Return "colorfulcloudsMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("token")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("token":"3975l6lr5pcbvidl6jl2")
	End Select
	Return ""
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim direction As String=sourceLang&"2"&targetLang

	Dim textList As List
	textList.Initialize
	textList.Add(source)
	Dim map1 As Map
	map1.Initialize
	map1.Put("source",textList)
	map1.Put("trans_type",direction)
	map1.Put("detect",True)
	map1.Put("request_id","demo")
	
	Dim jsonG As JSONGenerator
	jsonG.Initialize(map1)
	
	Log(jsonG.ToString)
	Dim token As String="3975l6lr5pcbvidl6jl2"
	Try
		token=getMap("colorfulclouds",getMap("mt",preferencesMap)).GetDefault("token",token)
	Catch
		Log(LastException)
	End Try

	Dim URL As String="http://api.interpreter.caiyunai.com/v1/translator"
	job.PostString(URL,jsonG.ToString)
	job.GetRequest.SetHeader("x-authorization","token "&token)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim targetList As List=json.NextObject.Get("target")
			target=targetList.Get(0)
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
