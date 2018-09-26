B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Public path As String
	Public similarityResult As KeyValueStore
	Public translationMemory As KeyValueStore
	Public externalTranslationMemory As KeyValueStore
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	similarityResult.Initialize(File.Combine(projectPath,"TM"),"similarity.db")
	translationMemory.Initialize(File.Combine(projectPath,"TM"),"TM.db")
	externalTranslationMemory.Initialize(File.Combine(projectPath,"TM"),"externalTM.db")
	Main.connectedDBMap.Put(projectPath,Me)
End Sub