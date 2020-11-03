B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private segmenter As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	segmenter.InitializeNewInstance("com.huaban.analysis.jieba.JiebaSegmenter",Null)
End Sub

'Mode: INDEX, SEARCH
Public Sub segmented(text As String,mode As String) As List
	Dim segmode As EnumClass
	segmode.Initialize("com.huaban.analysis.jieba.JiebaSegmenter.SegMode")
	Dim list1 As List=segmenter.RunMethod("process",Array(text,segmode.ValueOf(mode)))
	Dim words As List
	words.Initialize
	For Each SegToken As JavaObject In list1
		Dim startIndex,endIndex As Int
		startIndex=SegToken.GetField("startOffset")
		endIndex=SegToken.GetField("endOffset")
		words.Add(text.SubString2(startIndex,endIndex))
	Next
	Return words
End Sub