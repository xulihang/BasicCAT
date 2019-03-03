B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private autosaveTimer As Timer
	Private mEnabled As Boolean
	Private mInterval As Long
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	If Main.preferencesMap.ContainsKey("autosaveInterval") Then
		Dim mseconds As Int
		mseconds=Main.preferencesMap.Get("autosaveInterval")*1000
		autosaveTimer.Initialize("autosaveTimer",mseconds)
	Else
		autosaveTimer.Initialize("autosaveTimer",60000)
	End If
	autosaveTimer.Enabled=False
End Sub

Sub autosaveTimer_Tick
	If Main.currentProject.IsInitialized=False Then
		Return
	End If
	If Main.currentProject.path="" Then
		Return
	Else
		createBakupFiles
		Main.currentProject.save
	End If
End Sub

Sub createBakupFiles
	Log(File.Exists(Main.currentProject.path,"bak"))
	If File.Exists(Main.currentProject.path,"bak")=False Then
		File.MakeDir(Main.currentProject.path,"bak")
	End If
	Dim bakDir As String=File.Combine(File.Combine(Main.currentProject.path,"bak"),DateTime.Now)
	File.MakeDir(bakDir,"")
	Utils.CopyWorkFolderAsync(File.Combine(Main.currentProject.path, "work"),bakDir)
	File.Copy(Main.currentProject.path,"project.bcp",bakDir,"project.bcp")
End Sub


Public Sub setEnabled(Enabled As Boolean)
	mEnabled=Enabled
	autosaveTimer.Enabled=mEnabled
End Sub

Public Sub getEnabled As Boolean
	Return mEnabled
End Sub

Public Sub setInterval(Interval As Long)
	mInterval=Interval
	autosaveTimer.Interval=mInterval
End Sub

Public Sub getInterval As Long
	Return mInterval
End Sub
