B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private translation As String=""
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "amazonMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("secretKey")
			Return paramsList
		Case "translate"
			translation=""
			Try
				wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) Complete (result As String)
				Return result
			Catch
				Log(LastException)
				Return ""
			End Try

	End Select
	Return ""
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim region As String="us-east-1"
	Dim key,secretKey As String
	key=getMap("amazon",getMap("mt",preferencesMap)).Get("key")
	secretKey=getMap("amazon",getMap("mt",preferencesMap)).Get("secretKey")

	Dim pluginsDir As String
	pluginsDir=preferencesMap.GetDefault("pluginDir",File.Combine(File.DirApp,"plugins"))

	Dim su As StringUtils
	source=su.EncodeUrl(source,"UTF-8")
	Log(source)
	Dim encoding As String
	encoding=GetSystemProperty("sun.jnu.encoding","UTF8")
	pluginsDir=File.Combine(File.DirApp,"plugins")
	Dim jarPath As String
	jarPath=File.Combine(File.Combine(pluginsDir,"standalone"),"amazonMTCLI.jar")
	'jarPath="amazonMTCLI.jar"
	Dim sh As Shell
	sh.Initialize("sh","java",Array As String("-jar",jarPath,source,sourceLang,targetLang,key,secretKey,region))
	sh.WorkingDirectory=File.Combine(pluginsDir,"standalone")
	sh.Encoding=encoding

	sh.RunWithOutputEvents(-1)
	Dim waitedTime As Int=0
	Do While translation=""
		Sleep(100)
		waitedTime=waitedTime+100
		If waitedTime>10000 Then
			Exit
		End If
	Loop
	If translation="" Then
		Log("timed out")
		return ""
	End If
	Dim text As String
	Try
		text=File.ReadString(File.DirTemp,"amazon")
	Catch
		Log(LastException)
		text=translation
	End Try
	
	translation=""
	Log(text)
	Return text
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub sh_StdOut (Buffer() As Byte, Length As Int)
	Dim encoding As String
	encoding=GetSystemProperty("sun.jnu.encoding","UTF8")
	Dim ByteConverter As ByteConverter
	Dim result As String
	result=ByteConverter.StringFromBytes(Buffer,encoding)
	translation=result.Trim
End Sub