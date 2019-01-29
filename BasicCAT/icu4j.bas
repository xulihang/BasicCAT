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

Sub getEncoding(dir As String,filename As String) As String
    Log(dir)
	Log(filename)
	Try
		Dim charsetDetector As JavaObject
		charsetDetector.InitializeNewInstance("com.ibm.icu.text.CharsetDetector",Null)
		charsetDetector.RunMethodJO("setText",Array(File.OpenInput(dir,filename)))
		Dim charsetMatch As JavaObject
		charsetMatch=charsetDetector.RunMethodJO("detect",Null)
		Return charsetMatch.RunMethod("getName",Null)
	Catch
		Log(LastException)
		Return "UTF-8"
	End Try
End Sub