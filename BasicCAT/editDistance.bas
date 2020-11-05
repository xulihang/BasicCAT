B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private a(,) As Int
	Private str1 As String
	Private str2 As String
End Sub

Sub compareStrings
	If str1.Length<str2.Length Then
		Dim tmp As String
		tmp=str1
		str1=str2
		str2=tmp
	End If
End Sub

Sub showDiff(source1 As String,source2 As String,fontsize As Int) As String
	str1=source1
	str2=source2
	calculateEditDistance
	Dim result As Map=interpret(revealOperation)
	Return genHtmlResult(TextInParts(result),fontsize)
End Sub

Sub getTextInParts(source1 As String,source2 As String) As Map
	str1=source1
	str2=source2
	calculateEditDistance
	Dim result As Map=interpret(revealOperation)
	Return TextInParts(result)
End Sub

Public Sub getSimilarity(source1 As String,source2 As String) As ResumableSub
	str1=source1
	str2=source2
	Sleep(0)
	Dim result As Double
	result=1-calculateEditDistance/Max(str1.Length,str2.Length)
	Dim str As String
	str=result
	Dim su As ApacheSU
	str=su.Left(str,4)
	result=str
	Return result
End Sub

Sub calculateEditDistance As Int
	
	compareStrings
	Dim maxLength As Int
	maxLength=Max(str1.Length,str2.Length)


	
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
			'Log(i&" "&j)
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

Sub revealOperation As List
	Dim maxLength As Int
	maxLength=Max(str1.Length,str2.Length)
	Dim list1 As List
	list1.Initialize
	
	Dim x,y As Int
	x=str1.Length
	y=str2.Length
	For i=maxLength To 0 Step -1
		Dim map1 As Map
		map1=getWayAndPos(x,y)
		list1.Add(map1)
		x=map1.Get("x")
		y=map1.Get("y")
	Next
	Return list1
End Sub

Sub getWayAndPos(x As Int,y As Int) As Map
	Dim left,diagonal,up As Int
	Dim way As String
	Dim map1 As Map
	map1.Initialize
	If x-1=-1 And y-1<>-1 Then
		way="up"
		y=y-1
		map1.Put("way",way)
		map1.Put("x",x)
		map1.Put("y",y)
		Return map1
	End If
	If y-1=-1 And x-1<>-1 Then
		way="left"
		x=x-1
		map1.Put("way",way)
		map1.Put("x",x)
		map1.Put("y",y)
		Return map1
	End If
	If y-1=-1 And x-1=-1 Then
		way="end"
		map1.Put("way",way)
		map1.Put("x",x)
		map1.Put("y",y)
		Return map1
	End If
	left=a(x-1,y)
	diagonal=a(x-1,y-1)
	up=a(x,y-1)
	'优先级按照左上角、上边、左边的顺序
	If left<up Then
		If left<diagonal Then
			way="left"
		End If
	End If
	If up<left Then
		If up<diagonal Then
			way="up"
		End If
	End If
	If left=up Then
		way="up"
	End If
	If diagonal<=left And diagonal<=up Then
		way="diagonal"
	End If
	Select way
		Case "up"
			y=y-1
		Case "left"
			x=x-1
		Case "diagonal"
			x=x-1
			y=y-1
	End Select

	map1.Put("way",way)
	map1.Put("x",x)
	map1.Put("y",y)
	Return map1
End Sub

Sub interpret(list1 As List) As Map
	Dim add,del,substitute,diff As String
	Dim diffList,diffPosList,addList,addPosList As List
	diffList.Initialize
	addList.Initialize
	addPosList.Initialize
	diffPosList.Initialize
	For Each map1 As Map In list1
		Dim text As String
		If map1.Get("way")="up" Then
			'Log("Add "&str2.CharAt(map1.Get("y")))
			add=add&str2.CharAt(map1.Get("y"))
			
			addPosList.InsertAt(0,map1.Get("y"))
			text=str2.CharAt(map1.Get("y"))
			addList.InsertAt(0,text)
		Else if map1.Get("way")="left" Then
			'Log("Del "&str1.CharAt(map1.Get("x")))
			del=del&str1.CharAt(map1.Get("x"))
			diff=diff&str1.CharAt(map1.Get("x"))
			text=str1.CharAt(map1.Get("x"))
			diffList.InsertAt(0,text)
			diffPosList.InsertAt(0,map1.Get("x"))
		Else if map1.Get("way")="diagonal" Then
			If str1.CharAt(map1.Get("x"))<>str2.CharAt(map1.Get("y")) Then
				'Log("substitute "&str1.CharAt(map1.Get("x")))
				substitute=substitute&str1.CharAt(map1.Get("x"))
				diff=diff&str1.CharAt(map1.Get("x"))
				text=str1.CharAt(map1.Get("x"))
				diffList.InsertAt(0,text)
				diffPosList.InsertAt(0,map1.Get("x"))
				'Log("Switch "&TextField2.Text.CharAt(map1.Get("y")))
			End If
		End If
	Next

	Dim su As ApacheSU
	add=su.Reverse(add)
	diff=su.Reverse(diff)
	del=su.Reverse(del)
	substitute=su.Reverse(substitute)
	'Log(add&del&substitute)
	Dim result As Map
	result.Initialize
	result.Put("addList",addList)
	result.Put("diffList",diffList)
	result.Put("addPosList",addPosList)
	result.Put("diffPosList",diffPosList)
	Return result
End Sub

Sub genHtmlResult(strs As Map,fontsize As Int) As String
	Dim str1parts,str2parts As List
	str1parts=strs.Get("str1")
	str2parts=strs.Get("str2")
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append($"<!DOCTYPE HTML><html><head><style type="text/css">p {font-size: ${fontsize}px}</style></head><body>"$)
	sb.Append("<p>")
	For Each part As String In str1parts
		sb.Append(part)
	Next
	sb.Append("</p><p>")
	
	sb.Append("<p>")
	For Each part As String In str2parts
		sb.Append(part)
	Next
	sb.Append("</p>")
	sb.Append("</body></html>")
	Return sb.ToString
End Sub

Sub TextInParts(result As Map) As Map
	Dim addList,diffList,addPosList,diffPosList As List
	addList=result.Get("addList")
	diffList=result.Get("diffList")
	addPosList=result.Get("addPosList")
	diffPosList=result.Get("diffPosList")
	Dim str1Parts As List
	str1Parts.Initialize
	For i=0 To str1.Length-1
		Dim Text As String
		Text=str1.CharAt(i)
		If diffList.IndexOf(Text)<>-1 And diffList.Size<>0 Then
			If diffPosList.Get(diffList.IndexOf(Text))=i Then
				diffPosList.RemoveAt(diffList.IndexOf(Text))
				diffList.RemoveAt(diffList.IndexOf(Text))
				Text="<font color="&Chr(34)&"red"&Chr(34)&">"&Text&"</font>"
			End If
		End If
		str1Parts.add(Text)
	Next
	
	Dim str2Parts As List
	str2Parts.Initialize
	For i=0 To str2.Length-1
		Dim Text As String
		Text=str2.CharAt(i)
		If addList.IndexOf(Text)<>-1 And addList.Size<>0 Then
			
			If addPosList.Get(addList.IndexOf(Text))=i Then
				addPosList.RemoveAt(addList.IndexOf(Text))
				addList.RemoveAt(addList.IndexOf(Text))
				Text="<font color="&Chr(34)&"green"&Chr(34)&">"&Text&"</font>"
			End If
		End If
		str2Parts.Add(Text)
	Next
	
	Dim strs As Map
	strs.Initialize
	strs.Put("str1",str1Parts)
	strs.Put("str2",str2Parts)
	Return strs
End Sub

