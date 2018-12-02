B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public terminology As KeyValueStore
	Public externalTerminology As KeyValueStore
	Private sharedTerm As ClientKVS
	Private sourceLanguage As String
	Private projectName As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String,source As String)
	terminology.Initialize(File.Combine(projectPath,"Term"),"term.db")
	externalTerminology.Initialize(File.Combine(projectPath,"Term"),"external-term.db")
	sourceLanguage=source
	initSharedTerm(projectPath)
End Sub

Public Sub initSharedTerm(projectPath As String)
	If Main.currentProject.settings.GetDefault("sharingTerm_enabled",False)=True Then
		projectName=File.GetName(projectPath)
		Log("projectName"&projectName)
		Dim address As String=Main.currentProject.settings.GetDefault("server_address","http://127.0.0.1:51042")
		sharedTerm.Initialize(Me, "sharedTerm", address,File.Combine(projectPath,"Term"),"sharedTerm.db")
		sharedTerm.SetAutoRefresh(Array(projectName&"Term"), 0.1) 'auto refresh every 0.1 minute
		Dim job As HttpJob
		job.Initialize("job",Me)
		If address.EndsWith("/")=False Then
			address=address&"/"
		End If
		job.Download(address&"getinfo?type=size&user="&projectName&"Term")
		wait for (job) JobDone(job As HttpJob)
		If job.Success Then
			Try
				Dim size As Int=job.GetString
				If size=0 Then
					fillSharedTerm
				End If
			Catch
				Log(LastException)
			End Try
		End If
		job.Release
	End If
End Sub

Sub fillSharedTerm
	progressDialog.Show("Filling SharedTerm","sharedTerm")
	Dim termmap As Map
	termmap=sharedTerm.GetAll(projectName&"Term")
	Dim size As Int=terminology.ListKeys.Size
	Dim index As Int=0
	Dim toAddMap As Map
	toAddMap.Initialize
	For Each key As String In terminology.ListKeys
		index=index+1
		Sleep(0)
		progressDialog.update(index,size)
		If termmap.ContainsKey(key) Then
			If termmap.Get(key)<>terminology.Get(key) Then
				toAddMap.Put(key,terminology.Get(key))
			End If
		Else
			toAddMap.Put(key,terminology.Get(key))
		End If
	Next
	fillALL(toAddMap)
	progressDialog.close
End Sub

Sub fillALL(toAddMap As Map)
	For Each key As String In toAddMap.Keys
		Sleep(0)
		sharedTerm.Put(projectName&"Term",key,toAddMap.Get(key))
	Next
End Sub


Sub sharedTerm_NewData(changedItems As List)
	Log(changedItems)
	Dim map1 As Map=sharedTerm.GetAll(projectName&"Term")
	For Each item1 As Item In changedItems
		If item1.UserField=projectName&"Term" Then
			If terminology.ContainsKey(item1.KeyField) Then
				If terminology.Get(item1.KeyField)<>map1.Get(item1.KeyField) Then
					terminology.Put(item1.KeyField,map1.Get(item1.KeyField))
				End If
			Else
				terminology.Put(item1.KeyField,map1.Get(item1.KeyField))
			End If
		End If
	Next
End Sub

Public Sub deleteExternalTerminology
	externalTerminology.DeleteAll
End Sub

Public Sub importExternalTerminology(termList As List)
	progressDialog.Show("Loading external terminology","loadterm")
	Dim termsMap As Map
	termsMap.Initialize
	For Each termfile As String In termList
		Dim termfileLowercase As String
		termfileLowercase=termfile.ToLowerCase
		If termfileLowercase.EndsWith(".txt") Then
			importedTxt(termfile,termsMap)
		Else if termfileLowercase.EndsWith(".tbx") Then
			TBX.readTermsIntoMap(File.Combine(File.Combine(Main.currentProject.path,"Term"),termfile),sourceLanguage,Main.currentProject.projectFile.Get("target"),termsMap)
		End If
	Next

	If termsMap.Size<>0 Then
		Dim index As Int=0
		For Each source As String In termsMap.Keys
			index=index+1
			Sleep(0)
			progressDialog.update(index,termsMap.Size)
			externalTerminology.put(source,termsMap.Get(source))
		Next
	End If
	progressDialog.close
End Sub


Sub importedTxt(filename As String,termsMap As Map)
	Dim content As String
	content=File.ReadString(File.Combine(Main.currentProject.path,"Term"),filename)
	Dim segments As List
	segments=Regex.Split(CRLF,content)
	Dim result As List
	result.Initialize
	For Each line As String In segments

		Dim terminfo As Map
		terminfo.Initialize
		Dim targetMap As Map
		targetMap.Initialize
		
		Dim source,target,note,tag As String

		source=Regex.Split("	",line)(0)
		target=Regex.Split("	",line)(1)
		Try
			note=Regex.Split("	",line)(2)
			terminfo.Put("note",note)
		Catch
			Log(LastException)
		End Try
		Try
			tag=Regex.Split("	",line)(3)
			terminfo.Put("tag",tag)
		Catch
			Log(LastException)
		End Try
		If termsMap.ContainsKey(source) Then
			targetMap=termsMap.Get(source)
		End If
		targetMap.Put(target,terminfo)
		termsMap.Put(source,targetMap)
	Next
End Sub


Public Sub termsInASentence(sentence As String) As List
    Dim result As List
	result.Initialize
	result.AddAll(termsInASentenceUsingIteration(sentence,terminology))
	result.AddAll(termsInASentenceUsingHashMap(sentence,externalTerminology))
	Return result
End Sub

Sub termsInASentenceUsingHashMap(sentence As String,kvs As KeyValueStore) As List
	Dim result As List
	result.Initialize
    Dim words As List
	words.Initialize
	If sourceLanguage="en" Then
		'Log(sentence)
		sentence=Regex.Replace("[\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]",sentence,"") 'remove punctuations
		words.AddAll(Regex.Split(" ",sentence))
		addEnglishPhrases(words)
		Dim lemmatized As List
		lemmatized.Initialize
		lemmatized.AddAll(Regex.Split(" ",Main.nlp.lemmatizedSentence(sentence)))
		addEnglishPhrases(lemmatized)
		For Each lemma As String In lemmatized 'here, lemma may be lemmatized phrases
			If words.IndexOf(lemma)=-1 Then
				words.Add(lemma)
			End If
		Next
	Else
	    words.AddAll(Regex.Split("",sentence))
		words.AddAll(addChineseWords(sentence))
	End If
	For Each word As String In words
		'Log(word)
		If kvs.ContainsKey(word) Then
			Dim targetMap As Map
			targetMap=kvs.Get(word)
			For Each target As String In targetMap.Keys
				Dim oneterm As List
				oneterm.Initialize
				oneterm.Add(word)
				oneterm.Add(target)
				oneterm.Add(targetMap.Get(target))
				result.Add(oneterm)
			Next
		End If
	Next

	Return result
End Sub

Sub addEnglishPhrases(words As List)
	Dim iterateList As List
	iterateList.Initialize
	iterateList.AddAll(words)
	For i=1 To 8
		Dim endnum As Int=iterateList.Size-i
		If endnum<=0 Then
			Exit
		End If
		For j=0 To endnum 
			Dim word As String
			If j+i>iterateList.Size-1 Then
				Exit
			End If
			For k=j To j+i
				word=word&" "&iterateList.Get(k)
			Next
			word=word.Trim
			If words.IndexOf(word)=-1 Then
				words.Add(word)
			End If
		Next
	Next
End Sub

Sub addChineseWords(source As String) As List
	Dim words As List
	words.Initialize
	For i=1 To 8
		If source.Length-i<=0 Then
			Exit
		End If
		For j=0 To source.Length-i
			If j+i>source.Length Then
				Exit
			End If
			Dim word As String
			word=source.SubString2(j,j+i)
			words.Add(word)
		Next
	Next
	Return words
End Sub


Sub termsInASentenceUsingIteration(sentence As String,kvs As KeyValueStore) As List
	Dim result As List
	result.Initialize

	Dim lemmatizedSentence As String
	lemmatizedSentence=Main.nlp.lemmatizedSentence(sentence)
	For Each source As String In kvs.ListKeys
		If sourceLanguage="en" Then
			If Regex.Matcher("\b"&source&"\b",sentence).Find=False Then
				If Regex.Matcher("\b"&source.ToLowerCase&"\b",sentence.ToLowerCase).Find=False Then
					If Main.nlp.IsInitialized Then
						Dim lemmatized As String
						lemmatized=Main.nlp.lemmatizedSentence(source)
						If Regex.Matcher("\b"&lemmatized&"\b",lemmatizedSentence).Find=False Then
							Continue
						End If
					Else
						Continue
					End If
				End If
			End If
		Else
			If sentence.Contains(source)=False Then
				Continue
			End If
		End If


		Dim targetMap As Map
		targetMap=kvs.Get(source)
		For Each target As String In targetMap.Keys
			Dim oneterm As List
			oneterm.Initialize
			oneterm.Add(source)
			oneterm.Add(target)
			oneterm.Add(targetMap.Get(target))
			result.Add(oneterm)
		Next
	Next

	
	Return result
End Sub

Sub termsInASentenceOld(sentence As String) As List
	Dim result As List
	result.Initialize
	If sourceLanguage="en" Then
		Log(sentence)
		sentence=Regex.Replace("[\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]",sentence,"")
		'Log(sentence)
		Dim words() As String
		words=Regex.Split(" ",sentence)
		For Each word As String In words
			'Log(word)
			If terminology.ContainsKey(word) Then
				Dim oneterm As List
				oneterm.Initialize
				oneterm.Add(word)
				oneterm.Add(terminology.Get(word))
				result.Add(oneterm)
			End If
		Next
	Else
		
	End If
	Return result
End Sub

Sub addTerm(source As String,target As String)
	Dim targetMap As Map
	targetMap.Initialize
	If terminology.ContainsKey(source) Then
		targetMap=terminology.Get(source)
	End If
	Dim termInfo As Map
	termInfo.Initialize
	targetMap.Put(target,termInfo)
	terminology.Put(source,targetMap)
	addPairToSharedTerm(source,targetMap)
End Sub

Public Sub addPairToSharedTerm(source As String,targetMap As Map)
	If Main.currentProject.settings.GetDefault("sharingTerm_enabled",False)=True Then
		sharedTerm.Put(projectName&"Term",source,targetMap)
	End If
End Sub

Public Sub removeFromSharedTerm(source As String)
	If Main.currentProject.settings.GetDefault("sharingTerm_enabled",False)=True Then
		sharedTerm.GetAll(projectName&"Term").Remove(source)
	End If
End Sub

Sub exportToTXT(segments As List,path As String)
	Dim sb As StringBuilder
	sb.Initialize
	For Each segment As List In segments
		sb.Append(segment.Get(0)).Append("	").Append(segment.Get(1)).Append("	").Append(segment.Get(2)).Append("	").Append(segment.Get(3)).Append(CRLF)
	Next
	File.WriteString(path,"",sb.ToString)
End Sub
