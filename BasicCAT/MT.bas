B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private Bconv As ByteConverter
End Sub


Sub getMT(source As String,sourceLang As String,targetLang As String,MTEngine As String) As ResumableSub
	If MTEngine="baidu" Then
		wait for (BaiduMT(source,sourceLang,targetLang)) Complete (result As String)
		Return result
	End If
End Sub

Sub BaiduMT(source As String,sourceLang As String,targetLang As String) As ResumableSub

	
	sourceLang=sourceLang.ToLowerCase
	targetLang=targetLang.ToLowerCase
	Dim salt As Int
	salt=Rnd(1,1000)
	Dim appid,sign,key As String
	appid=Utils.getMap("baidu",Utils.getMap("mt",Main.preferencesMap)).Get("appid")
	key=Utils.getMap("baidu",Utils.getMap("mt",Main.preferencesMap)).Get("key")
	sign=appid&source&salt&key
	Dim md As MessageDigest
	sign=Bconv.HexFromBytes(md.GetMessageDigest(Bconv.StringToBytes(sign,"UTF-8"),"MD5"))
	sign=sign.ToLowerCase
	
	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	Dim param As String
	param="?appid="&appid&"&q="&source&"&from="&sourceLang&"&to="&targetLang&"&salt="&salt&"&sign="&sign
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("http://api.fanyi.baidu.com/api/trans/vip/translate"&param)
	wait for (job) JobDone(job As HttpJob)
	Dim target As String
	If job.Success Then
		Log(job.GetString)
		If job.GetString.Contains("error") Then
			target=""
		Else
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As List
			result=json.NextObject.Get("trans_result")
			Dim resultMap As Map
			resultMap=result.Get(0)
			target=resultMap.Get("dst")
		End If
	Else
		target=""
	End If
	job.Release
    Return target
End Sub