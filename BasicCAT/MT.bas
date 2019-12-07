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
	Private mtResultStore As Map
End Sub

Sub getMTList As List
	Dim mtList As List
	mtList.Initialize
	mtList.AddAll(Array As String("baidu","yandex","youdao","google","microsoft","mymemory","ali","ali-ecommerce"))
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
	If Main.preferencesMap.ContainsKey("mt_excludetags") Then
		If Main.preferencesMap.Get("mt_excludetags")=True Then
			source=Regex.Replace("<.*?>",source,"")
		End If
	End If
	sourceLang=convertLangCode(sourceLang,MTEngine)
	targetLang=convertLangCode(targetLang,MTEngine)
	Dim result As String
	
	If mtResultStore.IsInitialized=True Then
		Dim key As String=getMTResultKey(source,MTEngine,sourceLang,targetLang)
		If mtResultStore.ContainsKey(key) Then
			Return mtResultStore.Get(key)
		End If
	End If
	
	Select MTEngine
		Case "baidu"
			wait for (BaiduMT(source,sourceLang,targetLang)) Complete (result As String)
		Case "yandex"
			wait for (yandexMT(source,sourceLang,targetLang)) Complete (result As String)
		Case "youdao"
			wait for (youdaoMT(source,sourceLang,targetLang,False)) Complete (result As String)
		Case "google"
			wait for (googleMT(source,sourceLang,targetLang)) Complete (result As String)
		Case "microsoft"
			wait for (microsoftMT(source,sourceLang,targetLang)) Complete (result As String)
		Case "mymemory"
			wait for (MyMemory(source,sourceLang,targetLang)) Complete (result As String)
		Case "ali"
			wait for (AliMT(source,sourceLang,targetLang,False)) Complete (result As String)
		Case "ali-ecommerce"
			wait for (AliMT(source,sourceLang,targetLang,True)) Complete (result As String)
	End Select
	If result="" And getMTPluginList.IndexOf(MTEngine)<>-1 Then
		Dim params As Map
		params.Initialize
		params.Put("source",source)
		params.Put("sourceLang",sourceLang)
		params.Put("targetLang",targetLang)
		params.Put("preferencesMap",Main.preferencesMap)
		wait for (Main.plugin.RunPlugin(MTEngine&"MT","translate",params)) complete (result As String)
		Log("pluginMT"&result)
	End If
	If result<>"" Then
		storeMTResult(source,result,MTEngine,sourceLang,targetLang)
	End If
	Return result
End Sub

Sub storeMTResult(source As String,target As String,engine As String,sourceLang As String,targetLang As String)
	If mtResultStore.IsInitialized=False Then
		mtResultStore.Initialize
	End If
	mtResultStore.Put(getMTResultKey(source,engine,sourceLang,targetLang),target)
End Sub

Sub getMTResultKey(source As String,engine As String,sourceLang As String,targetLang As String) As String
	Dim map1 As Map
	map1.Initialize
	map1.Put("source",source)
	map1.Put("engine",engine)
	map1.Put("sourceLang",sourceLang)
	map1.Put("targetLang",targetLang)
	Dim json As JSONGenerator
	json.Initialize(map1)
	Return json.ToString
End Sub

Sub convertLangCode(lang As String,engine As String) As String
	If File.Exists(File.DirData("BasicCAT"),"langcodes.txt")=False Then
		File.Copy(File.DirAssets,"langcodes.txt",File.DirData("BasicCAT"),"langcodes.txt")
	End If
	Dim langcodes As Map
	langcodes=Utils.readLanguageCode(File.Combine(File.DirData("BasicCAT"),"langcodes.txt"))
	Dim codeMap As Map
	If langcodes.ContainsKey(lang)=False Then
		Return lang
	End If
	codeMap=langcodes.Get(lang)
	If codeMap.ContainsKey(engine) Then
		lang=codeMap.Get(engine)
	End If
	Return lang
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
	job.Download("https://api.fanyi.baidu.com/api/trans/vip/translate"&param)
	wait for (job) JobDone(job As HttpJob)
	Dim target As String=""
	If job.Success Then
		'Log(job.GetString)
	    Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As List
			result=json.NextObject.Get("trans_result")
			Dim resultMap As Map
			resultMap=result.Get(0)
			target=resultMap.Get("dst")
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return target
End Sub

Sub yandexMT(source As String,sourceLang As String,targetLang As String) As ResumableSub
	Dim target As String=""
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="?key="&Utils.getMap("yandex",Utils.getMap("mt",Main.preferencesMap)).Get("key")&"&text="&su.EncodeUrl(source,"UTF-8")&"&lang="&sourceLang&"-"&targetLang
	job.Download("https://translate.yandex.net/api/v1.5/tr.json/translate"&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim map1 As Map
			map1=json.NextObject
			If map1.Get("code")=200 Then
				Dim result As List
				result=map1.Get("text")
				target=result.Get(0)
			End If
		Catch
			Log(LastException)
		End Try
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
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Ocp-Apim-Subscription-Key",key)
	job.GetRequest.SetHeader("X-ClientTraceId",UUID)
	job.GetRequest.SetHeader("Content-Type","application/json")
	job.GetRequest.SetHeader("Accept","application/json")
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
		Try
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
		Catch
			Log(LastException)
		End Try
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

Sub AliMT(source As String,sourceLang As String,targetLang As String,isEcommerce As Boolean) As ResumableSub
	Dim result As String
	Try
		Dim accessKeyID,accessKeySecret,scene As String
		accessKeyID=Utils.getMap("ali",Utils.getMap("mt",Main.preferencesMap)).Get("accesskeyId")
		accessKeySecret=Utils.getMap("ali",Utils.getMap("mt",Main.preferencesMap)).Get("accesskeySecret")
		scene=Utils.getMap("ali-ecommerce",Utils.getMap("mt",Main.preferencesMap)).Get("scene")
		Dim profile As JavaObject
		profile.InitializeStatic("com.aliyuncs.profile.DefaultProfile")
		profile=profile.RunMethodJO("getProfile",Array("cn-hangzhou",accessKeyID,accessKeySecret))
		Dim client As JavaObject
		client.InitializeNewInstance("com.aliyuncs.DefaultAcsClient",Array(profile))
		Dim methodType As JavaObject
		methodType.InitializeStatic("com.aliyuncs.http.MethodType")
		Dim request As JavaObject
		If isEcommerce Then
			request.InitializeNewInstance("com.aliyuncs.alimt.model.v20181012.TranslateECommerceRequest",Null)
			request.RunMethod("setScene",Array(scene))
		Else
			request.InitializeNewInstance("com.aliyuncs.alimt.model.v20181012.TranslateGeneralRequest",Null)
		End If
		request.RunMethod("setMethod",Array(methodType.GetField("POST")))
		request.RunMethod("setFormatType",Array("text"))
		request.RunMethod("setSourceLanguage",Array(sourceLang))
		request.RunMethod("setTargetLanguage",Array(targetLang))
		request.RunMethod("setSourceText",Array(source))
		Dim response As JavaObject=client.RunMethodJO("getAcsResponse",Array(request))
		Dim data As JavaObject=response.RunMethodJO("getData",Null)
		result=data.RunMethod("getTranslated",Null)
		Return result
	Catch
		Log(LastException)
		Return ""
	End Try
End Sub

Sub UUID As String
	Dim jo As JavaObject
	Return jo.InitializeStatic("java.util.UUID").RunMethod("randomUUID", Null)
End Sub

