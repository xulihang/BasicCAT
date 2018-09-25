B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@

Sub Process_Globals
	
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