B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub previousPath(kind As String) As String
	Dim settingsPath As String=File.Combine(File.DirData("BasicCAT"),"path.map")
	If File.Exists(settingsPath,"") Then
		Dim settings As Map = File.ReadMap(settingsPath,"")
		Return settings.GetDefault(kind,File.DirApp)
	Else
		Return File.DirApp
	End If
End Sub

Sub savePath(kind As String,path As String)
	If File.IsDirectory(path,"")=False Then
		path=File.GetFileParent(path)
	End If
	Dim settings As Map
	Dim settingsPath As String=File.Combine(File.DirData("BasicCAT"),"path.map")
	If File.Exists(settingsPath,"") Then
		settings=File.ReadMap(settingsPath,"")
	Else
		settings.Initialize
    End If
	settings.Put(kind,path)
	File.WriteMap(settingsPath,"",settings)
End Sub