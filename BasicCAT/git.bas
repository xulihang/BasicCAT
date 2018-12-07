B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private gitJO As JavaObject
	Private gitJOStatic As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(path As String)
	gitJOStatic.InitializeStatic("org.eclipse.jgit.api.Git")
	If File.Exists(path,".git")=False Then
		Log("init")
		init(path)
	End If
	gitJO=gitJOStatic.RunMethodJO("open",Array(getFile(path)))
End Sub

Sub getFile(path As String) As JavaObject
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array(path))
	Return fileJO
End Sub

Public Sub init(path As String)
	gitJOStatic.RunMethodJO("init",Null).RunMethodJO("setDirectory",Array(getFile(path))).RunMethodJO("call",Null)
End Sub

Public Sub add(files As String)
	gitJO.RunMethodJO("add",Null).RunMethodJO("addFilepattern",Array(files)).RunMethodJO("call",Null)
End Sub

public Sub commit(message As String,name As String,email As String) As String
	Try
		Dim commitCommand As JavaObject
		commitCommand=gitJO.RunMethodJO("commit",Null)
		If name<>"" Then
			commitCommand.RunMethod("setCommitter",Array As String(name,email))
			commitCommand.RunMethod("setAuthor",Array As String(name,email))
			commitCommand.RunMethod("setAll",Array(True))
		End If
		commitCommand.RunMethodJO("setMessage",Array(message)).RunMethodJO("call",Null)
	Catch
		Log(LastException)
		Return "error"&LastException.Message
	End Try
    Return "success"
End Sub

Sub setCredentialProvider(username As String,password As String) As JavaObject
	Dim cp As JavaObject
	cp.InitializeNewInstance("org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider",Array(username,password))
	Return cp
End Sub

Public Sub pullRebase(username As String,password As String) As String
	Try
		Dim pullCommand As JavaObject
		pullCommand=gitJO.RunMethodJO("pull",Null)
		pullCommand.RunMethod("setRebase",Array(True))
		If username<>"" Then
			Dim cp As JavaObject
			cp=setCredentialProvider(username,password)
			pullCommand.RunMethod("setCredentialsProvider",Array(cp))
		End If
		Dim result As JavaObject
		result=pullCommand.RunMethodJO("call",Null).RunMethodJO("getRebaseResult",Null)
		Log("status"&result.RunMethod("getStatus",Null))
		Return result.RunMethod("getStatus",Null)
		'FAST_FORWARD
		'UP_TO_DATE
		'OK
		'STOPPED
	Catch
		Log(LastException)
		Return "error"&LastException.Message
	End Try
End Sub

Public Sub addRemote(urlString As String,name As String)
	Dim RemoteAddCommand As JavaObject
    RemoteAddCommand=gitJO.RunMethodJO("remoteAdd",Null)
	RemoteAddCommand.RunMethod("setName",Array(name))
	Dim uri As JavaObject
	uri.InitializeNewInstance("org.eclipse.jgit.transport.URIish",Array(urlString))
	RemoteAddCommand.RunMethod("setUri",Array(uri))
	RemoteAddCommand.RunMethodJO("call",Null)
End Sub

Public Sub push(username As String,password As String) As String
	Try
		Dim PushCommand As JavaObject
		PushCommand=gitJO.RunMethodJO("push",Null)
		If username<>"" Then
			Dim cp As JavaObject
			cp=setCredentialProvider(username,password)
			PushCommand.RunMethod("setCredentialsProvider",Array(cp))
		End If
		PushCommand.RunMethodJo("call",Null)
	Catch
		Log(LastException)
		Return "error"&LastException.Message
	End Try
	Return "success"
End Sub

Public Sub getStatus
	Dim status As JavaObject
	status=gitJO.RunMethodJO("status",Null).RunMethodJO("call",Null)
	

	Log(status.RunMethodJO("getConflicting",Null).RunMethod("size",Null))
	
	Log("Added: " & status.RunMethodJO("getAdded",Null))

	Log("Changed: " & status.RunMethodJO("getChanged",Null))

	Log("Conflicting: " & status.RunMethodJO("getConflicting",Null))

	Log("ConflictingStageState: " & status.RunMethodJO("getConflictingStageState",Null))

	Log("IgnoredNotInIndex: " & status.RunMethodJO("getIgnoredNotInIndex",Null))

	Log("Missing: " & status.RunMethodJO("getMissing",Null))

	Log("Modified: " & status.RunMethodJO("getModified",Null))

	Log("Removed: " & status.RunMethodJO("getRemoved",Null))

	Log("Untracked: " & status.RunMethodJO("getUntracked",Null))

	Log("UntrackedFolders: " & status.RunMethodJO("getUntrackedFolders",Null))
End Sub

Sub isConflicting As Boolean
	Dim status As JavaObject
	status=gitJO.RunMethodJO("status",Null).RunMethodJO("call",Null)
	Dim size As Int=status.RunMethodJO("getConflicting",Null).RunMethod("size",Null)
	If size>0 Then
		Return True
	Else
		Return False
	End If
End Sub

Public Sub rebase(operationMode As String)
	Try
		Dim operationJO As JavaObject
		operationJO.InitializeStatic("org.eclipse.jgit.api.RebaseCommand.Operation")
		Dim operation As Object
		operation=operationJO.GetField(operationMode)
		Dim RebaseCommand As JavaObject
		RebaseCommand=gitJO.RunMethodJO("rebase",Null)
		RebaseCommand.RunMethod("setOperation",Array(operation))
		RebaseCommand.RunMethod("call",Null)
	Catch
		Log(LastException)
	End Try

End Sub

Public Sub diffList As List
	Return  gitJO.RunMethodJO("diff",Null).RunMethod("call",Null)
End Sub

Public Sub changedFiles As List
	Dim result As List
	result.Initialize
	Dim DiffEntryList As JavaObject
	DiffEntryList=gitJO.RunMethodJO("diff",Null).RunMethod("call",Null)
	Dim size As Int
	size=DiffEntryList.RunMethod("size",Null)
	For i=0 To size - 1
		Dim diffEntry As JavaObject
		diffEntry=DiffEntryList.RunMethodJO("get",Array(i))
		result.Add(diffEntry.RunMethod("getNewPath",Null))
	Next
	Return result
End Sub