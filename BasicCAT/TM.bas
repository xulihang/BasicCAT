B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Public translationMemory As KeyValueStore
	Private externalTranslationMemory As KeyValueStore
	Public currentSource As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	translationMemory.Initialize(File.Combine(projectPath,"TM"),"TM.db")
    externalTranslationMemory.Initialize(File.Combine(projectPath,"TM"),"externalTM.db")
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
	translationMemory.Put(source,target)
End Sub

Public Sub deleteExternalTranslationMemory
	externalTranslationMemory.DeleteAll
End Sub

Public Sub importExternalTranslationMemory(tmList As List)
	For Each tmfile As String In tmList
		If tmfile.EndsWith(".txt") Then
			importTxt(tmfile)
		Else
			
		End If
	Next
End Sub

Sub importTxt(filename As String)
	progressDialog.Show("Loading external memory")
	Dim content As String
	content=File.ReadString(File.Combine(Main.currentProject.path,"TM"),filename)
	Dim segments As List
	segments=Regex.Split(CRLF,content)
	Dim index As Int=0
	For Each line As String In segments
		Sleep(0)
		index=index+1
		progressDialog.update(index,segments.Size)
		Dim source,target As String
		Dim targetList As List
		targetList.Initialize
		source=Regex.Split("	",line)(0)
        If externalTranslationMemory.ContainsKey(source) Then
			Continue
        End If
		target=Regex.Split("	",line)(1)
		targetList.Add(target)
		targetList.Add(filename)
		externalTranslationMemory.put(source,targetList)
	Next
	progressDialog.close
End Sub


Sub getMatchList(source As String) As ResumableSub
	Dim matchList As List
	matchList.Initialize

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
			Dim pairList As List
			pairList.Initialize
			pairList.Add(source)
			pairList.Add(key) ' two sourcelanguage sentences
			Dim json As JSONGenerator
			json.Initialize2(pairList)
			Dim similarity As Double
			wait for (getSimilarityFuzzyWuzzy(source,key)) Complete (Result As Double)
			similarity=Result
			If similarity>0.5 Then
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
				Log(tmPairList)
				matchList.Add(tmPairList)
			End If
		Next
    Next
	
	Return subtractedAndSortMatchList(matchList)
End Sub


Sub getOneUseMemory(source As String,rate As Int) As ResumableSub
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
		For Each key As String In kvs.ListKeys
			If basicCompare(source,key)=False Then
				Continue
			End If
			
			If kvs.ContainsKey("source") Then
				Dim tmPairList As List
				tmPairList.Initialize
				tmPairList.Add(1)
				tmPairList.Add(key)
				tmPairList.Add(kvs.Get(key))
				tmPairList.Add("")
				onePairList=tmPairList
				Return onePairList
			End If
			
			Dim similarity As Double
			wait for (getSimilarityFuzzyWuzzy(source,key)) Complete (Result As Double)
			similarity=Result



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

