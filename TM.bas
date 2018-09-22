B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private similarityResult As KeyValueStore
	Public translationMemory As KeyValueStore
	Private externalTranslationMemory As KeyValueStore
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	similarityResult.Initialize(File.Combine(projectPath,"tm"),"similarity.db")
	translationMemory.Initialize(File.Combine(projectPath,"tm"),"TM.db")
	externalTranslationMemory.Initialize(File.Combine(projectPath,"tm"),"externalTM.db")
End Sub

Sub addPair(source As String,target As String)
	If target="" Then
		Return
	End If
	translationMemory.Put(source,target)
End Sub

Sub getMatchList(source As String) As List
	Dim matchList As List
	matchList.Initialize

    For i=0 To 1 
		Log(i)
    Next
	For Each key As String In translationMemory.ListKeys
		Dim pairList As List
		pairList.Initialize
		pairList.Add(source)
		pairList.Add(key) ' two sourcelanguage sentences
		Dim json As JSONGenerator
		json.Initialize2(pairList)
		Log(json.ToString)
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
			tmPairList.Add(translationMemory.Get(key))
			tmPairList.Add("")
			Log(tmPairList)
			matchList.Add(tmPairList)
		End If
	Next
	Return matchList
End Sub

Sub getSimilarity(str1 As String,str2 As String) As Double
	Dim result As Double
	result=1-editDistance(str1,str2)/Max(str1.Length,str2.Length)
	Log(result)
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
