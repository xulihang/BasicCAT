B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private Bconv As ByteConverter
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "sogouDeepIMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("pid")
			paramsList.Add("key")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim pid,key As String
	pid=getMap("sogouDeepI",getMap("mt",preferencesMap)).Get("pid")
    key=getMap("sogouDeepI",getMap("mt",preferencesMap)).Get("key")
	Dim su As StringUtils

	If sourceLang="zh" Then
		sourceLang="zh-CHS"
	End If
	If targetLang="zh" Then
		targetLang="zh-CHS"
	End If
	
	Dim params As String

	Dim salt As String
	salt=Rnd(1,1000)
	Dim sign As String
	sign=pid.Trim&source.Trim&salt.trim&key.Trim
	Dim md As MessageDigest
	sign=Bconv.HexFromBytes(md.GetMessageDigest(Bconv.StringToBytes(sign,"UTF-8"),"MD5"))
	sign=sign.ToLowerCase
	
	source=su.EncodeUrl(source,"UTF-8")
	
	params="from="&sourceLang&"&q="&source&"&to="&targetLang&"&pid="&pid&"&salt="&salt&"&sign="&sign
	
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.PostString("http://fanyi.sogou.com/reventondc/api/sogouTranslate",params)
	job.GetRequest.SetContentType("application/x-www-form-urlencoded")
	job.GetRequest.SetHeader("Accept","application/json")

	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			target=json.NextObject.Get("translation")
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