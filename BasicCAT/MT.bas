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

Sub getMTList As List
	Dim mtList As List
	mtList.Initialize
	mtList.AddAll(Array As String("baidu","yandex","youdao","google","microsoft","mymemory"))
    mtList.AddAll(getMTPluginList)
	Return mtList
End Sub

Sub getMTPluginList As List
	Dim mtList As List
	mtList.Initialize
	For Each name As String In Main.plugin.GetAvailablePlugins
		If name.EndsWith("MT") Then
			mtList.Add(name.Replace("MT",""))
		End If
	Next
	Return mtList
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
		Case "google"
			wait for (googleMT(source,sourceLang,targetLang)) Complete (result As String)
			Return result
		Case "microsoft"
			wait for (microsoftMT(source,sourceLang,targetLang)) Complete (result As String)
			Return result
		Case "mymemory"
			wait for (MyMemory(source,sourceLang,targetLang)) Complete (result As String)
			Return result
	End Select
	If getMTPluginList.IndexOf(MTEngine)<>-1 Then
		Dim params As Map
		params.Initialize
		params.Put("source",source)
		params.Put("sourceLang",sourceLang)
		params.Put("targetLang",targetLang)
		params.Put("preferencesMap",Main.preferencesMap)
		wait for (Main.plugin.RunPlugin(MTEngine&"MT","translate",params)) complete (result As String)
		Log("pluginMT"&result)
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

Sub microsoftMT(source As String,sourceLang As String,targetLang As String) As ResumableSub
	Dim target,key As String
	key=Utils.getMap("microsoft",Utils.getMap("mt",Main.preferencesMap)).Get("key")
	Dim sourceList As List
	sourceList.Initialize
	sourceList.Add(CreateMap("Text":source))
	Dim jsong As JSONGenerator
	jsong.Initialize2(sourceList)
	source=jsong.ToString
	
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="&from="&sourceLang&"&to="&targetLang
	
	job.PostString("https://api.cognitive.microsofttranslator.com/translate?api-version=3.0"&params,source)
	
	job.GetRequest.SetHeader("Ocp-Apim-Subscription-Key",key)
	job.GetRequest.SetHeader("X-ClientTraceId",UUID)
	job.GetRequest.SetHeader("Content-Type","application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As List
			result=json.NextArray
			Dim innerMap As Map
			innerMap=result.Get(0)
			Dim translations As List
			translations=innerMap.Get("translations")
			Dim map1 As Map
			map1=translations.Get(0)
			target=map1.Get("text")
		Catch
			target=""
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub googleMT(source As String,sourceLang As String,targetLang As String) As ResumableSub
	Dim target As String
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="?key="&Utils.getMap("google",Utils.getMap("mt",Main.preferencesMap)).Get("key")& _ 
	"&q="&su.EncodeUrl(source,"UTF-8")&"&format=text&source="&sourceLang&"&target="&targetLang
	
	job.Download("https://translation.googleapis.com/language/translate/v2"&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result,data As Map
			Dim json As JSONParser
			json.Initialize(job.GetString)
			result=json.NextObject
			data=result.Get("data")
			Dim translations As List
			translations=data.Get("translations")
			Dim map1 As Map
			map1=translations.Get(0)
			target=map1.Get("translatedText")
		Catch
			target=""
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub youdaoMT(source As String,sourceLang As String,targetLang As String,lookup As Boolean) As ResumableSub
	If lookup=True Then
		source=source.Trim
	End If
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
	job.Download("https://openapi.youdao.com/api"&param)
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
			If lookup=True And result.ContainsKey("basic") Then
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

Sub MyMemory(source As String,sourceLang As String,targetLang As String) As ResumableSub

	Dim email As String
	email=Utils.getMap("mymemory",Utils.getMap("mt",Main.preferencesMap)).Get("email")
	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim langpair As String
	langpair=sourceLang&"|"&targetLang
	langpair=su.EncodeUrl(langpair,"UTF-8")
	Dim param As String
	param="?q="&source&"&langpair="&langpair
	If email<>"" Then
		param=param&"&de="&email
	End If
	
	job.Download("https://api.mymemory.translated.net/get"&param)
	Dim translatedText As String=""
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map
			response=json.NextObject.Get("responseData")
			translatedText=response.Get("translatedText")
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return translatedText
End Sub

Sub UUID As String
	Dim jo As JavaObject
	Return jo.InitializeStatic("java.util.UUID").RunMethod("randomUUID", Null)
End Sub

