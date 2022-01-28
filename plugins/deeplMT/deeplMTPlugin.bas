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
	Return "deeplMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("freemode (yes or no)")
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
			Return CreateMap("freemode (yes or no)":"yes")
	End Select
	Return ""
End Sub


Sub ConvertLang(lang As String) As String
	Return lang.ToUpperCase
End Sub

Sub batchTranslate(sourceList As List,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim sb As StringBuilder
	sb.Initialize
	For Each source As String In sourceList
		sb.Append(source.Replace(CRLF,"<br/>"))
		sb.Append(CRLF)
	Next
	wait for (translate(sb.ToString,sourceLang,targetLang,preferencesMap)) Complete (target As String)
	Dim targetList As List
	targetList.Initialize
	For Each result As String In Regex.Split(CRLF,target)
		result = result.Replace("<br/>",CRLF)
		targetList.Add(result)
	Next
	Return targetList
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	sourceLang=ConvertLang(sourceLang)
	targetLang=ConvertLang(targetLang)
	
	Dim target As String
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	Dim freemode As String
	freemode=getMap("deepl",getMap("mt",preferencesMap)).GetDefault("freemode","yes")
	Dim key As String
	key=getMap("deepl",getMap("mt",preferencesMap)).GetDefault("key","")
	If key="" Then
		Return ""
	End If
	
	Dim url As String
	If freemode="yes" Then
		url="https://api-free.deepl.com/v2/translate"
	Else
		url="https://api.deepl.com/v2/translate "
	End If
	
	params="?auth_key="&key& _
	"&text="&su.EncodeUrl(source,"UTF-8")&"&source_lang="&sourceLang&"&target_lang="&targetLang
	job.Download(url&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim translations As List = json.NextObject.Get("translations")
			Dim trans As Map = translations.Get(0)
			target = trans.Get("text")
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


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
