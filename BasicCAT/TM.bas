B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public translationMemory As KeyValueStore
	Public externalTranslationMemory As KeyValueStore
	Private similarityStore As Map
	Public currentSource As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	translationMemory.Initialize(File.Combine(projectPath,"TM"),"TM.db")
    externalTranslationMemory.Initialize(File.Combine(projectPath,"TM"),"externalTM.db")
	similarityStore.Initialize
End Sub

public Sub close
	If translationMemory.IsInitialized Then
		translationMemory.Close
		externalTranslationMemory.Close
	End If
End Sub

Sub addPair(source As String,target As String)
	If target="" Then
		Return
	End If
	If translationMemory.ContainsKey(source) Then
		If translationMemory.Get(source)=target Then
			Return
		End If
	End If
	translationMemory.Put(source,target)
End Sub

Public Sub deleteExternalTranslationMemory
	externalTranslationMemory.DeleteAll
End Sub

Public Sub importExternalTranslationMemory(tmList As List) As ResumableSub
	progressDialog.Show("Loading external memory","loadtm")
	Dim segments As List
	segments.Initialize
	For Each tmfile As String In tmList
		Dim tmfileLowercase As String
		tmfileLowercase=tmfile.ToLowerCase
		If tmfileLowercase.EndsWith(".txt") Then
			segments.AddAll(importedTxt(tmfile))
		Else if tmfileLowercase.EndsWith(".tmx") Then
			segments.AddAll(TMX.importedList(File.Combine(Main.currentProject.path,"TM"),tmfile))
		End If
	Next
	Log(segments)
	If segments.Size<>0 Then
		Dim index As Int=0
		For Each bitext As List In segments
			index=index+1
			progressDialog.update(index,segments.Size)
			Sleep(0)
			Dim source,target,filename As String
			Dim targetList As List
			targetList.Initialize
			If bitext.Size=3 Then
				source=bitext.get(0)
				target=bitext.Get(1)
				filename=bitext.Get(2)
			Else
				Continue
			End If

			targetList.Add(target)
			targetList.Add(filename)
			externalTranslationMemory.put(source,targetList)
		Next
	End If
	Log(externalTranslationMemory.ListKeys.Size)
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
		bitext.Add(filename)
		result.Add(bitext)
	Next
	Return result
End Sub


Sub getMatchList(source As String) As ResumableSub
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
			Dim kvs As KeyValueStore
			kvs=translationMemory
		Else
			Dim kvs As KeyValueStore
			kvs=externalTranslationMemory
		End If
		For Each key As String In kvs.ListKeys
			Sleep(0)
			If basicCompare(source,key)=False Then
				Continue
			End If

			'Dim pairList As List
			'pairList.Initialize
			'pairList.Add(source)
			'pairList.Add(key) ' two sourcelanguage sentences
			'Dim json As JSONGenerator
			'json.Initialize2(pairList)
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
				
				If i=0 Then
					tmPairList.Add(kvs.Get(key))
					tmPairList.Add("")
				Else
					Dim targetList As List
					targetList=kvs.Get(key)
					tmPairList.Add(targetList.Get(0))
					tmPairList.Add(targetList.Get(1)) ' external tm name
				End If
				Log(tmPairList)
				matchList.Add(tmPairList)
			End If
		Next
    Next
	
	Return subtractedAndSortMatchList(matchList)
End Sub


Sub getOneUseMemory(source As String,rate As Double) As ResumableSub
	
	Dim matchList As List
	matchList.Initialize
	Dim onePairList As List
	onePairList.Initialize
	For i=0 To 1
		If i=0 Then
			Dim kvs As KeyValueStore
			kvs=translationMemory
		Else
			Dim kvs As KeyValueStore
			kvs=externalTranslationMemory
		End If
		
		If kvs.ContainsKey(source) Then
			Dim tmPairList As List
			tmPairList.Initialize
			tmPairList.Add(1)
			tmPairList.Add(source)
			If i=0 Then
				tmPairList.Add(kvs.Get(source))
				tmPairList.Add("")
			Else
				Dim targetList As List
				targetList=kvs.Get(source)
				tmPairList.Add(targetList.Get(0))
				tmPairList.Add(targetList.Get(1))
			End If
			onePairList=tmPairList
			Return onePairList
		End If
		
		For Each key As String In kvs.ListKeys
			If basicCompare(source,key)=False Then
				Continue
			End If
			
			
			
			Dim similarity As Double
			
			If similarityStore.ContainsKey(source&"	"&key) Then
				similarity=similarityStore.Get(source&"	"&key)
			Else
				wait for (getSimilarityFuzzyWuzzy(source,key)) Complete (Result As Double)
				similarity=Result
				similarityStore.Put(source&"	"&key,similarity)
			End If
			




			If similarity>rate Then
				Dim tmPairList As List
				tmPairList.Initialize
				tmPairList.Add(similarity)
				tmPairList.Add(key)
				
				If i=0 Then
					tmPairList.Add(kvs.Get(key))
					tmPairList.Add("")
				Else
					Dim targetList As List
					targetList=kvs.Get(key)
					tmPairList.Add(targetList.Get(0))
					tmPairList.Add(targetList.Get(1))
				End If
				If similarity=1 Then
					'Log("exact match")
					onePairList=tmPairList
					Return onePairList
				End If
				matchList.Add(tmPairList)
			End If
		Next
	Next
	If matchList.Size=0 Then
		Return onePairList
	End If
	onePairList=subtractedAndSortMatchList(matchList).Get(0)
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

