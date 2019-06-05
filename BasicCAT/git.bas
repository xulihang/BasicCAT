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
	Private th As Thread
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(path As String)
	th.Initialise("th")
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

Public Sub fetchAsync(username As String,password As String) As ResumableSub
	th.Start(Me,"fetch",Array As Object(username,password))
	wait for th_Ended(endedOK As Boolean, error As String)
	Return endedOK
End Sub

Public Sub fetch(username As String,password As String)
	Dim fetchCommand As JavaObject
	fetchCommand=gitJO.RunMethodJO("fetch",Null)
	If username<>"" Then
		Dim cp As JavaObject
		cp=setCredentialProvider(username,password)
		fetchCommand.RunMethod("setCredentialsProvider",Array(cp))
	End If
	fetchCommand.RunMethodJO("call",Null)
End Sub

Public Sub setWorkdir(dirpath As String)
	Dim StoredConfig As JavaObject
	StoredConfig=gitJO.RunMethodJO("getRepository",Null).RunMethodJO("getConfig",Null)
	StoredConfig.RunMethodJO("setString",Array("core",Null,"worktree",dirpath))
	StoredConfig.RunMethod("save",Null)
End Sub

Public Sub unsetWorkdir
	Dim StoredConfig As JavaObject
	StoredConfig=gitJO.RunMethodJO("getRepository",Null).RunMethodJO("getConfig",Null)
	StoredConfig.RunMethodJO("unset",Array("core",Null,"worktree"))
	StoredConfig.RunMethod("save",Null)
End Sub

Public Sub getWorkdirPath As String
	Dim repo As JavaObject
	repo=gitJO.RunMethodJO("getRepository",Null)
	Dim path As String
	path=repo.RunMethodJO("getWorkTree",Null).RunMethod("getCanonicalPath",Null)
	Return path
End Sub


Public Sub checkoutFile(path As String,name As String,startpoint As String)
	Dim checkoutCommand As JavaObject
	checkoutCommand=gitJO.RunMethodJO("checkout",Null)
	checkoutCommand.RunMethod("addPath",Array(path))
	checkoutCommand.RunMethod("setName",Array(name))
	checkoutCommand.RunMethod("setStartPoint",Array(startpoint))
	checkoutCommand.RunMethod("call",Null)
End Sub

Public Sub checkoutAllFiles(name As String,startpoint As String)
	Dim checkoutCommand As JavaObject
	checkoutCommand=gitJO.RunMethodJO("checkout",Null)
	checkoutCommand.RunMethod("setAllPaths",Array(True))
	checkoutCommand.RunMethod("setName",Array(name))
	checkoutCommand.RunMethod("setStartPoint",Array(startpoint))
	checkoutCommand.RunMethod("call",Null)
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
		Return result.RunMethodJO("getStatus",Null).RunMethod("toString",Null)
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

Public Sub pushAsync(username As String,password As String,remoteName As String,branchName As String) As ResumableSub
	th.Start(Me,"push",Array As Object(username,password,remoteName,branchName))
	wait for th_Ended(endedOK As Boolean, error As String)
	Return endedOK
End Sub

Public Sub push(username As String,password As String,remoteName As String,branchName As String)
	Dim PushCommand As JavaObject
	PushCommand=gitJO.RunMethodJO("push",Null)
	PushCommand.RunMethodJO("setRemote",Array(remoteName))
	PushCommand.RunMethodJO("add",Array(branchName))
	If username<>"" Then
		Dim cp As JavaObject
		cp=setCredentialProvider(username,password)
		PushCommand.RunMethod("setCredentialsProvider",Array(cp))
	End If
	PushCommand.RunMethodJo("call",Null)
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

Public Sub isConflicting As Boolean
	Dim status As JavaObject
	status=gitJO.RunMethodJO("status",Null).RunMethodJO("call",Null)
	Dim size As Int=status.RunMethodJO("getConflicting",Null).RunMethod("size",Null)
	If size>0 Then
		Return True
	Else
		Return False
	End If
End Sub

Public Sub rebase(operationMode As String,upstream As String) As String
	Try
		Dim operationJO As JavaObject
		operationJO.InitializeStatic("org.eclipse.jgit.api.RebaseCommand.Operation")

		Dim RebaseCommand As JavaObject
		RebaseCommand=gitJO.RunMethodJO("rebase",Null)
		If operationMode<>"" And operationMode<>Null Then
			Log("rebase")
			Dim operation As Object
			operation=operationJO.GetField(operationMode)
			RebaseCommand.RunMethod("setOperation",Array(operation))
		End If
		If upstream<>"" Then
			RebaseCommand.RunMethod("setUpstream",Array(upstream))
		End If
		
		Dim result As JavaObject
		result=RebaseCommand.RunMethod("call",Null)
		Log("status"&result.RunMethod("getStatus",Null))
		Return result.RunMethodJO("getStatus",Null).RunMethod("toString",Null)
	Catch
		Log(LastException)
		Return "error"&LastException.Message
	End Try
End Sub

Public Sub diffList As List
	Return  gitJO.RunMethodJO("diff",Null).RunMethod("call",Null)
End Sub

Public Sub diffListBetweenBranches(oldHead As String,newHead As String) As List
	Dim repo As JavaObject
	repo=gitJO.RunMethodJO("getRepository",Null)

	
	Dim oldHeadObjectID As JavaObject
	oldHeadObjectID=repo.RunMethodJO("resolve",Array(oldHead&"^{tree}"))

	Dim newHeadObjectID As JavaObject
	newHeadObjectID=repo.RunMethodJO("resolve",Array(newHead&"^{tree}"))
	
	Dim ObjectReader As JavaObject
	ObjectReader=repo.RunMethodJO("newObjectReader",Null)
	Dim oldTreeIter,currentTreeIter As JavaObject
	oldTreeIter.InitializeNewInstance("org.eclipse.jgit.treewalk.CanonicalTreeParser",Null)
	currentTreeIter.InitializeNewInstance("org.eclipse.jgit.treewalk.CanonicalTreeParser",Null)
	oldTreeIter.RunMethod("reset",Array(ObjectReader,oldHeadObjectID))
	currentTreeIter.RunMethod("reset",Array(ObjectReader,newHeadObjectID))
	Dim DiffEntryList As List=gitJO.RunMethodJO("diff",Null).RunMethodJO("setNewTree",Array(currentTreeIter)).RunMethodJO("setOldTree",Array(oldTreeIter)).RunMethod("call",Null)
	Dim filenames As List
	filenames.Initialize
	For Each diffEntry As JavaObject In DiffEntryList
		filenames.Add(diffEntry.RunMethod("getNewPath",Null))
	Next
	Return filenames
End Sub

Public Sub getCommitIDofBranch(branchRef As String) As String
	Try
	
		Dim repo As JavaObject
		repo=gitJO.RunMethodJO("getRepository",Null)
		Dim id As String
		id=repo.RunMethodJO("exactRef",Array(branchRef)).RunMethodJO("getObjectId",Null).RunMethod("getName",Null)
		Return id
	Catch
		Log(LastException)
	End Try
    Return ""
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

Public Sub conflictsUnSolvedFilename(dirPath As String) As String
	For Each filename In changedFiles
		If File.Exists(dirPath,filename) Then
			Dim content As String
			content=File.ReadString(dirPath,filename)
			If content.Contains("<<<<<<<") And content.Contains("=======") And content.Contains(">>>>>>>") Then
				Return filename
			End If
		End If
	Next
	Return "conflictsSolved"
End Sub

Public Sub getRemoteUri As String
	Dim RemoteListCommand As JavaObject
	RemoteListCommand=gitJO.RunMethodJO("remoteList",Null)
	Dim RemoteConfigList As JavaObject
	RemoteConfigList=RemoteListCommand.RunMethodJO("call",Null)
	Dim listSize As Int
	listSize=RemoteConfigList.RunMethod("size",Null)
	Log(listSize)
	Dim uri As String
	If listSize>0 Then
		Dim jo As JavaObject
		jo=RemoteConfigList.RunMethodJO("get",Array(0))
		Dim urisList As List
		urisList=jo.RunMethod("getURIs",Null)
		If urisList.Size>0 Then
			uri=urisList.Get(0)
		Else
			uri=""
		End If
	Else
		uri=""
	End If
	Return uri
End Sub