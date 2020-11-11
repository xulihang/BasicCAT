B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub languageIsSupported(lang As String) As Boolean
	Dim languagesList As List
	languagesList.Initialize
	languagesList.AddAll(Array As String("en","zh","fr","de","es","ar"))
	For Each code As String In languagesList
		If lang.StartsWith(code) Then
			Return True
		End If
	Next
	Return False
End Sub

Sub convertLanguageCodeForChinese(lang As String) As String
	If lang.StartsWith("zh") Then
		Return "zh"
	Else
		Return lang
	End If
End Sub

Sub getWords(text As String,sourceLang As String) As List
	sourceLang=convertLanguageCodeForChinese(sourceLang)
	Dim wordList As List
	wordList.Initialize
	Dim pattern As String
	If sourceLang.StartsWith("zh") Then
		pattern=""
		If Main.jieba1.IsInitialized=False Then
			Main.jieba1.Initialize
		End If
		'wait for (getStanfordTokenizedResult(text,address,sourceLang)) Complete (resultList As List)
		wordList.AddAll(Main.jieba1.segmented(text,"SEARCH"))
	Else
		pattern=" "
		wordList.AddAll(Regex.Split(pattern,text))
	End If
	removePunctuationsAndDuplicated(wordList)
	Log(wordList)
	Return wordList
End Sub

Sub getLongPhrasesFromText(text As String,sourceLang As String,wordList As List) As ResumableSub
	Dim phrases As List
	Dim address As String=""
	If Main.preferencesMap.ContainsKey("corenlp_address") Then
		address=Main.preferencesMap.Get("corenlp_address")
	End If
	If address<>"" Then
		If languageIsSupported(sourceLang) Then
			Dim phrases As List
			phrases.Initialize
			wait for (getStanfordParsedResult(text,address,sourceLang)) Complete (result As String)
			phrases.AddAll(getPhrasesFromStringViaRe(result))
			duplicatedRemovedList2(phrases,wordList)
			Log("phrases"&phrases)
		End If
	Else
		phrases.Initialize
	End If
	Return phrases
End Sub

Sub getChunks(text As String,lang As String) As List
	If lang.StartsWith("en") Then
		Dim tokens(),tags() As String
		tokens=Main.nlp.tokenize(text)
		tags=Main.nlp.posTag(tokens)
		Return Main.nlp.chunks(tokens,tags)
	Else
		Dim list1 As List
		list1.Initialize
		Return list1
	End If
End Sub

Sub getTranslation(wordList As List,chunks As List,longphrases As List,engine As String) As ResumableSub
	Dim sourceLang,targetLang As String
	sourceLang=Main.currentProject.projectFile.Get("source")
	targetLang=Main.currentProject.projectFile.Get("target")
	Dim translationList As List
	translationList.Initialize
	If Main.preferencesMap.GetDefault("autocomplete_translate_words",False) Then
		For Each word As String In wordList
			wait for (MT.getMT(word,sourceLang,targetLang,engine)) Complete (result As String)
			translationList.Add(result)
		Next
	End If
	If Main.preferencesMap.GetDefault("autocomplete_translate_chunks",False) Then
		For Each chunk As String In chunks
			wait for (MT.getMT(chunk,sourceLang,targetLang,engine)) Complete (result As String)
			translationList.Add(result)
		Next
	End If
	For Each lp As String In longphrases
		wait for (MT.getMT(lp,sourceLang,targetLang,engine)) Complete (result As String)
		translationList.Add(result)
	Next
	Return duplicatedRemovedList(translationList)
End Sub

Sub removePunctuationsAndDuplicated(words As List)
	Dim map1 As Map
	map1.Initialize
	For Each part As String In words
		If Regex.IsMatch("[。！？\.\!\?]",part)=False Then
			map1.Put(part,"")
		End If
	Next
	words.Clear
	For Each key As String In map1.Keys
		words.add(key)
	Next
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

Sub getPhrasesFromStringViaRe2(text As String) As List
	Dim phrases As List
	phrases.Initialize
	For Each item As String In Array As String("N","V","P")
		
		text=Regex.Replace("\r\n",text,"")
		text=Regex.Replace(" {1,}",text," ")
		Dim matcher As Matcher
		'\(NP .*?\){2,}
		'\(.*?
		'\)
		matcher=Regex.Matcher("\("&item&"P .*?\){2,}",text)
		Do While matcher.Find
			phrases.Add(Regex.Replace("\(.*? |\)",matcher.Match,""))
			'ListView1.Items.Add(matcher.Match)
			Log(matcher.Match)
		Loop
	Next
	Return phrases
End Sub


Sub getPhrasesFromStringViaRe(text As String) As List
	Dim phrases As List
	phrases.Initialize
	text=Regex.Replace("\r",text,"")
	text=Regex.Replace("\n",text,"")
	text=Regex.Replace(" {1,}",text," ")
	Log(text)
	For Each item As String In Array As String("NP","VP","PP","ADJP")
		Dim matcher As Matcher
		'\(NP .*?\){2,}
		'\(.*?
		'\)
		matcher=Regex.Matcher("\("&item&" .*?\){2,}",text)
		Do While matcher.Find
			phrases.Add(Regex.Replace("\(.*? |\)",matcher.Match,""))
			Log(matcher.Match)
		Loop
	Next

	getLongPhrases(text,phrases,"VP")
	getLongPhrases(text,phrases,"PP")

	Return duplicatedPhrasesRemovedList(phrases)
End Sub

Sub getLongPhrases(text As String,phrases As List,item As String)
	Dim matcher As Matcher

	matcher=Regex.Matcher("\("&item&" .*\){2,}",text)
		
	If matcher.Find Then
		Log(matcher.Match)
		Dim text As String
		Dim removeBracketPattern As String
		removeBracketPattern="\(.*? |\)"
		text=Regex.Replace(removeBracketPattern,matcher.Match,"")

		phrases.Add(text)
		
		Dim matcher2 As Matcher
		matcher2=Regex.Matcher("\("&item&" .*?\)",matcher.Match)
		If matcher2.Find Then
			If matcher.Match.IndexOf(matcher2.Match)=0 Then 'replace the beginning part
				phrases.Add(Regex.Replace(removeBracketPattern,matcher2.Match,""))
				getLongPhrases(matcher.Match.Replace(matcher2.Match,""),phrases,item)
			Else
				Dim p As String
				p="("&item
				getLongPhrases(matcher.Match.SubString2(p.Length,matcher.Match.Length),phrases,item)
			End If
		End If
	End If
End Sub

Sub duplicatedPhrasesRemovedList(list1 As List) As List
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

Sub duplicatedRemovedList(list1 As List) As List
	Dim newList As List
	newList.Initialize
	For Each item As String In list1 
		If newList.IndexOf(item)=-1  Then
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