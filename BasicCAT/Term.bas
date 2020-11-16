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
		Dim key As String
		Dim configPath As String=File.Combine(projectPath,"config")
		If File.Exists(configPath,"accesskey") Then
			key=File.ReadString(configPath,"accesskey")
		Else
			key="put your key in this file"
		End If
		sharedTerm.Initialize(Me, "sharedTerm", address,File.Combine(projectPath,"Term"),"sharedTerm.db",key)
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

Public Sub changedRefreshStatus(status As Boolean)
	If sharedTerm.IsInitialized Then
		sharedTerm.changedRefreshStatus(status)
	End If
End Sub

Sub fillSharedTerm
	'progressDialog.Show("Filling SharedTerm","sharedTerm")
	Dim termmap As Map
	termmap=sharedTerm.GetAll(projectName&"Term")
	'Dim size As Int=terminology.ListKeys.Size
	Dim index As Int=0
	Dim toAddMap As Map
	toAddMap.Initialize
	For Each key As String In terminology.ListKeys
		index=index+1
		Sleep(0)
		'progressDialog.update(index,size)
		If termmap.ContainsKey(key) Then
			If termmap.Get(key)<>terminology.Get(key) Then
				toAddMap.Put(key,terminology.Get(key))
			End If
		Else
			toAddMap.Put(key,terminology.Get(key))
		End If
	Next
	fillALL(toAddMap)
	'progressDialog.close
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
			If item1.ValueField=Null Then 'remove
				sharedTerm.removeLocal(item1.UserField,item1.KeyField)
				If terminology.ContainsKey(item1.KeyField) Then
					terminology.Remove(item1.KeyField)
				End If
				Continue
			End If
			
			If terminology.ContainsKey(item1.KeyField) Then
				If terminology.Get(item1.KeyField)<>map1.Get(item1.KeyField) Then
					addTermFromShared(item1.KeyField,map1.Get(item1.KeyField))
				End If
			Else
				addTermFromShared(item1.KeyField,map1.Get(item1.KeyField))
			End If
		End If
	Next
End Sub

Sub addTermFromShared(key As String,targetMap As Map)
	verifyAndAddHistory(key,targetMap)
	terminology.Put(key,targetMap)
End Sub

Sub verifyAndAddHistory(key As String,targetMap As Map)
	If Main.currentProject.settings.GetDefault("record_history",True)=True Then
		Dim previousTargetMap As Map
		previousTargetMap.Initialize
		If terminology.ContainsKey(key) Then
			previousTargetMap=terminology.Get(key)
		End If
		For Each target As String In targetMap.Keys
			Log("target"&target)
			If previousTargetMap.ContainsKey(target)=False Then
				Log("does not exist")
				addHistory(key,target,targetMap.Get(target))
			Else
				Log("does exist")
				Dim previousTerminfo As Map
				previousTerminfo=previousTargetMap.Get(target)
				Dim terminfo As Map
				terminfo=targetMap.Get(target)
				If terminfo.GetDefault("note","")<>previousTerminfo.GetDefault("note","") And terminfo.GetDefault("note","")<>"" Then
					addHistory(key,target,targetMap.Get(target))
					Continue
				End If
				If terminfo.GetDefault("tag","")<>previousTerminfo.GetDefault("tag","") And terminfo.GetDefault("tag","")<>"" Then
					addHistory(key,target,targetMap.Get(target))
					Continue
				End If
			End If
		Next
	End If
End Sub

Sub addHistory(source As String,target As String,terminfo As Map)
	If Main.currentProject.settings.GetDefault("record_history",True)=True Then
		Main.currentProject.projectHistory.addTermHistory(source,target,terminfo)
	End If
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
		Else If termfileLowercase.EndsWith(".xlsx") Then
				importedXlsx(termfile,termsMap)
		Else if termfileLowercase.EndsWith(".tbx") Then
			TBX.readTermsIntoMap(File.Combine(File.Combine(Main.currentProject.path,"Term"),termfile),sourceLanguage,Main.currentProject.projectFile.Get("target"),termsMap)
		End If
	Next
    Dim termToBeImported As Map
	termToBeImported.Initialize
	If termsMap.Size<>0 Then
		Dim index As Int=0
		For Each source As String In termsMap.Keys
			index=index+1
			Sleep(0)
			progressDialog.update(index,termsMap.Size)
			termToBeImported.put(source,termsMap.Get(source))
		Next
	End If
	wait for (externalTerminology.PutMapAsync(termToBeImported)) Complete (done As Object)
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

Sub importedXlsx(filename As String,termsMap As Map)
	Dim wb As PoiWorkbook
	wb.InitializeExisting(File.Combine(Main.currentProject.path,"Term"),filename,"")
	Dim sheet1 As PoiSheet=wb.GetSheet(0)
	For Each row As PoiRow In sheet1.Rows
		Dim terminfo As Map
		terminfo.Initialize
		Dim targetMap As Map
		targetMap.Initialize
		
		Dim source,target,note,tag As String

		source=row.GetCell(0).ValueString
		target=row.GetCell(1).ValueString
		Try
			note=row.GetCell(2).ValueString
			If note<>"" Then
				terminfo.Put("note",note)
			End If
			tag=row.GetCell(3).ValueString
			If tag<>"" Then
				terminfo.Put("tag",tag)
			End If
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
	If Main.currentProject.settings.GetDefault("termMatch_algorithm","iteration")="iteration" Then
		result.AddAll(termsInASentenceUsingIteration(sentence,terminology))
	Else
		result.AddAll(termsInASentenceUsingHashMap(sentence,terminology))
	End If
	result.AddAll(termsInASentenceUsingHashMap(sentence,externalTerminology))
	Return result
End Sub

Sub termsInASentenceUsingHashMap(sentence As String,kvs As KeyValueStore) As List
	Dim result As List
	result.Initialize
    Dim words As List
	words.Initialize
	If Utils.LanguageHasSpace(sourceLanguage) Then
		'Log(sentence)
		sentence=Regex.Replace("[\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]",sentence,"") 'remove punctuations
		words.AddAll(Regex.Split(" ",sentence))
		LanguageUtils.addPhrases(words)
		If sourceLanguage.StartsWith("en") Then 'only english opennlp model exists
			Dim lemmatized As List
			lemmatized.Initialize
			lemmatized.AddAll(Regex.Split(" ",Main.nlp.lemmatizedSentence(sentence)))
			LanguageUtils.addPhrases(lemmatized)
			For Each lemma As String In lemmatized 'here, lemma may be lemmatized phrases
				If words.IndexOf(lemma)=-1 Then
					words.Add(lemma)
				End If
			Next
		End If
	Else
	    words.AddAll(Regex.Split("",sentence))
		words.AddAll(LanguageUtils.addHanziWords(sentence))
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




Sub termsInASentenceUsingIteration(sentence As String,kvs As KeyValueStore) As List
	Dim result As List
	result.Initialize

	Dim lemmatizedSentence As String
	lemmatizedSentence=Main.nlp.lemmatizedSentence(sentence)
	For Each source As String In kvs.ListKeys
		If Utils.LanguageHasSpace(sourceLanguage) Then
			If Regex.Matcher("\b"&source&"\b",sentence).Find=False Then
				If Regex.Matcher("\b"&source.ToLowerCase&"\b",sentence.ToLowerCase).Find=False Then
					If Main.nlp.IsInitialized And sourceLanguage.StartsWith("en") Then
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

Public Sub addTerm(source As String,target As String)
	Dim targetMap As Map
	targetMap.Initialize
	If terminology.ContainsKey(source) Then
		targetMap=terminology.Get(source)
	End If
	If targetMap.ContainsKey(target)=False Then
		Dim termInfo As Map
		termInfo.Initialize
		addCreatingInfo(termInfo)
		targetMap.Put(target,termInfo)
		verifyAndAddHistory(source,targetMap)
		terminology.Put(source,targetMap)
		addTermToSharedTerm(source,targetMap)
	End If
End Sub

Public Sub editTerm(source As String,previousTarget As String,target As String,terminfo As Map)
	Dim targetMap As Map
	targetMap.Initialize
	If terminology.ContainsKey(source) Then
		If previousTarget<>target Then
			removeOneTarget(source,previousTarget,False)
		End If
		targetMap=terminology.Get(source)
	End If
	addCreatingInfo(terminfo)
	targetMap.Put(target,terminfo)
	verifyAndAddHistory(source,targetMap)
	terminology.Put(source,targetMap)
	addTermToSharedTerm(source,targetMap)
End Sub

Public Sub removeOneTarget(source As String,target As String,isAddingToSharedTerm As Boolean)
	Dim targetMap As Map
	targetMap=terminology.Get(source)
	targetMap.Remove(target)
	terminology.Put(source,targetMap)
	If isAddingToSharedTerm Then
		addTermToSharedTerm(source,targetMap)
	End If
End Sub

Sub addCreatingInfo(termInfo As Map)
	Dim time As String=DateTime.Now
	termInfo.Put("createdTime",time)
	If Main.currentProject.settings.GetDefault("sharingTM_enabled",False)=True Then
		termInfo.Put("creator",Main.preferencesMap.GetDefault("vcs_username","anonymous"))
	Else
		If Main.currentProject.settings.GetDefault("git_enabled",False)=False Then
			termInfo.Put("creator",Main.preferencesMap.GetDefault("vcs_username","me"))
		Else
			termInfo.Put("creator",Main.preferencesMap.GetDefault("vcs_username","anonymous"))
		End If
	End If
End Sub

Public Sub addTermToSharedTerm(source As String,targetMap As Map)
	If Main.currentProject.settings.GetDefault("sharingTerm_enabled",False)=True Then
		sharedTerm.Put(projectName&"Term",source,targetMap)
	End If
End Sub

Public Sub removeFromSharedTerm(source As String)
	If Main.currentProject.settings.GetDefault("sharingTerm_enabled",False)=True Then
		sharedTerm.Put(projectName&"Term", source, Null) ' this equals remove method
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
