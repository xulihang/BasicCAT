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
	Select MTEngine
		Case "baidu"
			wait for (BaiduMT(source,sourceLang,targetLang)) Complete (result As String)
			Return result
		Case "yandex"
			wait for (yandexMT(source,sourceLang,targetLang)) Complete (result As String)
			Return result
		Case "youdao"
			wait for (youdaoMT(source,sourceLang,targetLang,False)) Complete (result As String)
			Return result
	End Select
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
		'Log(job.GetString)
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

Sub yandexMT(source As String,sourceLang As String,targetLang As String) As ResumableSub
	Dim target As String
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="?key="&Utils.getMap("yandex",Utils.getMap("mt",Main.preferencesMap)).Get("key")&"&text="&su.EncodeUrl(source,"UTF-8")&"&lang="&sourceLang&"-"&targetLang
	job.Download("https://translate.yandex.net/api/v1.5/tr.json/translate"&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim map1 As Map
		map1=json.NextObject
		If map1.Get("code")=200 Then
			Dim result As List
			result=map1.Get("text")
			target=result.Get(0)
		Else
			target=""
		End If
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub youdaoMT(source As String,sourceLang As String,targetLang As String,lookup As Boolean) As ResumableSub
	
	Dim salt As Int
	salt=Rnd(1,1000)
	Dim appid,sign,key As String
	appid=Utils.getMap("youdao",Utils.getMap("mt",Main.preferencesMap)).Get("appid")
	key=Utils.getMap("youdao",Utils.getMap("mt",Main.preferencesMap)).Get("key")
	sign=appid&source&salt&key
	Dim md As MessageDigest
	sign=Bconv.HexFromBytes(md.GetMessageDigest(Bconv.StringToBytes(sign,"UTF-8"),"MD5"))
	sign=sign.ToLowerCase
	
	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	Dim param As String
	param="?appKey="&appid&"&q="&source&"&from="&sourceLang&"&to="&targetLang&"&salt="&salt&"&sign="&sign
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download("http://openapi.youdao.com/api"&param)
	wait for (job) JobDone(job As HttpJob)
	Dim target As String=""
	Dim meansList As List
	meansList.Initialize
	If job.Success Then
		Log(job.GetString)
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim result As Map
		result=json.NextObject
		If result.Get("errorCode")="0" Then
			Dim translationList As List
			translationList=result.Get("translation")
			target=translationList.Get(0)
			If lookup=True Then
				Dim basic As Map
				basic=result.Get("basic")
				meansList.AddAll(basic.Get("explains"))
				meansList.Add(target)
			End If
		End If
	End If
	job.Release
	If lookup Then
		Return meansList
	Else
		Return target
	End If
End Sub