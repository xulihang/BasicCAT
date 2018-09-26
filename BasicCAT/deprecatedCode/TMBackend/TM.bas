B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private similarityResult As KeyValueStore
	Private translationMemory As KeyValueStore
	Private externalTranslationMemory As KeyValueStore
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	Dim db As ConnectedDB
	If Main.connectedDBMap.ContainsKey(projectPath) Then
		db=Main.connectedDBMap.Get(projectPath)
		If db.IsInitialized=False Then
			db.Initialize(projectPath)
		End If
	Else
		db.Initialize(projectPath)
	End If
	similarityResult=db.similarityResult
	translationMemory=db.translationMemory
	externalTranslationMemory=db.externalTranslationMemory
End Sub

Sub getOneUseMemory(source As String,rate As Int) As List
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

			Dim similarity As Double
			similarity=getSimilarity(source,key)



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
	
	onePairList=subtractedAndSortMatchList(matchList).Get(0)
	Return onePairList
End Sub

Sub getOne(source As String,rate As Int) As List
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
			Dim pairList As List
			pairList.Initialize
			pairList.Add(source)
			pairList.Add(key) ' two sourcelanguage sentences
			Dim json As JSONGenerator
			json.Initialize2(pairList)
			Dim similarity As Double
			If similarityResult.ContainsKey(json.ToString) Then
				similarity=similarityResult.Get(json.ToString)

			Else
				similarity=getSimilarity(source,key)
				similarityResult.Put(json.ToString,similarity)
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
	
	onePairList=subtractedAndSortMatchList(matchList).Get(0)
	Return onePairList
End Sub

Sub getList(source As String) As List
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
			'Sleep(0)
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
			If similarityResult.ContainsKey(json.ToString) Then
				similarity=similarityResult.Get(json.ToString)

			Else
				similarity=getSimilarity(source,key)
				similarityResult.Put(json.ToString,similarity)
			End If
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
				'Log(tmPairList)
				matchList.Add(tmPairList)
			End If
		Next
	Next
	
	Return subtractedAndSortMatchList(matchList)
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


Sub getSimilarity(str1 As String,str2 As String) As Double
	Dim result As Double
	result=1-editDistance(str1,str2)/Max(str1.Length,str2.Length)
	Dim str As String
	str=result
	Dim su As ApacheSU
	str=su.Left(str,4)
	result=str
	Return result
End Sub

Sub editDistance(str1 As String,str2 As String) As Int

	If str1.Length<str2.Length Then
		Dim tmp As String
		tmp=str1
		str1=str2
		str2=tmp
	End If
	
	'int
	Dim a(str1.Length+1,str2.Length+1) As Int 'str1是放在上面的，影响列
	a(0,0)=0
	
	For i=0 To str1.Length-1
		a(i+1,0)=a(i,0)+1
	Next

	For i=0 To str2.Length-1
		a(0,i+1)=a(0,i)+1
	Next
	
	
	'dp
	Dim temp As Int
	For j=1 To str2.Length
		For i=1 To str1.Length

			If str1.CharAt(i-1)<>str2.CharAt(j-1) Then
				temp=1
			Else
				temp=0
			End If
			a(i,j)=Min(a(i-1,j-1)+temp,Min(a(i,j-1)+1,a(i-1,j)+1))
		Next
	Next
	
	Dim content As String
	For j=0 To str2.Length
		Dim row As String
		For i=0 To str1.Length
			If i=0 Then
				row=a(i,j)
			Else
				row=row&","&a(i,j)
			End If
		Next

		content=content&row&CRLF
	Next

	
	Return a(str1.Length,str2.Length)
	
End Sub
