B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Public sh As Shell
End Sub

Sub runCorenlpServer(sourcelang As String)

	If sh.IsInitialized=False Then
		sh.Initialize("sh","java",Array As String("-mx4g","-cp",$"*"$,"edu.stanford.nlp.pipeline.StanfordCoreNLPServer","-port","9000","-timeout","15000"))
	End If
	Log(Main.preferencesMap.Get("corenlp_path"))
	sh.WorkingDirectory=Main.preferencesMap.Get("corenlp_path")
	sh.RunWithOutputEvents(-1)
End Sub

Sub getAllSegmentTranslation(text As String,engine As String) As ResumableSub
	Dim sourceLang,targetLang As String
	sourceLang=Main.currentProject.projectFile.Get("source")
	targetLang=Main.currentProject.projectFile.Get("target")
	
	
	
	Dim translationList As List
	translationList.Initialize
	
	If Main.preferencesMap.ContainsKey("corenlp_path") Then
		If File.Exists(Main.preferencesMap.Get("corenlp_path"),"")=False Then
			Return translationList
		Else
			runCorenlpServer(sourceLang)
		End If
	Else
		Return translationList
	End If
	
	Dim address As String=""
	If Main.preferencesMap.ContainsKey("corenlp_address") Then
		address=Main.preferencesMap.Get("corenlp_address")
		
	End If

	Dim wordList As List
	wordList.Initialize
	
	Dim pattern As String
	If sourceLang="zh" Then
		pattern=""
		wait for (getStanfordTokenizedResult(text,address,sourceLang)) Complete (resultList As List)
		wordList.AddAll(resultList)
		Log(resultList)
	Else
		pattern=" "
	End If
	
	wordList.AddAll(Regex.Split(pattern,text))

	For Each word As String In wordList
		wait for (MT.getMT(word,sourceLang,targetLang,engine)) Complete (result As String)
		translationList.Add(result)
	Next
	
	If address<>"" Then
		Dim grams As List
		grams.Initialize
		wait for (getStanfordParsedResult(text,address,sourceLang)) Complete (result As String)
		grams.AddAll(getGramsFromStringViaRe(result))
		duplicatedRemovedList2(grams,wordList)
		Log("grams"&grams)
		For Each gram As String In grams
			wait for (MT.getMT(gram,sourceLang,targetLang,engine)) Complete (result As String)
			translationList.Add(result)
		Next
	End If

	
	Return duplicatedRemovedList(translationList)
End Sub

Sub getStanfordTokenizedResult(sentence As String, address As String,lang As String) As ResumableSub
	Dim tokens As List
	tokens.Initialize
	Dim params As String
	Dim su As StringUtils
	params=su.EncodeUrl($"{"annotators":"tokenize","outputFormat":"json","pipelineLanguage":"${lang}"}"$,"UTF-8")
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.PostString("http://"&address&"/?properties="&params,sentence)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim map1 As Map
		map1=json.NextObject
		Dim list1 As List
		list1=map1.Get("tokens")
		For Each token As Map In list1
			tokens.Add(token.Get("word"))
		Next
	End If
	job.Release
	Return tokens
End Sub

Sub getStanfordParsedResult(sentence As String,address As String,lang As String) As ResumableSub
	Dim parse As String
	Dim params As String
	Dim su As StringUtils
	params=su.EncodeUrl($"{"annotators":"parse","outputFormat":"json","pipelineLanguage":"${lang}}"$,"UTF-8")
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.PostString("http://"&address&"/?properties="&params,sentence)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Dim json As JSONParser
		json.Initialize(job.GetString)
		Dim map1 As Map
		map1=json.NextObject
		Dim list1 As List
		list1=map1.Get("sentences")
		Dim map2 As Map
		map2=list1.Get(0)
		parse=map2.Get("parse")
		Log(parse)
	End If
	job.Release
	Return parse
End Sub

Sub getGramsFromStringViaRe2(text As String) As List
	Dim gramsList As List
	gramsList.Initialize
	For Each item As String In Array As String("N","V","P")
		
		text=Regex.Replace("\r\n",text,"")
		text=Regex.Replace(" {1,}",text," ")
		Dim matcher As Matcher
		'\(NP .*?\){2,}
		'\(.*?
		'\)
		matcher=Regex.Matcher("\("&item&"P .*?\){2,}",text)
		Do While matcher.Find
			gramsList.Add(Regex.Replace("\(.*? |\)",matcher.Match,""))
			'ListView1.Items.Add(matcher.Match)
			Log(matcher.Match)
		Loop
	Next
		
	Return gramsList
End Sub


Sub getGramsFromStringViaRe(text As String) As List
	Dim gramsList As List
	gramsList.Initialize
	text=Regex.Replace("\r\n",text,"")
	text=Regex.Replace(" {1,}",text," ")
	For Each item As String In Array As String("NP","VP","PP")
		Dim matcher As Matcher
		'\(NP .*?\){2,}
		'\(.*?
		'\)
		matcher=Regex.Matcher("\("&item&" .*?\){2,}",text)
		Do While matcher.Find
			gramsList.Add(Regex.Replace("\(.*? |\)",matcher.Match,""))
			Log(matcher.Match)
		Loop
	Next

	gramsList=getLongGrams(text,gramsList,"VP")

	Return gramsList
End Sub

Sub getLongGrams(text As String,gramsList As List,item As String) As List
	Dim matcher As Matcher

	matcher=Regex.Matcher("\("&item&" .*\){2,}",text)
		
	Do While matcher.Find
		Log(matcher.Match)
		gramsList.Add(Regex.Replace("\(.*? |\)",matcher.Match,""))
		
		Dim matcher2 As Matcher
		matcher2=Regex.Matcher("\("&item&" .*?\){2,}",matcher.Match)
		Do While matcher2.Find

			'all.Add(matcher2.Match)
			gramsList.Add(Regex.Replace("\(.*? |\)",matcher2.Match,""))
			getLongGrams(matcher.Match.Replace(matcher2.Match,""),gramsList,item)
		Loop
		
	Loop
	Return duplicatedRemovedList(gramsList)
End Sub

Sub duplicatedRemovedList(list1 As List) As List
	Dim newList As List
	newList.Initialize
	For Each item As String In list1 
		Dim matcher As Matcher
		matcher=Regex.Matcher(",|，",item) ' remove grams with comma
		If newList.IndexOf(item)=-1 And matcher.Find=False Then
			newList.Add(item)
		End If
	Next
	Return newList
End Sub

Sub duplicatedRemovedList2(list1 As List,list2 As List) As List
	Dim newList As List
	newList.Initialize
	For Each item As String In list1 
		If newList.IndexOf(item)=-1 Or list2.IndexOf(item)=-1 Then
			newList.Add(item)
		End If
	Next
	Return newList
End Sub