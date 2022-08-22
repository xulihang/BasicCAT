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
		Case "batchtranslate"
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("token":"3975l6lr5pcbvidl6jl2")
	End Select
	Return ""
End Sub


Private Sub convertLang(lang As String) As String
	If lang.StartsWith("zh") Then
		Return "zh"
	End If
	Return lang
End Sub

Sub batchTranslate(sourceList As List, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	sourceLang = convertLang(sourceLang)
	targetLang = convertLang(targetLang)
	Dim direction As String=sourceLang&"2"&targetLang
	Dim map1 As Map
	map1.Initialize
	map1.Put("source",sourceList)
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
			targetList=json.NextObject.Get("target")
			Return targetList
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return targetList
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	wait for (batchTranslate(Array As String(source),sourceLang,targetLang,preferencesMap)) Complete (targetList As List)
	If targetList.Size>0 Then
		Return targetList.Get(0)
	Else
		Return ""
	End If
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
