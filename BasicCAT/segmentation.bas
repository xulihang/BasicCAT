B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Public Sub segmentedTxt(text As String,Trim As Boolean) As List
	Dim segmentationRule As List
	segmentationRule=File.ReadList(File.DirAssets,"segmentation_en.conf")
	Dim segmentationExceptionRule As List
	segmentationExceptionRule=File.ReadList(File.DirAssets,"segmentation_en_exception.conf")
	
	Dim seperatedByCRLF As String
	seperatedByCRLF=text
	For Each rule As String In segmentationRule
		seperatedByCRLF=Regex.Replace(rule,seperatedByCRLF,"$0"&CRLF)
	Next

	For Each rule As String In segmentationExceptionRule
		seperatedByCRLF=seperatedByCRLF.Replace(rule&CRLF,rule)
	Next
	Dim out As List
	out.Initialize
	For Each sentence As String In Regex.Split(CRLF,seperatedByCRLF)
		If Trim Then
			sentence=sentence.Trim
		End If
		out.Add(sentence)
	Next
	Log(out)
	Return out
End Sub