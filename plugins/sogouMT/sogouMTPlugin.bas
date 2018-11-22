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
	Return "sogouMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("appKey")
			paramsList.Add("secretKey")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim appKey,secretKey As String
	appKey=getMap("sogou",getMap("mt",preferencesMap)).Get("appKey")
	secretKey=getMap("sogou",getMap("mt",preferencesMap)).Get("secretKey")
	Dim su As StringUtils

	If sourceLang="zh" Then
		sourceLang="zh-CHS"
	End If
	If targetLang="zh" Then
		targetLang="zh-CHS"
	End If
	source=su.EncodeUrl(source,"UTF-8")
	Dim params As String
	params="from="&sourceLang&"&q="&source&"&to="&targetLang

	Dim timestamp As Int = DateTime.Now/1000
	Dim prefix As String="sac-auth-v1/"&appKey&"/"&timestamp&"/3600"

	Dim sign As String=getSignature(prefix,secretKey,params)
	

	params="from="&sourceLang&"&q="&source&"&to="&targetLang
	
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("http://api.ai.sogou.com/pub/nlp/translate?"&params)
	job.GetRequest.SetHeader("Authorization",prefix&"/"&sign)

	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim resultList As List
			resultList=json.NextObject.Get("trans_result")
			Dim result As Map
			result=resultList.Get(0)
			target=result.Get("trans_text")
		Catch
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub getSignature(prefix As String,secretKey As String,params As String) As String
	
	Dim mactool As Mac
	Dim k As KeyGenerator
	k.Initialize("HmacSHA256")
	Dim combined As String=prefix&"\nGET\napi.ai.sogou.com\n/pub/nlp/translate\n"&params
	combined=combined.Replace("\n",CRLF)
	Log(combined)
	k.KeyFromBytes(secretKey.GetBytes("UTF-8"))
	mactool.Initialise("HmacSHA256",k.Key)
	mactool.Update(combined.GetBytes("UTF-8"))
	Dim bb() As Byte
	bb=mactool.Sign
	Dim base As Base64
	Dim sign As String=base.EncodeBtoS(bb,0,bb.Length)
    Log("sign"&sign)
	Return sign
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub