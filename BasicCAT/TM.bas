B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public translationMemory As TMDB
	Public externalTranslationMemory As TMDB
	Private sharedTM As ClientKVS
	Private similarityStore As Map
	Public currentSource As String
	Private projectName As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String,sourceLang As String,targetLang As String)
	translationMemory.Initialize(File.Combine(projectPath,"TM"),"TM.db",sourceLang,targetLang)
	externalTranslationMemory.Initialize(File.Combine(projectPath,"TM"),"externalTM.db",sourceLang,targetLang)
	similarityStore.Initialize
	initSharedTM(projectPath)
End Sub

Public Sub initSharedTM(projectPath As String)
	If Main.currentProject.settings.GetDefault("sharingTM_enabled",False)=True Then
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
		sharedTM.Initialize(Me, "sharedTM", address,File.Combine(projectPath,"TM"),"sharedTM.db",key)
		sharedTM.SetAutoRefresh(Array(projectName&"TM"), 0.1) 'auto refresh every 0.1 minute
		Dim job As HttpJob
		job.Initialize("job",Me)
		If address.EndsWith("/")=False Then
			address=address&"/"
		End If
		job.Download(address&"getinfo?type=size&user="&projectName&"TM")
		wait for (job) JobDone(job As HttpJob)
		If job.Success Then
			Try
				Dim size As Int=job.GetString
				If size=0 Then
					fillSharedTM
				End If
			Catch
				Log(LastException)
			End Try
		End If
		job.Release
	End If
End Sub

Public Sub changedRefreshStatus(status As Boolean)
	If sharedTM.IsInitialized Then
		sharedTM.changedRefreshStatus(status)
	End If
End Sub


Sub fillSharedTM
	'progressDialog.Show("Filling SharedTM","sharedTM")
	Dim tmmap As Map
	tmmap=sharedTM.GetAll(projectName&"TM")
	'Dim size As Int=translationMemory.ListKeys.Size
	Dim index As Int=0
	Dim toAddMap As Map
	toAddMap.Initialize
	For Each key As String In translationMemory.ListKeys
		index=index+1
	    Sleep(0)
		'progressDialog.update(index,size)
		If tmmap.ContainsKey(key) Then
			
			Dim previousTargetMap As Map=translationMemory.Get(key)
			Dim newTargetMap As Map=tmmap.Get(key)
			Dim previousCreatedTime,newCreatedTime As Long
			previousCreatedTime=previousTargetMap.Get("createdTime")
			newCreatedTime=newTargetMap.Get("createdTime")
			
			If previousTargetMap.Get("text")<>translationMemory.Get("text") And newCreatedTime>previousCreatedTime Then
				toAddMap.Put(key,translationMemory.Get(key))
			End If
		Else
			toAddMap.Put(key,translationMemory.Get(key))
		End If
	Next
	fillALL(toAddMap)
	'progressDialog.close
End Sub

Sub fillALL(toAddMap As Map)
	For Each key As String In toAddMap.Keys
		Sleep(0)
		sharedTM.Put(projectName&"TM",key,toAddMap.Get(key))
	Next
End Sub


Sub sharedTM_NewData(changedItems As List)
	Log("changed"&changedItems)
	Dim changedKeys As List
	changedKeys.Initialize

	Dim map1 As Map=sharedTM.GetAll(projectName&"TM")
	For Each item1 As Item In changedItems
		If item1.UserField=projectName&"TM" Then
			If item1.ValueField=Null Then 'remove
				sharedTM.removeLocal(item1.UserField,item1.KeyField)
				If translationMemory.ContainsKey(item1.KeyField) Then
					translationMemory.Remove(item1.KeyField)
				End If
				Continue
			End If
			
			If translationMemory.ContainsKey(item1.KeyField) Then

				Dim previousTargetMap,newTargetMap As Map
				previousTargetMap=translationMemory.Get(item1.KeyField)
				newTargetMap=map1.Get(item1.KeyField)
				Dim previousCreatedTime,newCreatedTime As Long
				previousCreatedTime=previousTargetMap.Get("createdTime")
				newCreatedTime=newTargetMap.Get("createdTime")
				
				If newCreatedTime>previousCreatedTime Then
					translationMemory.Put(item1.KeyField,map1.Get(item1.KeyField))
					changedKeys.Add(item1.KeyField)
				End If
			Else
				translationMemory.Put(item1.KeyField,map1.Get(item1.KeyField))
				changedKeys.Add(item1.KeyField)
			End If
		End If
	Next
	Main.currentProject.saveNewDataToWorkfile(changedKeys)
End Sub

public Sub close
	If translationMemory.IsInitialized Then
		translationMemory.Close
		externalTranslationMemory.Close
	End If
End Sub

Sub addPair(source As String,targetMap As Map)
    Dim target As String
	target=targetMap.Get("text")
	Dim note As String
	note=targetMap.Get("note")
	Dim createdTime As Long
	createdTime=targetMap.Get("createdTime")
	If translationMemory.ContainsKey(source) Then
		Dim previousTargetMap As Map
		previousTargetMap=translationMemory.Get(source)
		Dim previousCreatedTime As Long=previousTargetMap.GetDefault("createdTime",0)
		If previousTargetMap.Get("text")=target Then
			If previousTargetMap.GetDefault("note","")=note Then
				Return
			End If
		End If
		If previousCreatedTime>createdTime Then
			Return
		End If
	End If
	translationMemory.Put(source,targetMap)
	addPairToSharedTM(source,targetMap)
End Sub

Public Sub addPairToSharedTM(source As String,targetMap As Map)
	If Main.currentProject.settings.GetDefault("sharingTM_enabled",False)=True Then
		sharedTM.Put(projectName&"TM",source,targetMap)
	End If
End Sub

Public Sub removeFromSharedTM(source As String)
	If Main.currentProject.settings.GetDefault("sharingTM_enabled",False)=True Then
		sharedTM.Put(projectName&"TM", source, Null) ' this equals remove method
	End If
End Sub

Public Sub deleteExternalTranslationMemory
	externalTranslationMemory.DeleteAll
End Sub

Public Sub importExternalTranslationMemory(tmList As List,projectFile As Map) As ResumableSub
	progressDialog.Show("Loading external memory","loadtm")
	Dim segments As List
	segments.Initialize
	For Each tmfile As String In tmList
		Dim tmfileLowercase As String
		tmfileLowercase=tmfile.ToLowerCase
		If tmfileLowercase.EndsWith(".txt") Then
			segments.AddAll(importedTxt(tmfile))
		Else if tmfileLowercase.EndsWith(".tmx") Then
			segments.AddAll(TMX.importedListQuick(File.Combine(Main.currentProject.path,"TM"),tmfile,projectFile.Get("source"),projectFile.Get("target")))
		else if tmfileLowercase.EndsWith(".xlsx") Then
			segments.AddAll(importedXlsx(tmfile))
		End If
	Next
	'Log(segments)
	Dim tmToBeImported As Map
	tmToBeImported.Initialize
	If segments.Size<>0 Then
		Dim index As Int=0
		For Each bitext As List In segments
			index=index+1
			If index Mod 5 = 0 Then
				progressDialog.update(index,segments.Size)
				Sleep(0)
			End If

			Dim source,target,filename As String
			Dim targetMap As Map
			targetMap.Initialize
			
			If bitext.Size>=3 Then
				source=bitext.get(0)
				target=bitext.Get(1)
				filename=bitext.Get(2)
				If bitext.Size=4 Then
					targetMap=bitext.Get(3)
				End If
			Else
				Continue
			End If

			targetMap.Put("text",target)
			targetMap.Put("filename",filename)
			tmToBeImported.put(source,targetMap)
		Next
	End If
	'Log(externalTranslationMemory.ListKeys.Size)
	externalTranslationMemory.PutWithTransaction(tmToBeImported)
	progressDialog.close
	Return True
End Sub

Sub importedTxt(filename As String) As List
	Dim content As String
	content=File.ReadString(File.Combine(Main.currentProject.path,"TM"),filename)
	Dim segments As List
	segments=Regex.Split(CRLF,content)
	Dim result As List
	result.Initialize
	For Each line As String In segments

        Dim bitext As List
		bitext.Initialize
		Dim source,target As String

		source=Regex.Split("	",line)(0)
		target=Regex.Split("	",line)(1)
		bitext.Add(source)
		bitext.Add(target)
		
		Dim targetMap As Map
		targetMap.Initialize
		
		Try
			Dim creator As String
			creator=Regex.Split("	",line)(2)
			targetMap.Put("creator",creator)
			Dim creationdate As String
			creationdate=Regex.Split("	",line)(3)
			targetMap.Put("createdTime",creationdate)
			Dim note As String
			note=Regex.Split("	",line)(4)
			targetMap.Put("note",note)
		Catch
			Log(LastException)
		End Try
		
		bitext.Add(filename)
		bitext.Add(targetMap)
		result.Add(bitext)
	Next
	Return result
End Sub

Sub importedXlsx(filename As String) As List
	Dim result As List
	result.Initialize
	
	Dim wb As PoiWorkbook
	wb.InitializeExisting(File.Combine(Main.currentProject.path,"TM"),filename,"")
    
	Dim sheet1 As PoiSheet = wb.GetSheet(0)
	For Each row As PoiRow In sheet1.rows
		Dim bitext As List
		bitext.Initialize
		Dim source,target As String

		source=row.GetCell(0).ValueString
		target=row.GetCell(1).ValueString
		bitext.Add(source)
		bitext.Add(target)
		
		Dim targetMap As Map
		targetMap.Initialize
		
		Try
			Dim creator As String
			creator=row.GetCell(2).ValueString
			If creator<>"" Then
				targetMap.Put("creator",creator)
			End If
			Dim creationdate As String
			creationdate=row.GetCell(3).ValueString
			If creationdate<>"" Then
				targetMap.Put("createdTime",creationdate)
			End If			
			Dim note As String
			note=row.GetCell(4).ValueString
			If note<>"" Then
				targetMap.Put("note",note)
			End If
		Catch
			Log(LastException)
		End Try
		
		bitext.Add(filename)
		bitext.Add(targetMap)
		result.Add(bitext)
	Next

	Return result
End Sub

Sub getMatchList(source As String,matchrate As Double,getOne As Boolean) As ResumableSub
	Dim matchList As List
	matchList.Initialize
	For i=0 To 1
		If i=0 Then
			Dim kvs As TMDB
			kvs=translationMemory
		Else
			Dim kvs As TMDB
			kvs=externalTranslationMemory
		End If
		Dim matchedMap As Map
		
		If kvs.ContainsKey(source) And getOne Then
			matchedMap=kvs.Get(source)
		Else
			wait for (kvs.GetMatchedMapAsync(source,True,False)) Complete (resultMap As Map)
			matchedMap=resultMap
		End If
		
		'Log(matchedMap)
		source=source.ToLowerCase.Trim
		For Each key As String In matchedMap.Keys
			Sleep(0)
			Dim lowerCased As String=key.ToLowerCase.Trim
			If basicCompare(source,lowerCased)=False Then
				Continue
			End If

			Dim similarity As Double
			If lowerCased=source Then 'exact match
				similarity=1.0
			Else
				Dim joined As String=source&"	"&lowerCased
				If similarityStore.ContainsKey(joined) Then
					similarity=similarityStore.Get(joined)
				Else
					wait for (getSimilarityFuzzyWuzzy(source,lowerCased)) Complete (Result As Double)
					similarity=Result
					similarityStore.Put(joined,similarity)
				End If
			End If

			If similarity>=matchrate Then
				Dim tmPairList As List
				tmPairList.Initialize
				tmPairList.Add(similarity)
				tmPairList.Add(key)
				
				Dim target As String
				Dim targetMap As Map
				targetMap=kvs.Get(key)
				target=targetMap.Get("text")
				tmPairList.Add(target)
				If i=0 Then
					tmPairList.Add(targetMap.GetDefault("creator","anonymous"))
				Else
					tmPairList.Add(targetMap.Get("filename")) ' external tm name
				End If
				'Log(tmPairList)
				matchList.Add(tmPairList)
				If getOne Then
					Return matchList
				End If
			End If
		Next
	Next
	
	Return subtractedAndSortMatchList(matchList)
End Sub

Sub getMatchListOld(source As String) As ResumableSub
	Dim matchList As List
	matchList.Initialize

    Dim matchrate As Double
	If Main.currentProject.settings.ContainsKey("matchrate") Then
		matchrate=Main.currentProject.settings.Get("matchrate")
	Else
		matchrate=0.5
	End If
	For i=0 To 1
		If i=0 Then
			Dim kvs As TMDB
			kvs=translationMemory
		Else
			Dim kvs As TMDB
			kvs=externalTranslationMemory
		End If
		For Each key As String In kvs.ListKeys
			Sleep(0)
			If basicCompare(source,key)=False Then
				Continue
			End If

			Dim similarity As Double
			If key=source Then 'exact match
				similarity=1.0
			Else
				If similarityStore.ContainsKey(source&"	"&key) Then
					similarity=similarityStore.Get(source&"	"&key)
				Else
					wait for (getSimilarityFuzzyWuzzy(source,key)) Complete (Result As Double)
					similarity=Result
					similarityStore.Put(source&"	"&key,similarity)
				End If
			End If

			If similarity>matchrate Then
				Dim tmPairList As List
				tmPairList.Initialize
				tmPairList.Add(similarity)
				tmPairList.Add(key)
				
				Dim target As String
				Dim targetMap As Map
				targetMap=kvs.Get(key)
				target=targetMap.Get("text")
				tmPairList.Add(target)
				If i=0 Then
					tmPairList.Add(targetMap.GetDefault("creator","anonymous"))
				Else
					tmPairList.Add(targetMap.Get("filename")) ' external tm name
				End If
				'Log(tmPairList)
				matchList.Add(tmPairList)
			End If
		Next
    Next
	
	Return subtractedAndSortMatchList(matchList)
End Sub


Sub getOneUseMemory(source As String,rate As Double) As ResumableSub
	Dim onePairList As List
	onePairList.Initialize
	wait for (getMatchList(source,rate,True)) Complete (matchList As List) 
	If matchList.Size=0 Then
		Return onePairList
	End If
	onePairList=matchList.Get(0)
	Return onePairList
End Sub

Sub basicCompare(str1 As String,str2 As String) As Boolean
	Dim temp As String
	If str1.Length>str2.Length Then
		temp=str1
		str1=str2
		str2=temp
	End If
	If str1.Length-str2.Length>str2.Length/2 Then
		Return False
	Else
		Return True
	End If
	
End Sub

Sub subtractedAndSortMatchList(matchList As List) As List
	If matchList.Size<=1 Then
		Return matchList
	End If
	Dim newlist As List
	newlist.Initialize
	Dim sortedList As List
	sortedList=BubbleSort(matchList)
	For i=0 To Min(4,sortedList.Size-1)
		newlist.Add(sortedList.Get(i))
	Next
	Return newlist
End Sub

Sub BubbleSort(matchList As List) As List
	For j=0 To matchList.Size-1
		For i = 1 To matchList.Size - 1
			If  NextIsMoreSimilar(matchList.Get(i),matchList.Get(i-1)) Then
				matchList=Swap(matchList,i, i-1)
			End If
		Next
	Next
	Return matchList
End Sub

Sub Swap(matchList As List,index1 As Int, index2 As Int) As List
	Dim temp As List
	temp = matchList.Get(index1)
	matchList.Set(index1,matchList.Get(index2))
	matchList.Set(index2,temp)
	Return matchList
End Sub

Sub NextIsMoreSimilar(list2 As List,list1 As List) As Boolean
	'list2 is the next
	If list2.Get(0)>list1.Get(0) Then
		Return True
	Else
		Return False
	End If
End Sub

Sub getSimilarityFuzzyWuzzy(str1 As String,str2 As String) As ResumableSub
	Sleep(0)
	Dim result As Double
	Dim jo As JavaObject
	result=jo.InitializeStatic("me.xdrop.fuzzywuzzy.FuzzySearch").RunMethod("ratio",Array As String(str1,str2))
	result=result/100
	Return result
End Sub

Sub getExternalMemorySize As Int
	Return externalTranslationMemory.ListKeys.Size
End Sub

Sub getProjectMemorySize As Int
	Return externalTranslationMemory.ListKeys.Size+translationMemory.ListKeys.Size
End Sub

