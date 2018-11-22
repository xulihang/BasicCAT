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
	Return "tencentMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("secretId")
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
	Dim id,key As String
	id=getMap("tencent",getMap("mt",preferencesMap)).Get("secretId")
	key=getMap("tencent",getMap("mt",preferencesMap)).Get("secretKey")

	Dim su As StringUtils

	Dim params As String
	Dim nounce As Int
	Dim timestamp As Int=DateTime.Now/1000
	nounce=Rnd(1000,2000)
	params="Action=TextTranslate&Nonce="&nounce&"&ProjectId=0&Region=ap-shanghai&SecretId="&id&"&Source="&sourceLang&"&SourceText="&source&"&Target="&targetLang&"&Timestamp="&timestamp&"&Version=2018-03-21"
	'add signature
	source=su.EncodeUrl(source,"UTF-8")
	params="Action=TextTranslate&Nonce="&nounce&"&ProjectId=0&Region=ap-shanghai&SecretId="&id&"&Signature="&getSignature(key,params)&"&Source="&sourceLang&"&SourceText="&source&"&Target="&targetLang&"&Timestamp="&timestamp&"&Version=2018-03-21"
	'Log(params)
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("https://tmt.ap-shanghai.tencentcloudapi.com/?"&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim Response As Map
			Response=json.NextObject.Get("Response")
			target=Response.Get("TargetText")
		Catch
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub getSignature(key As String,params As String) As String
	Dim mactool As Mac
	Dim k As KeyGenerator
	k.Initialize("HMACSHA1")
	Dim su As StringUtils
	Dim combined As String="GETtmt.ap-shanghai.tencentcloudapi.com/?"&params
	k.KeyFromBytes(Bconv.StringToBytes(key,"UTF-8"))
	mactool.Initialise("HMACSHA1",k.Key)
	mactool.Update(combined.GetBytes("UTF-8"))
	Dim bb() As Byte
	bb=mactool.Sign
	Dim base As Base64
	Dim sign As String=base.EncodeBtoS(bb,0,bb.Length)
	sign=su.EncodeUrl(sign,"UTF-8")
	Return sign
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
