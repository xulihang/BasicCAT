B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private history As KeyValueStore
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(projectPath As String)
	history.Initialize(File.Combine(projectPath,"History"),"History.db")
End Sub

Sub addHistory(source As String,targetMap As Map)
	Dim segmentsMap As Map
	segmentsMap.Initialize
	If history.ContainsKey(source) Then
		segmentsMap=history.Get(source)
	End If
	Dim filename As String
	filename=targetMap.Get("filename")

	Dim segmentHistoryList As List
	segmentHistoryList.Initialize
	

	If segmentsMap.ContainsKey(filename) Then
		segmentHistoryList=segmentsMap.Get(filename)
	End If
	
	If segmentHistoryList.Size<>0 Then
		Dim previousHistory As Map
		previousHistory=segmentHistoryList.Get(0)
		If previousHistory.Get("text")=targetMap.get("text") Then
			Return
		End If
	End If
	
	
	Dim historyMap As Map
	historyMap.Initialize
	historyMap.Put("text",targetMap.get("text"))
	historyMap.Put("creator",targetMap.get("creator"))
	historyMap.Put("createdTime",targetMap.get("createdTime"))
	segmentHistoryList.InsertAt(0,historyMap)
	segmentsMap.Put(filename,segmentHistoryList)
	history.Put(source,segmentsMap)
End Sub

Sub getHistory(source As String,filename As String) As List
	Dim historyList As List
	historyList.Initialize
	Dim segmentsMap As Map
	segmentsMap.Initialize
	If history.ContainsKey(source) Then
		segmentsMap=history.Get(source)
	    If segmentsMap.ContainsKey(filename) Then
			historyList=segmentsMap.Get(filename)
	    End If
	End If
    Return historyList
End Sub