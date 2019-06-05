B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
#RaisesSynchronousEvents: SubThatCanRaiseEvent
Sub Class_Globals
	Private fx As JFX
	Public path As String
	Public files As List
	Public projectFile As Map
	Public currentFilename As String
	Public segments As List
	Public projectTM As TM
	Public projectTerm As Term
	Public projectHistory As HistoryRecord
	Public lastEntry As Int
	Private previousEntry As Int=-1
	Private lastFilename As String
	Public settings As Map
	Public completed As Int
	Private cmClicked As Boolean=False
	Private cm As ContextMenu
	Private cursorReachEnd As Boolean=False
	Private projectGit As git
	Public contentChanged As Boolean=False
	Private SegEnabledFiles As List
	Private currentWorkFileFrame As Map
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	files.Initialize
	projectFile.Initialize
	segments.Initialize
	settings.Initialize
	SegEnabledFiles.Initialize
	cm.Initialize("cm")
End Sub

Sub initializeTM(projectPath As String,isExistingProject As Boolean)
	projectTM.Initialize(projectPath)
	Dim externalTMList As List
	externalTMList=settings.Get("tmList")
	Log(externalTMList.Size)
	For i=0 To externalTMList.Size-1
		Dim filename As String
		filename=externalTMList.Get(i)
		If File.Exists(File.Combine(Main.currentProject.path,"TM"),filename)=False Then
			fx.Msgbox(Main.MainForm,filename&" does not exist. Will be deleted.","")
            externalTMList.RemoveAt(i)
			settings.Put("tmList",externalTMList)
			save
		End If
	Next
	If isExistingProject Then
		If Main.preferencesMap.ContainsKey("checkExternalTMOnOpening") Then
			If Main.preferencesMap.Get("checkExternalTMOnOpening")=False Then
			    Return
			End If
		End If
	End If

	projectTM.importExternalTranslationMemory(externalTMList,projectFile)
	'runTMBackend
End Sub

Sub initializeTerm(projectPath As String)
	projectTerm.Initialize(projectPath,projectFile.Get("source"))
End Sub

Sub initializeHistory(projectPath As String)
	projectHistory.Initialize(projectPath)
End Sub

Public Sub open(jsonPath As String)
	If Utils.conflictsUnSolvedFilename(jsonPath,"")<>"conflictsSolved" Then
		fx.Msgbox(Main.MainForm,jsonPath&" has unresolved conflicts.","")
		Return
	End If
	Main.addProjectTreeTableItem
	path=getProjectPath(jsonPath)
	createProjectFiles
	Dim json As JSONParser
	json.Initialize(File.ReadString(jsonPath,""))
	projectFile=json.NextObject
	lastEntry=projectFile.Get("lastEntry")
	lastFilename=projectFile.Get("lastFile")
	settings=projectFile.Get("settings")
	files.AddAll(projectFile.Get("files"))
	For Each filepath As String In files
		addFilesToTreeTable(filepath)
	Next
	initializeTM(path,True)
	initializeTerm(path)
	initializeHistory(path)
	Main.initializeNLP(projectFile.Get("source"))

	If Main.preferencesMap.GetDefault("vcsEnabled",False)=True Then
		If settings.GetDefault("git_enabled",False) Then
			commitAndPush("")
		End If
	End If
End Sub

Public Sub newProjectSetting(source As String,target As String)
	projectFile.Put("source",source)
	projectFile.Put("target",target)
	Main.initializeNLP(source)
	Dim tmList As List
	tmList.Initialize
	Dim termList As List
	termList.Initialize
	settings.Put("tmList",tmList)
	settings.Put("termList",termList)
End Sub

Public Sub addFile(filepath As String,isExtractedByOkapi As Boolean) As ResumableSub
	Dim filename As String
	filename=Main.getFilename(filepath)
	Log("fp"&filepath)
	Log("fn"&filename)
	If isExtractedByOkapi Then
		filename=filename&".xlf"
		addToOkapiExtractedList(filename)
	Else
		Wait For (File.CopyAsync(filepath,"",File.Combine(path,"source"),filename)) Complete (Success As Boolean)
		Log("Success: " & Success)
	End If
	files.Add(filename)
	addFilesToTreeTable(filename)
	wait for (createWorkFileAccordingToExtension(filename)) Complete (result As Object)
	save
End Sub

Sub addToOkapiExtractedList(filename As String)
	Dim okapiExtractedFiles As List
	okapiExtractedFiles.Initialize
	If projectFile.ContainsKey("okapiExtractedFiles") Then
		okapiExtractedFiles=projectFile.Get("okapiExtractedFiles")
	End If
	If okapiExtractedFiles.IndexOf(filename)=-1 Then
		okapiExtractedFiles.Add(filename)
	End If
	projectFile.Put("okapiExtractedFiles",okapiExtractedFiles)
End Sub

Public Sub addFileInFolder(folderPath As String,filename As String,isExtractedbyOkapi As Boolean) As ResumableSub
	filename=filename.Replace("/",GetSystemProperty("file.separator","/"))
	If files.IndexOf(filename)=-1 Then
		FileUtils.createNonExistingDir(File.Combine(File.Combine(path,"source"),filename))
		FileUtils.createNonExistingDir(File.Combine(File.Combine(path,"work"),filename))
		FileUtils.createNonExistingDir(File.Combine(File.Combine(path,"target"),filename))
		
		If isExtractedbyOkapi Then
			filename=filename&".xlf"
			addToOkapiExtractedList(filename)
		Else
			Wait For (File.CopyAsync(folderPath,filename,File.Combine(path,"source"),filename)) Complete (Success As Boolean)
			Log("Success: " & Success)
		End If

		wait for (createWorkFileAccordingToExtension(filename)) Complete (result As Boolean)
		If result=True Then
			files.Add(filename)
			addFilesToTreeTable(filename)
		End If
		Return result
	Else
		Return False
	End If
End Sub

Public Sub saveSettings(newsettings As Map)
	projectFile.Put("settings",newsettings)
	Log(newsettings)
	save
	If newsettings.Get("tmListChanged")="yes" Then
		projectTM.deleteExternalTranslationMemory
		wait for (projectTM.importExternalTranslationMemory(settings.Get("tmList"),projectFile)) complete (result As Boolean)
	End If
	If newsettings.Get("termListChanged")="yes" Then
		projectTerm.deleteExternalTerminology
		projectTerm.importExternalTerminology(settings.Get("termList"))
	End If
	If newsettings.Get("sharingTM_enabled")=True Then
		projectTM.initSharedTM(path)
		projectTM.changedRefreshStatus(True)
	Else
		projectTM.changedRefreshStatus(False)
	End If
	If newsettings.Get("sharingTerm_enabled")=True Then
		projectTerm.initSharedTerm(path)
		projectTerm.changedRefreshStatus(True)
	Else
		projectTerm.changedRefreshStatus(False)
	End If
End Sub

public Sub save
	createProjectFiles
	If projectTM.IsInitialized=False Then
		initializeTM(path,False)
	End If
	If projectTerm.IsInitialized=False Then
		initializeTerm(path)
	End If
	If projectHistory.IsInitialized=False Then
		initializeHistory(path)
	End If
	showPreView
	projectFile.Put("files",files)
	projectFile.Put("lastFile",lastFilename)
	projectFile.Put("lastEntry",lastEntry)
	projectFile.Put("settings",settings)
	Dim json As JSONGenerator
	json.Initialize(projectFile)
	File.WriteString(path,"project.bcp",json.ToPrettyString(4))
	
	If contentChanged Then
		saveFile(currentFilename)
		gitcommit(False,True)
		
	End If
	
	Main.updateSavedTime
End Sub


Sub openFile(filename As String,onOpeningProject As Boolean)
	If onOpeningProject=False Then
		save
	End If
	If File.Exists(File.Combine(path,"work"),filename&".json")=False Then
		fx.Msgbox(Main.MainForm,"The workfile does not exist."&CRLF&"Maybe it's still in building.","")
		Return
	End If
	Main.editorLV.Items.Clear
	Main.tmTableView.Items.Clear
	Main.LogWebView.LoadHtml("")
	Main.searchTableView.Items.Clear
	segments.Clear
	currentFilename=filename

	readWorkFile(currentFilename,segments,True,path)

	Log("currentFilename:"&currentFilename)
	If lastFilename=currentFilename And segments.Size<>0 Then
		Log("ddd"&True)
		Log(lastEntry)
		Try
			Main.editorLV.ScrollTo(lastEntry)
		Catch
			lastEntry=0
			Log(LastException)
		End Try
	End If
	Dim visibleRange As Range
	visibleRange=Main.getVisibleRange(Main.editorLV)
	fillPane(visibleRange.firstIndex,visibleRange.lastIndex)
	Main.addScrollChangedEvent(Main.editorLV)
End Sub

Sub closeFile
	Main.editorLV.Items.Clear
	Main.tmTableView.Items.Clear
	Main.LogWebView.LoadHtml("")
	Main.searchTableView.Items.Clear
	segments.Clear
	currentFilename=""
End Sub

Sub addFilesToTreeTable(filename As String)
	Dim subTreeTableItem As TreeTableItem
	subTreeTableItem=Main.projectTreeTableView.Root.Children.Get(0)
	Dim tti As TreeTableItem
	Dim lbl As Label
	lbl.Initialize("lbl")
	lbl.Text=filename
	Dim fileCM As ContextMenu
	fileCM.Initialize("fileCM")
	Dim mi As MenuItem
	mi.Initialize("Remove","removeFileMi")
	Dim mi2 As MenuItem
	mi2.Initialize("Import from review","importReviewMi")
	Dim mi3 As MenuItem
	mi3.Initialize("docx for review","exportReviewMi")
	Dim mi4 As MenuItem
	mi4.Initialize("bi-paragraphs","exportBiParagraphMi")
	Dim mi5 As MenuItem
	mi5.Initialize("markdown with notes","exportMarkdownWithNotesMi")
	
	Dim exportMenu As Menu
	exportMenu.Initialize("Export to","")
	exportMenu.MenuItems.Add(mi3)
	exportMenu.MenuItems.Add(mi4)
	exportMenu.MenuItems.Add(mi5)
	
	Dim mi6 As MenuItem
	mi6.Initialize("Update with existing workfile","updateWithWorkfileMi")
	Dim mi7 As MenuItem
	mi7.Initialize("Generate target file","generateTargetFileMi")
	
	fileCM.MenuItems.Add(mi)
	fileCM.MenuItems.Add(mi2)
	fileCM.MenuItems.Add(exportMenu)
	fileCM.MenuItems.Add(mi6)
	fileCM.MenuItems.Add(mi7)
	
	lbl.ContextMenu=fileCM
	
	tti.Initialize("tti",Array As Object(lbl))
	mi.Tag=tti
	mi2.Tag=filename
	mi3.Tag=filename
	mi4.Tag=filename
	mi5.Tag=filename
	mi6.Tag=filename
	mi7.Tag=filename
	subTreeTableItem.Children.Add(tti)
End Sub

Sub showPreView
	If Main.pre.IsInitialized And Main.pre.isShowing Then
		Main.pre.loadText
	End If
End Sub

Sub createProjectFiles
	Dim dirList As List
	dirList.Initialize
	dirList.Add("")
	dirList.Add("source")
	dirList.Add("work")
	dirList.Add("target")
	dirList.Add("TM")
	dirList.Add("Term")
	dirList.Add("History")
	dirList.Add("bak")
	dirList.Add("config")
	For Each dirname As String In dirList
		If File.Exists(path,dirname)=False Then
			Log(dirname)
			File.MakeDir(path,dirname)
		End If
	Next
	Dim configPath As String=File.Combine(path,"config")
	Dim configsList As List
	configsList.Initialize
	configsList.Add("segmentationRules.srx")
	configsList.Add("dictList.txt")
	For Each filename As String In configsList
		If File.Exists(configPath,filename)=False Then
			File.Copy(File.DirAssets,filename,configPath,filename)
		End If
	Next
End Sub

Sub getProjectPath(jsonPath As String) As String
	Dim ProjectPath As String
	Try
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("\"))
	Catch
		ProjectPath=jsonPath.SubString2(0,jsonPath.LastIndexOf("/"))
		Log(LastException)
	End Try
	Return ProjectPath
End Sub


'project action end
'--------------------
'git relevant

Sub gitcommit(local As Boolean,isSaving As Boolean) As Boolean
	Dim configured As Boolean=False
	If Main.preferencesMap.ContainsKey("vcsEnabled") Then
		If Main.preferencesMap.Get("vcsEnabled")=True Then
			configured=True
			If isSaving Then
				If settings.GetDefault("save_and_commit",False) Then
					If settings.GetDefault("git_enabled",False) And local=False Then
						commitAndPush("")
					Else
						gitcommitLocal("")
					End If
				End If
			Else
				If local Then
					gitcommitLocal("")
				Else
					commitAndPush("")
				End If
			End If

		End If
	End If
	Return configured
End Sub

Public Sub gitinit
	createGitignore
	If projectGit.IsInitialized=False Then
		projectGit.Initialize(path)
	End If
End Sub

Public Sub setGitRemoteAndPush(uri As String)
	gitinit
	setGitRemote(uri)
	initAndPush
End Sub

Public Sub setGitRemote(uri As String)
	gitinit
	projectGit.addRemote(uri,"origin")
End Sub

Public Sub getGitRemote As String
	gitinit
	Return projectGit.getRemoteUri
End Sub

Public Sub gitcommitLocal(commitMessage As String)
	gitinit
	If commitMessage="" Then
		commitMessage="new text change"
	End If
	Dim username,email As String
	If Main.preferencesMap.ContainsKey("vcs_email") Then
		email=Main.preferencesMap.Get("vcs_email")
	End If
	If Main.preferencesMap.ContainsKey("vcs_username") Then
		username=Main.preferencesMap.Get("vcs_username")
	End If
	Dim diffList As List
	diffList=projectGit.diffList
	Log(diffList)
	If diffList<>Null And diffList.Size<>0 Then
		projectGit.add(".")
		projectGit.commit(commitMessage,username,email)
	End If
End Sub

Sub createGitignore
	If File.Exists(path,".gitignore")=False Then
		File.Copy(File.DirAssets,".gitignore",path,".gitignore")
	End If
End Sub

Public Sub initAndPush
	gitcommitLocal("init")
	Dim password,username As String
	If Main.preferencesMap.ContainsKey("vcs_password") Then
		password=Main.preferencesMap.Get("vcs_password")
	End If
	If Main.preferencesMap.ContainsKey("vcs_username") Then
		username=Main.preferencesMap.Get("vcs_username")
	End If
	If password="" Or username="" Then
		fx.Msgbox(Main.MainForm,"Please configure your git account info first.","")
		Return
	End If
	wait for (projectGit.pushAsync(username,password,"origin","master")) complete (result As Boolean)
	If result=False Then
		fx.Msgbox(Main.MainForm,"Push Failed","")
	End If
End Sub

Public Sub commitAndPush(commitMessage As String)
	gitinit

	Dim username,email,password As String
	If Main.preferencesMap.ContainsKey("vcs_email") Then
		email=Main.preferencesMap.Get("vcs_email")
	End If
	If Main.preferencesMap.ContainsKey("vcs_username") Then
		username=Main.preferencesMap.Get("vcs_username")
	End If
	If Main.preferencesMap.ContainsKey("vcs_password") Then
		password=Main.preferencesMap.Get("vcs_password")
	End If
	If email="" Or username="" Or password="" Then
		fx.Msgbox(Main.MainForm,"Please configure your git account info first.","")
		Return
	End If
	If getGitRemote="" Then
		fx.Msgbox(Main.MainForm,"Please configure git remote first.","")
		Return
	End If

	
	If commitMessage="" Then
		commitMessage="new translation"
	End If
	
	Main.enableAutosaveTimer(False)
	Main.updateOperation("commiting and pushing")
	Sleep(0)

	If projectGit.isConflicting Then
		Log("conflicting")
		Dim filename As String=projectGit.conflictsUnSolvedFilename(path)
		If filename<>"conflictsSolved" Then
			fx.Msgbox(Main.MainForm,filename&" still contains conflicts.","")
			Return
		Else
			projectGit.add(".")
			projectGit.rebase("CONTINUE","")
			wait for (projectGit.pushAsync(username,password,"origin","master")) complete (pushResult As Boolean)
			If pushResult=False Then
				fx.Msgbox(Main.MainForm,"Failed","")
				Return
			End If
		End If
	Else
		wait for (updateLocalFileBasedonFetch(username,password,email)) Complete (success as Object)
		Dim diffList As List
		diffList=projectGit.diffList
		Log(diffList)
		If diffList<>Null And diffList.Size<>0 Then
			projectGit.add(".")
			projectGit.commit(commitMessage,username,email)
		End If
		
		wait for (samelocalHeadAndRemoteHead(username,password,False)) Complete (isSame As Boolean)
		If isSame = False Then
			
			Dim rebaseResult As String
			rebaseResult=projectGit.pullRebase(username,password)
			Log("rebaseResult"&rebaseResult)
			If rebaseResult="STOPPED" Or rebaseResult="CONFLICTS" Then
				fx.Msgbox(Main.MainForm,"Conflits exist. Please solve the conflicts first.","")
				closeFile
				Return
			Else
				wait for (projectGit.pushAsync(username,password,"origin","master")) complete (pushResult As Boolean)
				If pushResult=False Then
					fx.Msgbox(Main.MainForm,"Push Failed","")
					Return
				End If
			End If
		End If
	End If
	checkWorkfile
	Main.enableAutosaveTimer(True)
	Main.updateOperation("committed")
End Sub

Sub samelocalHeadAndRemoteHead(username As String,password As String,fetch As Boolean) As ResumableSub
	Dim result As Boolean=True
	Dim refsPath As String
	refsPath=File.Combine(File.Combine(path,".git"),"refs")
	If File.Exists(refsPath,"remotes") Then
		Dim previousRemoteHead As String
		previousRemoteHead=projectGit.getCommitIDofBranch("refs/remotes/origin/master")
		If fetch Then
			wait for (projectGit.fetchAsync(username,password)) Complete (success As Object)
		End If
		Dim localHead,remoteHead As String
		localHead=projectGit.getCommitIDofBranch("refs/heads/master")
		remoteHead=projectGit.getCommitIDofBranch("refs/remotes/origin/master")
		If localHead<>remoteHead Then
			result=False
		End If
		If fetch Then
			If previousRemoteHead=remoteHead Then
				result = True
			End If
		End If
	Else
		result=False
	End If
	Return result
End Sub

Sub updateLocalFileBasedonFetch(username As String,password As String,email As String)  as ResumableSub
	wait for (samelocalHeadAndRemoteHead(username,password,True)) Complete (isSame As Boolean)
	If isSame = False Then
		Dim localHead,remoteHead As String
		localHead=projectGit.getCommitIDofBranch("refs/heads/master")
		remoteHead=projectGit.getCommitIDofBranch("refs/remotes/origin/master")
		Log("remotelyChanged")
		If File.Exists(path,"tmp") Then
			FileUtils.Delete(path,"tmp")
		End If
		File.MakeDir(path,"tmp")

		projectGit.setWorkdir(File.Combine(path,"tmp"))
		projectGit.Initialize(path)
		projectGit.checkoutAllFiles("master","origin/master")
		projectGit.rebase("","origin/master")
		
		projectGit.unsetWorkdir
		projectGit.Initialize(path)
		
		Dim diffList As List
		diffList=projectGit.diffListBetweenBranches(localHead,remoteHead)
		Log(diffList)
		
		projectGit.setWorkdir(File.Combine(path,"tmp"))
		projectGit.Initialize(path)
		
		Log("worddir,before: "&projectGit.getWorkdirPath)
		Dim needsPushList As List
		needsPushList.Initialize
		
		For Each filename As String In diffList
			Log(filename&" changed")
			If File.Exists(path,filename) Then
				If filename.StartsWith("work") And filename.EndsWith(".json") Then
					Dim pureFilename As String
					pureFilename=Utils.replaceOnce(filename,"work/","")
					pureFilename=Utils.replaceOnceFromTheEnd(pureFilename,".json","")
					If updateWorkFile(pureFilename) Then
						needsPushList.Add(filename)
					End If
				End If
			End If
		Next
		Log(needsPushList)
		If needsPushList.Size<>0 Then
			Dim diffList As List
			diffList=projectGit.diffList
			Log("sync")
			Log(diffList)
			If diffList<>Null And diffList.Size<>0 Then
				projectGit.add(".")
				projectGit.commit("sync",username,email)
			End If
			wait for (projectGit.pushAsync(username,password,"origin","master")) complete (result As Boolean)
			Log("pushresult"&result)
		End If
		projectGit.unsetWorkdir
		projectGit.Initialize(path)
	End If

	Log("worddir,after: "&projectGit.getWorkdirPath)
End Sub

Sub updateWorkFile(filename As String) As Boolean
	Dim needsPush As Boolean=False
	Dim localFileSegments,remoteFileSegments As List
	localFileSegments.Initialize
	remoteFileSegments.Initialize
	readWorkFile(filename,localFileSegments,False,path)
	readWorkFile(filename,remoteFileSegments,False,File.Combine(path,"tmp"))
	If localFileSegments.Size<>remoteFileSegments.Size Then
		Return needsPush
	End If
	Dim size As Int=localFileSegments.Size
	For i=0 To size-1
		Dim localSegment,remoteSegment As List
		localSegment=localFileSegments.Get(i)
		remoteSegment=remoteFileSegments.Get(i)
		If localSegment.Get(0)=remoteSegment.Get(0) And localSegment.Get(1)<>remoteSegment.Get(1) Then
			Dim localExtra,remoteExtra As Map
			localExtra=localSegment.Get(4)
			remoteExtra=remoteSegment.Get(4)
			Dim localCreatedTime,remoteCreatedTime As Long
			localCreatedTime=localExtra.GetDefault("createdTime",0)
			remoteCreatedTime=remoteExtra.GetDefault("createdTime",0)
			Log(localCreatedTime)
			Log(remoteCreatedTime)
			If remoteCreatedTime>localCreatedTime Then
				localSegment.Set(1,remoteSegment.Get(1))
				localSegment.Set(4,remoteExtra)
				If filename=currentFilename Then
					Dim segment As List 'also need to set the clv and segment
					segment=segments.Get(i)
					segment.Set(1,remoteSegment.Get(1))
					segment.Set(4,remoteExtra)
					fillOne(i,remoteSegment.Get(1))
				End If
			else if remoteCreatedTime<localCreatedTime Then
				needsPush=True
				remoteSegment.Set(1,localSegment.Get(1))
				remoteSegment.Set(4,localExtra)
			End If
		End If
	Next
	saveWorkFile(filename,localFileSegments,path)
	saveWorkFile(filename,remoteFileSegments,File.Combine(path,"tmp"))
	Return needsPush
End Sub

Sub checkWorkfile
	If segments.Size<>0 Then
		Dim filesegments As List
		filesegments.Initialize
		readWorkFile(currentFilename,filesegments,False,path)
		If filesegments.Size<>segments.Size Then
		    Dim result As Int
			result=fx.Msgbox2(Main.MainForm,"Someone has merged or splitted segments of current file. Reopen it?","","Reopen","","No",fx.MSGBOX_CONFIRMATION)
			Select result
				Case fx.DialogResponse.POSITIVE
			        openFile(currentFilename,True)
			End Select
		End If
	End If
End Sub

'git end
'-------------------
'ui relevant


Sub lbl_MouseClicked (EventData As MouseEvent)
	If EventData.PrimaryButtonPressed Then
		Dim lbl As Label
		lbl=Sender
		Log("file changed"&lbl.Text)
		Dim filename As String
		filename=lbl.text
		If currentFilename<>filename Then
			openFile(filename,False)
		End If
	End If
End Sub

Sub exportReviewMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("docx files",Array As String("*.docx"))
	fc.InitialFileName=filename&".docx"
	Dim exportPath As String
	exportPath=fc.ShowSave(Main.MainForm)
	If exportPath="" Then
		Return
	End If

	Dim rows As List
	rows.Initialize
	For Each bitext As List In getAllSegments(filename)
		Dim target As String=bitext.Get(1)
		Dim extra As Map
		extra=bitext.Get(4)
		If extra.ContainsKey("note") Then
			target=target&"  --------note: "&extra.Get("note")
		End If
		rows.Add(Array As String(bitext.Get(0),target))
	Next
	Dim poiw As POIWord
	poiw.Initialize("","write")
	poiw.createTable(rows,exportPath)
	fx.Msgbox(Main.MainForm,"Done.","")
End Sub

Sub exportMarkdownWithNotesMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	If currentFilename<>filename Then
		fx.Msgbox(Main.MainForm,"Please first open this file.","")
		Return
	End If
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("Markdown",Array As String("*.md"))
	Dim exportPath As String
	exportPath=fc.ShowSave(Main.MainForm)
	If exportPath<>"" Then
		Utils.exportToMarkdownWithNotes(segments,exportPath,currentFilename,projectFile.Get("source"),projectFile.Get("target"),settings,path)
		fx.Msgbox(Main.MainForm,"Done.","")
	End If
End Sub

Sub exportBiParagraphMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	If currentFilename<>filename Then
		fx.Msgbox(Main.MainForm,"Please first open this file.","")
		Return
	End If
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("TXT",Array As String("*.txt"))
	Dim exportPath As String
	exportPath=fc.ShowSave(Main.MainForm)
	If exportPath<>"" Then
		Utils.exportToBiParagraph(segments,exportPath,currentFilename,projectFile.Get("source"),projectFile.Get("target"),settings,path)
		fx.Msgbox(Main.MainForm,"Done.","")
	End If
End Sub

Sub importReviewMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	If currentFilename<>filename Then
		fx.Msgbox(Main.MainForm,"Please first open this file.","")
		Return
	End If
	Dim rows As List
	Dim reviewFilePath As String
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("Word Files",Array As String("*.docx"))
	reviewFilePath=fc.ShowOpen(Main.MainForm)
	If reviewFilePath<>"" Then
		Dim poiw As POIWord
		poiw.Initialize(reviewFilePath,"read")
		rows=poiw.readTable
		Dim crDialog As confirmReviewDialog
		If rows.Size<>segments.Size Then
			fx.Msgbox(Main.MainForm,"Unmatched segments size.","")
			Return
		End If
		crDialog.Initialize(rows,Me)
		crDialog.ShowAndWait
	End If

End Sub

Sub updateWithWorkfileMI_Action
	Dim mi As MenuItem=Sender
	Dim selectedFilename As String=mi.tag
	If selectedFilename<>currentFilename Then
		fx.Msgbox(Main.MainForm,"Please first open this file","")
		Return
	End If
	
	Dim fc As FileChooser
	fc.Initialize
	fc.SetExtensionFilter("workfile",Array("*.json"))
	Dim workFilePath As String
	workFilePath=fc.ShowOpen(Main.MainForm)
	If workFilePath="" Then
		Return
	End If

	Dim fileSegments As List
	fileSegments.Initialize
	
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(workFilePath,""))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim innerFilename As String
		innerFilename=sourceFileMap.GetKeyAt(0)
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		fileSegments.AddAll(segmentsList)
	Next

	Dim sourceMap As Map
	sourceMap.Initialize
	For Each segment As List In fileSegments
		Dim source As String
		source=segment.Get(0)
		sourceMap.Put(source,segment)
	Next
	
	progressDialog.Show("Updating","update")
    Dim size As Int=segments.Size
	Dim index As Int
	progressDialog.update(index,size)
	Sleep(0)
	For Each segment As List In segments
		index=index+1
		progressDialog.update(index,size)
		Dim source As String
		source=segment.Get(0)
		If sourceMap.ContainsKey(source) Then
			Dim segmentFromWorkfile As List
			segmentFromWorkfile=sourceMap.Get(source)
			Dim extra As Map
			extra=segment.Get(4)
			Dim extraFromWorkfile As Map
			extraFromWorkfile=segmentFromWorkfile.Get(4)
			If extraFromWorkfile.GetDefault("createdTime",0)>=extra.GetDefault("createdTime",0) Then
				segment.Clear
				segment.AddAll(segmentFromWorkfile)
			End If
		End If
	Next
	progressDialog.close
	refillVisiblePane
	contentIsChanged
	fx.Msgbox(Main.MainForm,"Done","")
End Sub

Sub generateTargetFileMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim filename As String
	filename=mi.Tag
	generateTargetFileForOne(filename)
End Sub

Sub removeFileMi_Action
	Dim mi As MenuItem
	mi=Sender
	Dim tti As TreeTableItem
	Dim subTreeTableItem As TreeTableItem
	subTreeTableItem=Main.projectTreeTableView.Root.Children.Get(0)
	tti=mi.Tag
	Dim lbl As Label
	lbl=tti.GetValue(0)
	Dim filename As String
	filename=lbl.Text
	Dim result As Int
	result=fx.Msgbox2(Main.MainForm,"Remove corresponding translation memories?","","Yes","Cancel","No",fx.MSGBOX_CONFIRMATION)
	Log(result)
	'yes -1, no -2, cancel -3
	If result=-3 Then
		Return
	End If 
	If currentFilename=filename Then
		Main.editorLV.Items.Clear
		segments.Clear
		currentFilename=""
	End If
	If result=-1 Then
		For Each bitext As List In getAllSegments(filename)
			projectTM.translationMemory.Remove(bitext.Get(0))
		Next
	End If

	subTreeTableItem.Children.RemoveAt(subTreeTableItem.Children.IndexOf(mi.Tag))
	files.RemoveAt(files.IndexOf(filename))
	Dim okapiExtractedFiles As List
	If projectFile.ContainsKey("okapiExtractedFiles") Then
		okapiExtractedFiles=projectFile.Get("okapiExtractedFiles")
		Dim index As Int = okapiExtractedFiles.IndexOf(filename)
		If index<>-1 Then
			okapiExtractedFiles.RemoveAt(index)
		End If
	End If
	filename=filename.Replace("/",GetSystemProperty("file.separator","/"))
	File.Delete(File.Combine(path,"source"),filename)
	Try
		File.Delete(File.Combine(path,"work"),filename&".json")
	Catch
		Log(LastException)
	End Try
	save
	fx.Msgbox(Main.MainForm,"Done","")
End Sub

Sub targetTextArea_TextChanged (Old As String, New As String)
	If Old<>New  Then
		If Old="" And New.Length<=1 Then
			contentIsChanged
		End If
		If Old<>"" Then
			contentIsChanged
		End If
	End If
	
	If Old="" And New.Length>1 Then
		Return
	End If
	If New.Contains(CRLF) Or Old.Contains(CRLF) Then
		Return
	End If
	
	Dim ta As TextArea
	ta=Sender
	
	'-----autocorrect
	Dim autocorrectList As List
	autocorrectList.Initialize
	If settings.ContainsKey("autocorrect_enabled") Then
		If settings.Get("autocorrect_enabled")=True Then
			If settings.ContainsKey("autocorrect") Then
				autocorrectList=settings.Get("autocorrect")
			End If
		End If
	End If
	
	If New.Length>Old.Length And autocorrectList.Size<>0 Then
		Dim corrected As Boolean=False
		For Each item As List In autocorrectList
			If corrected=True Then
				Exit
			End If
			Dim match As String
			Dim before As String=item.Get(0)
			Dim after As String=item.Get(1)
			If ta.SelectionEnd-before.Length>=0 Then
				match=ta.Text.SubString2(ta.SelectionEnd-before.Length,ta.SelectionEnd)
				If match=before Then
					Dim selection As Int=ta.SelectionEnd
					ta.Text=ta.Text.SubString2(0,ta.SelectionEnd-before.Length)&after&ta.Text.SubString2(ta.SelectionEnd,ta.Text.Length)
					ta.SetSelection(selection+after.Length,selection+after.Length)
					corrected=True
				End If
			End If
		Next
	End If
	

	
	Old=Old.SubString2(0,Min(ta.SelectionStart,Old.Length))
	New=New.SubString2(0,Min(ta.SelectionStart,New.Length))
	Dim lastString As String
	If New.Length>1 Then
		lastString=New.CharAt(New.Length-1)
	Else
		lastString=New
	End If

	If Utils.LanguageHasSpace(projectFile.Get("target"))=False Then
		Old=Regex.Replace("[a-zA-Z]|[^\u4e00-\u9fa5]",Old,"")
		New=Regex.Replace("[a-zA-Z]|[^\u4e00-\u9fa5]",New,"")
		If New.Length>Old.Length Then
			lastString=New.Replace(Old,"")
		End If
	Else
		Dim wordList As List
		wordList.Initialize
		wordList.AddAll(Regex.Split(" ",New))
		If wordList.Size<>0 Then
			lastString=wordList.Get(wordList.Size-1)
		End If
	End If
	'Log("old"&Old)
	'Log("last"&lastString)




	If cmClicked=True Then
		cmClicked=False
	Else
		If Utils.isList(ta.Tag) Then
			cm.MenuItems.Clear
			Sleep(0)
			Dim segmentsList As List
			segmentsList=ta.Tag
			Dim maxSuggestionNum As Int=5
			If Main.preferencesMap.ContainsKey("maxSuggestionNum") Then
				maxSuggestionNum=Main.preferencesMap.Get("maxSuggestionNum")
			End If
			Dim num As Int=0
			For Each text As String In segmentsList
				If text.ToLowerCase.StartsWith(lastString.ToLowerCase) And text<>lastString Then
					num=num+1
					If text.StartsWith(lastString) Then
						Dim mi As MenuItem
						mi.Initialize(text, "mi")
						mi.Tag=lastString
						cm.MenuItems.Add(mi)
					Else
						Dim mi As MenuItem
						mi.Initialize(text.ToLowerCase, "mi")
						mi.Tag=lastString
						cm.MenuItems.Add(mi)
					End If
				End If
				If num=maxSuggestionNum Then
					Exit
				End If
			Next
			If cm.MenuItems.Size<>0 Then
				Dim map1 As Map
				map1=Utils.GetScreenPosition(ta)
				Log(map1)
				Dim jo As JavaObject = cm
				jo.RunMethod("show", Array(ta, map1.Get("x")+ta.Width/10, map1.Get("y")+ta.Height))
			End If
		End If
	End If
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub sourceTextArea_TextChanged (Old As String, New As String)
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub segmentPane_MouseClicked (EventData As MouseEvent)
	lastEntry=Main.editorLV.Items.IndexOf(Sender)
	Log(lastEntry)
End Sub

Public Sub createEmptyPane As Pane
	Dim segmentPane As Pane
	segmentPane.Initialize("segmentPane")
	segmentPane.SetSize(Main.editorLV.Width,50dip)
	Return segmentPane
End Sub

Public Sub addTextAreaToSegmentPane(segmentpane As Pane,source As String,target As String)
	segmentpane.LoadLayout("segment")
	segmentpane.SetSize(Main.editorLV.Width,50dip)
	Dim sourceTextArea As TextArea
	sourceTextArea=segmentpane.GetNode(0)
	sourceTextArea.Text=source

	'sourceTextArea.Style = "-fx-font-family: Tahoma;"
	Main.setTextAreaFont(sourceTextArea,"sourceFont")
	addKeyEvent(sourceTextArea,"sourceTextArea")
	addSelectionChangedEvent(sourceTextArea,"sourceTextAreaSelection")
	Dim targetTextArea As TextArea
	targetTextArea=segmentpane.GetNode(1)
	targetTextArea.Text=target

	'targetTextArea.Style = "-fx-font-family: Arial Unicode MS;"
	Main.setTextAreaFont(targetTextArea,"targetFont")
	addKeyEvent(targetTextArea,"targetTextArea")
	addSelectionChangedEvent(targetTextArea,"targetTextAreaSelection")
	
	sourceTextArea.Left=0
	sourceTextArea.SetSize(Main.editorLV.Width/2-20dip,50dip)
	targetTextArea.Left=sourceTextArea.Left+sourceTextArea.Width
	targetTextArea.SetSize(Main.editorLV.Width/2-20dip,50dip)
End Sub

Sub addKeyEvent(textarea1 As TextArea,eventName As String)
	Dim CJO As JavaObject = textarea1
	Dim O As Object = CJO.CreateEventFromUI("javafx.event.EventHandler",eventName&"_KeyPressed",Null)
	CJO.RunMethod("setOnKeyPressed",Array(O))
	CJO.RunMethod("setFocusTraversable",Array(True))
End Sub

Sub addSelectionChangedEvent(textarea1 As TextArea,eventName As String)
	Dim Obj As Reflector
	Obj.Target = textarea1
	Obj.AddChangeListener(eventName, "selectionProperty")
	
End Sub

Sub sourceTextAreaSelection_changed(old As Object, new As Object)

	Dim ta As TextArea
	ta=Sender
	onSelectionChanged(new,ta,True)
End Sub

Sub targetTextAreaSelection_changed(old As Object, new As Object)
	cursorReachEnd=False
    Log(old)
	Log(new)
	Dim ta As TextArea
	ta=Sender
    onSelectionChanged(new,ta,False)

End Sub

Sub onSelectionChanged(new As Object,ta As TextArea,isSource As Boolean)
	
	Dim indexString As String
	indexString=new
	Dim selectionStart,selectionEnd As Int
	selectionStart=Regex.Split(",",indexString)(0)
	selectionEnd=Regex.Split(",",indexString)(1)
	Dim selectedText As String
	If selectionEnd<>selectionStart Then
		selectedText=ta.Text.SubString2(selectionStart,selectionEnd)
		If isSource Then
		    Main.sourceTermTextField.Text=selectedText
		Else
			Main.targetTermTextField1.Text=selectedText
		End If
	Else
		Return
	End If
	'---------------------- add term
	
	Dim index As Int
	If isSource Then
		index=0
		If cmClicked=True Then
			cmClicked=False
		Else
			cm.MenuItems.Clear
			wait for (getMeans(selectedText)) complete (result As List)
			For Each text As String In result
				Dim mi As MenuItem
				mi.Initialize(text, "mi")
				cm.MenuItems.Add(mi)
			Next
			Sleep(100)
			Dim jo As JavaObject = cm
			jo.RunMethod("show", Array(ta, Main.getLeft, Main.getTop))
		End If
		
	Else
		index=1
	End If
	'------------------ show word meaning
	If Main.TabPane1.SelectedIndex=1 Then
		
		
		If Utils.LanguageHasSpace(projectFile.Get("source"))=True And isSource=True Then
			If selectionEnd<>ta.Text.Length Then
				Dim lastChar As String
				lastChar=ta.Text.SubString2(selectionEnd,Min(ta.Text.Length,selectionEnd+1))
				If Regex.IsMatch("\s|,|\.|\!|\?|"&Chr(34),lastChar)=False Then
					Return
				End If
			End If
		End If
		If Utils.LanguageHasSpace(projectFile.Get("target"))=True And isSource=False Then
			If selectionEnd<>ta.Text.Length Then
				Dim lastChar As String
				lastChar=ta.Text.SubString2(selectionEnd,Min(ta.Text.Length,selectionEnd+1))
				If Regex.IsMatch("\s|,|\.|\!|\?|"&Chr(34),lastChar)=False Then
					Return
				End If
			End If
		End If
		
		Main.searchTableView.Items.Clear
		Main.searchTableView.Tag=selectedText
		Dim result As List
		result.Initialize
		
		For i=0 To segments.Size-1
			Dim segment1 As List
			segment1=segments.Get(i) 
			Dim newsegment As List 'avoid affecting segments
			newsegment.Initialize
			newsegment.AddAll(segment1)
			Dim content As String
			content=newsegment.Get(index)
			newsegment.Add(i)
			If content.Contains(selectedText) And content<>ta.Text Then
				result.Add(newsegment)
			End If
		Next
		For Each segment As List In result
			Dim row()  As Object = Array As String(segment.Get(5),segment.Get(0),segment.Get(1))
			Main.searchTableView.Items.Add(row)
		Next
		Main.changeWhenSegmentOrSelectionChanges
	End If
	'---------- show segment search
End Sub

Sub mi_Action
	cmClicked=True
	Dim mi As MenuItem
	mi=Sender
	Try
		Dim p As Pane
		p=Main.editorLV.Items.Get(lastEntry)
		Dim targetTextArea As TextArea
		targetTextArea=p.GetNode(1)
		targetTextArea.Text=targetTextArea.Text.SubString2(0,targetTextArea.SelectionStart)&Utils.replaceOnce(mi.Text,mi.Tag,"")&targetTextArea.Text.SubString2(targetTextArea.SelectionStart,targetTextArea.Text.Length)
		Sleep(0)
		targetTextArea.SetSelection(targetTextArea.Text.Length,targetTextArea.Text.Length)
	Catch
		Log(LastException)
	End Try
	
End Sub

Sub sourceTextArea_MouseClicked (EventData As MouseEvent)
	Dim ta As TextArea
	ta=Sender
	lastEntry=Main.editorLV.Items.IndexOf(ta.Parent)
	If ta.SelectionEnd=ta.SelectionStart Then
		Dim jo As JavaObject = cm
		jo.RunMethod("hide", Null)
	End If
End Sub


Sub sourceTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim sourceTextArea As TextArea
	sourceTextArea=Sender

	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	Log(result)
    If result="ENTER" Then
		If SegEnabledFiles.IndexOf(currentFilename)<>-1 Then
			fx.Msgbox(Main.MainForm,"This file does not support spliting and merging segments","")
			Return Null
		End If
		contentIsChanged
		Dim filenameLowercase As String
		filenameLowercase=currentFilename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") Then
			txtFilter.splitSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".idml") Then
			idmlFilter.splitSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff") Then
			xliffFilter.splitSegment(sourceTextArea)
		Else
			Dim params As Map
			params.Initialize
			params.Put("main",Main)
			params.Put("sourceTextArea",sourceTextArea)
			params.Put("editorLV",Main.editorLV)
			params.Put("segments",segments)
			params.Put("projectFile",projectFile)
			runFilterPluginAccordingToExtension(currentFilename,"splitSegment",params)
		End If
	Else if result="DELETE" Then
		If SegEnabledFiles.IndexOf(currentFilename)<>-1 Then
			fx.Msgbox(Main.MainForm,"This file does not support spliting and merging segments","")
			Return Null
		End If
		contentIsChanged
		Dim filenameLowercase As String
		filenameLowercase=currentFilename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") Then
			txtFilter.mergeSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".idml") Then
			idmlFilter.mergeSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff") Then
			xliffFilter.mergeSegment(sourceTextArea)
		Else
			Dim params As Map
			params.Initialize
			params.Put("MainForm",Main.MainForm)
			params.Put("sourceTextArea",sourceTextArea)
			params.Put("editorLV",Main.editorLV)
			params.Put("segments",segments)
			params.Put("projectFile",projectFile)
			runFilterPluginAccordingToExtension(currentFilename,"mergeSegment",params)
		End If
	End If
End Sub

Sub targetTextArea_KeyPressed_Event (MethodName As String, Args() As Object) As Object
	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	Log(result)
	Dim targetTextArea As TextArea
	targetTextArea=Sender
	If result="ENTER" Then
		changeSegment(1,targetTextArea)
	Else if result="DOWN" Then
		If 	cursorReachEnd=False Then
			cursorReachEnd=True
		Else
			changeSegment(1,targetTextArea)
		End If
	Else if result="UP" Then
		If 	cursorReachEnd=False Then
			cursorReachEnd=True
		Else
			changeSegment(-1,targetTextArea)
		End If
	End If
End Sub

Sub changeSegment(offset As Int,targetTextArea As TextArea)
	Try
		targetTextArea.Text=targetTextArea.Text.Replace(CRLF,"")
		saveTranslation(targetTextArea)
		Dim pane As Pane
		pane=targetTextArea.Parent
		Dim index As Int
		index=Main.editorLV.Items.IndexOf(pane)
		If index+offset>=Main.editorLV.Items.Size Or index+offset<0 Then
			Return
		End If
		Dim nextPane As Pane
		nextPane=Main.editorLV.Items.Get(index+offset)
		Dim nextTA As TextArea
		nextTA=nextPane.GetNode(1)
		nextTA.RequestFocus
		lastEntry=Main.editorLV.Items.IndexOf(nextPane)
		lastFilename=currentFilename
		showTM(nextTA)
		showTerm(nextTA)
		languagecheck(targetTextArea,index)
		Main.updateSegmentLabel(lastEntry,segments.Size)
		Dim visibleRange As Range
		visibleRange=Main.getVisibleRange(Main.editorLV)
		If index+offset<visibleRange.firstIndex+1 Or index+offset>visibleRange.lastIndex-1 Then
			If offset<0 Then
				Main.editorLV.ScrollTo(index+offset)
			Else
				Main.editorLV.ScrollTo(index+offset-visibleRange.lastIndex+visibleRange.firstIndex+1)
			End If
		End If
	Catch
		Log(LastException)
	End Try
	showPreView
End Sub

Sub sourceTextArea_FocusChanged (HasFocus As Boolean)
	Log(HasFocus)
	Dim TextArea1 As TextArea
	TextArea1=Sender
	If HasFocus Then
		TextArea1.Tag=TextArea1.Text
		TextArea1.Editable=True
	Else
		TextArea1.Text=TextArea1.Tag
		TextArea1.Editable=False
	End If
End Sub

Sub targetTextArea_FocusChanged (HasFocus As Boolean)
	Dim TextArea1 As TextArea
	TextArea1=Sender
	Sleep(0)
	If TextArea1.IsInitialized=False Then
		Log("Null,Textarea")
		Return
	End If
	If TextArea1.Parent.IsInitialized=False Then
		Log("Null,Textarea Parent")
		Return
	End If
	lastEntry=Main.editorLV.Items.IndexOf(TextArea1.Parent)
	lastFilename=currentFilename
	If HasFocus Then
		
        Log("hasFocus")
		Log(TextArea1.Text)
		'Log(previousEntry)
		'Log(lastEntry)
		showTM(TextArea1)
		showTerm(TextArea1)
		Main.updateSegmentLabel(Main.editorLV.Items.IndexOf(TextArea1.Parent),segments.Size)

	Else
		Log("loseFocus")
		'Log("previous"&previousEntry)
		'Log("lastentry"&lastEntry)
		Log(TextArea1.Text)
		If previousEntry<>lastEntry Then
			languagecheck(TextArea1,lastEntry)
		End If
		previousEntry=lastEntry
	End If
End Sub

Sub languagecheck(ta As TextArea,entry As Int)
	If Main.getCheckLVSize<=1 Then
		If Main.preferencesMap.ContainsKey("languagetoolEnabled") Then
			If Main.preferencesMap.Get("languagetoolEnabled")=True Then
				wait for (LanguageTool.check(ta.Text,entry,projectFile.Get("target"))) complete (result As List)
				showReplacements(result,ta)
			End If
		End If
	End If
End Sub

Sub showReplacements(values As List,ta As TextArea)
	If values.Size=0 Then
		Return
	End If
	
	Dim replacementsCM As ContextMenu
	replacementsCM.Initialize("replacementsCM")
	Dim replacements As List
	replacements=values.Get(2)
	'0 offset
	'1 length
	'2 replacements
	Dim maxCheckDropdownNum As Int=5
	If Main.preferencesMap.ContainsKey("maxCheckDropdownNum") Then
		maxCheckDropdownNum=Main.preferencesMap.Get("maxCheckDropdownNum")
	End If
	Dim num As Int=0
	For Each replace As Map In replacements
		Log(replace)
		num=num+1
		Dim mi As MenuItem
		mi.Initialize(replace.Get("value"), "replacementMi")
		Dim tagList As List
		tagList.Initialize
		tagList.AddAll(values)
		tagList.set(2,replace.Get("value"))
		mi.Tag=tagList
		replacementsCM.MenuItems.Add(mi)
		If num=maxCheckDropdownNum Then
			Exit
		End If
	Next
	Sleep(100)
	Dim map1 As Map
	map1=Utils.GetScreenPosition(ta)
	Log(map1)
	Dim jo As JavaObject = replacementsCM
	jo.RunMethod("show", Array(ta, map1.Get("x")+ta.Width/10, map1.Get("y")+ta.Height))
End Sub

Sub replacementMi_Action
	Try
		Dim mi As MenuItem
		mi=Sender
		Dim tagList As List
		tagList=mi.Tag
		Dim offset,length,thisPreviousEntry As Int
		offset=tagList.Get(0)
		length=tagList.Get(1)
		thisPreviousEntry=tagList.Get(3)
		Log(thisPreviousEntry)
		Dim replacement As String
		replacement=tagList.Get(2)
		Log(replacement)
		Dim p As Pane
		p=Main.editorLV.Items.Get(thisPreviousEntry)
		Dim targetTextArea As TextArea
		targetTextArea=p.GetNode(1)
		targetTextArea.Text=targetTextArea.Text.SubString2(0,offset)&replacement&targetTextArea.Text.SubString2(offset+length,targetTextArea.Text.Length)
		Sleep(0)
		targetTextArea.SetSelection(targetTextArea.Text.Length,targetTextArea.Text.Length)
		Main.checkLVClear
	Catch
		Log(LastException)
	End Try
End Sub

Sub loadITPSegments(targetTextArea As TextArea,engine As String,fullTranslation As String)
	If Main.preferencesMap.ContainsKey("autocompleteEnabled") Then
		If Main.preferencesMap.Get("autocompleteEnabled")=False Then
			Return
		End If
	Else
		Return
	End If
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Dim result As List
	result.Initialize
	wait for (ITP.getAllSegmentTranslation(sourceTA.Text,engine)) Complete (segmentTranslations As List)
	result.Add(fullTranslation)
	result.AddAll(segmentTranslations)
	If Utils.isList(targetTextArea.Tag) Then
		Dim list1 As List
		list1=targetTextArea.Tag
		list1.AddAll(result)
		targetTextArea.Tag=ITP.duplicatedRemovedList(list1)
	Else
		targetTextArea.Tag=result
	End If
End Sub

Sub showTM(targetTextArea As TextArea)
	Dim time As Long
	time=DateTime.Now
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Dim targetTA As TextArea
	targetTA=pane.GetNode(1)
	Log(sourceTA.Text)
	
	
	If projectTM.currentSource=sourceTA.Text Then 'avoid loading the same many times
		Return
	End If
	Main.tmTableView.Items.Clear
	Main.LogWebView.LoadHtml("")
	projectTM.currentSource=sourceTA.Text
	showMT(sourceTA.Text,targetTextArea)
	Dim senderFilter As Object = projectTM.getMatchList(sourceTA.Text)
	Wait For (senderFilter) Complete (Result As List)


    Dim index As Int=0
	For Each matchList As List In Result
        Dim note As String
		note=matchList.Get(3)
		Dim isExternal As Boolean=True
		If note.ToLowerCase.EndsWith(".txt")=False And note.ToLowerCase.EndsWith(".tmx")=False Then
			isExternal=False
		End If
		If matchList.Get(1)=sourceTA.Text And isExternal=False And targetTA.Text=matchList.Get(2) Then
			Continue 'itself
		End If
		Dim row()  As Object = Array As String(matchList.Get(0),matchList.Get(1),matchList.Get(2),matchList.Get(3))
        If index=0 Then
			Main.tmTableView.Items.InsertAt(0,row)
		    index=index+1
		Else
			Main.tmTableView.Items.Add(row)
        End If
		
		
	Next
	Log(DateTime.Now-time)
	

	
	Main.changeWhenSegmentOrSelectionChanges
	If Main.tmTableView.Items.Size<>0 Then
		Main.tmTableView.SelectedRow=0
	End If
End Sub

Sub showMT(source As String,targetTextArea As TextArea)
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return
	End If
	For Each engine As String In MT.getMTList
		If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
			wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),engine)) Complete (Result As String)
			If Result<>"" Then
				Dim row()  As Object = Array As String("","",Result,engine)
				Main.tmTableView.Items.Add(row)
				Main.changeWhenSegmentOrSelectionChanges
			End If
			loadITPSegments(targetTextArea,engine,Result)
		End If
	Next
End Sub

Sub getMeans(source As String) As ResumableSub
	Dim resultList As List
	resultList.Initialize
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return resultList
	End If
	
	

	
	If Main.preferencesMap.ContainsKey("lookupWord") Then
		If Main.preferencesMap.Get("lookupWord")=True Then
			Dim youdaoSetuped As Boolean=True
			If mtPreferences.ContainsKey("youdao") Then
				For Each param As String In Utils.getMap("youdao",mtPreferences).Values
					If param="" Then
						youdaoSetuped=False
					End If
				Next
			Else
				youdaoSetuped=False
			End If
			If youdaoSetuped=True Then
				wait for (MT.youdaoMT(source,projectFile.Get("source"),projectFile.Get("target"),True)) Complete (Result As List)
				resultList.AddAll(Result)
			End If
		End If
	End If

	If Main.preferencesMap.ContainsKey("lookupWordUsingMT") Then
		If Main.preferencesMap.Get("lookupWordUsingMT")=True Then
			For Each engine As String In MT.getMTList
				If engine="youdao" Then
					Continue
				End If
				If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
					wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),engine)) Complete (one As String)
					If one<>"" Then
						resultList.Add(one)
					End If
				End If
			Next
		End If
	End If

	
	
	Return resultList
End Sub

Sub showTerm(targetTextArea As TextArea)
	Main.termLV.Items.Clear
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As TextArea
	sourceTA=pane.GetNode(0)
	Dim terms As List
	terms=projectTerm.termsInASentence(sourceTA.Text)
	Main.termLV.Items.Clear
	For Each termList As List In terms
		Dim p As Pane
		p.Initialize("termpane")
		p.LoadLayout("oneterm")
		p.SetSize(Main.termLV.Width,50)
		p.Tag=termList.Get(1)
		Dim lbl1 As Label
		lbl1=p.GetNode(0)
		lbl1.Text=termList.Get(0)
		
		Dim lbl2 As Label
		lbl2=p.GetNode(1)
		lbl2.Text=termList.Get(1)
		Dim mi As MenuItem
		mi.Initialize("View Info","viewInfoMI")
		mi.Tag=termList
		Dim mi2 As MenuItem
		mi2.Initialize("View History","viewTermHistoryMI")
		mi2.Tag=termList.Get(0)
		Dim termCM As ContextMenu
		termCM.Initialize("termCM")
		termCM.MenuItems.Add(mi)
		termCM.MenuItems.Add(mi2)
		lbl2.ContextMenu=termCM
		
		Dim termInfo As Map
		termInfo=termList.Get(2)
		If termInfo.ContainsKey("description") Then 'description
			If termInfo.Get("description")<>"" Then
				lbl1.TooltipText=termInfo.Get("description")
				lbl2.TooltipText=termInfo.Get("description")
			End If

		End If
		Main.termLV.Items.Add(p)
	Next
End Sub

Sub viewTermHistoryMI_Action
	Dim mi As MenuItem
	mi=Sender
	Dim hisviewer As HistoryViewer
	hisviewer.Initialize
	hisviewer.Show(projectHistory.getTermHistory(mi.Tag))
End Sub

Sub viewInfoMI_Action
	Dim mi As MenuItem
	mi=Sender
	Dim termList As List
	termList=mi.Tag
	Dim terminfo As Map
	terminfo=termList.Get(2)
	Dim infoBuilder As StringBuilder
	infoBuilder.Initialize
	infoBuilder.Append("note: ").Append(terminfo.GetDefault("note","")).Append(CRLF)
	infoBuilder.Append("tag: ").Append(terminfo.GetDefault("tag","")).Append(CRLF)
	infoBuilder.Append("creator: ").Append(terminfo.GetDefault("creator","")).Append(CRLF)
	Dim createdTime As Long=terminfo.GetDefault("createdTime",0)
	Dim time As String
	time=DateTime.Date(createdTime)&" "&DateTime.Time(createdTime)
	infoBuilder.Append("createdTime: ").Append(time).Append(CRLF)
	fx.Msgbox(Main.MainForm,infoBuilder.ToString,"")
End Sub

Sub refillVisiblePane
	Dim visibleRange As Range
	visibleRange=Main.getVisibleRange(Main.editorLV)
	Dim ExtraSize As Int
	ExtraSize=15
	For i=Max(0,visibleRange.firstIndex-ExtraSize*2) To Min(Main.editorLV.Items.Size - 1,visibleRange.lastIndex+ExtraSize*2)
		Main.editorLV.Items.Set(i,"")
	Next
	fillPane(visibleRange.firstIndex,visibleRange.lastIndex)
End Sub

Public Sub fillPane(FirstIndex As Int, LastIndex As Int)
	Log("fillPane")
	If segments.Size=0 Then
		Return
	End If
	Dim ExtraSize As Int
	ExtraSize=15
	For i = Max(0,FirstIndex-ExtraSize*2) To Min(Main.editorLV.Items.Size - 1,LastIndex+ExtraSize*2)

		If i > FirstIndex - ExtraSize And i < LastIndex + ExtraSize Then
			'visible+
			If Main.editorLV.Items.Get(i)="" Then

				Dim segmentPane As Pane
				segmentPane=createEmptyPane
				
				Dim bitext As List
				bitext=segments.Get(i)

				addTextAreaToSegmentPane(segmentPane,bitext.Get(0),bitext.Get(1))
				Dim extra As Map
				extra=bitext.Get(4)
				setPaneStatus(extra,segmentPane)
				If Main.calculatedHeight.ContainsKey(bitext.Get(0)&"	"&bitext.Get(1)) Then
					Dim h As Int=Main.calculatedHeight.Get(bitext.Get(0)&"	"&bitext.Get(1))
					Main.setLayout(segmentPane,i,h)
				End If
				Main.editorLV.Items.Set(i,segmentPane)
			End If
		Else
			'not visible
			Main.editorLV.Items.Set(i,"")
		End If
	Next
End Sub

Sub preTranslate(options As Map)
	If options.Get("type")<>"" Then
		contentIsChanged
		completed=0
		Dim index As Int=-1
		progressDialog.Show("Pretranslating...","pretranslate")
		For Each bitext As List In segments
			Sleep(0)
			index=index+1
			Dim target As String
			target=bitext.Get(1)
			If target<>"" Then
				completed=completed+1
				progressDialog.update(completed,segments.Size)
				Continue
			End If
			
			Dim bitext As List
			bitext=segments.Get(index)
			
			If options.Get("type")="TM" Then
				If projectTM.ProjectMemorySize=0 Then
					progressDialog.close
					Return
				End If
				Dim resultList As List
				Log("rate"&options.Get("rate"))
				Wait For (projectTM.getOneUseMemory(bitext.Get(0),options.Get("rate"))) Complete (Result As List)
				resultList=Result
				If resultList.Size=0 Then
					completed=completed+1
					progressDialog.update(completed,segments.Size)
					Continue
				End If
				Dim similarity,matchrate As Double
				similarity=resultList.Get(0)
				matchrate=options.Get("rate")

				Log(bitext.Get(0))
				Log(similarity)
				Log(matchrate)
				Log(similarity>=matchrate)
				
				If similarity>=matchrate Then
					setTranslation(index,resultList.Get(2),True)
					'setSegment(bitext,index)
					fillOne(index,resultList.Get(2))
				End If
			Else if options.Get("type")="MT" Then
				wait for (MT.getMT(bitext.Get(0),projectFile.Get("source"),projectFile.Get("target"),options.Get("engine"))) Complete (translation As String)
				If translation<>"" Then
					setTranslation(index,translation,False)
					'setSegment(bitext,index)
					fillOne(index,translation)
				End If
			End If
				
			completed=completed+1

			progressDialog.update(completed,segments.Size)
			If completed>=segments.Size Then
				progressDialog.close
				fillVisibleTargetTextArea
				Return
			End If
		Next

		progressDialog.close
		fillVisibleTargetTextArea
	End If
End Sub

Sub fillOne(index As Int,translation As String)
	Try
		Dim p As Pane
		p=Main.editorLV.Items.Get(index)
		Dim targetTextArea As TextArea
		targetTextArea=p.GetNode(1)
		targetTextArea.Text=translation
		Dim bitext As List
		bitext=segments.Get(index)
		Dim extra As Map
		extra=bitext.Get(4)
		setPaneStatus(extra,p)
		contentIsChanged
	Catch
		Log(LastException)
	End Try
End Sub

Sub setPaneStatus(extra As Map,segmentPane As Pane)
	If extra.ContainsKey("neglected") Then
		If extra.Get("neglected")="yes" Then
			Utils.disableTextArea(segmentPane)
		End If
	End If
	If extra.ContainsKey("note") Then
		If extra.Get("note")<>"" Then
			CSSUtils.SetStyleProperty(segmentPane.GetNode(1),"-fx-background-color","green")
		End If
	End If
End Sub

Public Sub fillVisibleTargetTextArea
	Dim visibleRange As Range
	visibleRange=Main.getVisibleRange(Main.editorLV)
	Log("fill")
	For i=Max(0,visibleRange.firstIndex-15) To Min(Main.editorLV.Items.Size-1,visibleRange.lastIndex+14)
		Try
			Dim p As Pane
			p=Main.editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try
		Dim targetTextArea As TextArea
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=segments.Get(i)
		targetTextArea.Text=bitext.Get(1)
	Next
End Sub

'impl
'--------------------------

Public Sub setTranslation(index As String,translation As String,isFromTM As Boolean)
	If segments.Size=0 Then
		Return
	End If
	Dim bitext As List
	bitext=segments.Get(index)
	If translation<>bitext.Get(1) Then
		bitext.Set(1,translation)
		Dim time As Long
		time=DateTime.Now
		Dim extra As Map
		extra=bitext.Get(4)
		Dim creator As String
		If settings.GetDefault("sharingTM_enabled",False)=True Then
			creator=Main.preferencesMap.GetDefault("vcs_username","anonymous")
		Else
			If settings.GetDefault("git_enabled",False)=False Then
				creator=Main.preferencesMap.GetDefault("vcs_username","")
			Else
				creator=Main.preferencesMap.GetDefault("vcs_username","anonymous")
			End If
		End If
		If isFromTM Then
			Dim targetMap As Map
			targetMap.Initialize
			Dim source As String
			source=bitext.Get(0)
			If projectTM.translationMemory.ContainsKey(source) Then
				targetMap=projectTM.translationMemory.Get(source)
			Else if projectTM.externalTranslationMemory.ContainsKey(source) Then
				targetMap=projectTM.externalTranslationMemory.Get(source)
			End If
			If targetMap.ContainsKey("createdTime") Then
				Try
					time=targetMap.Get("createdTime")
				Catch
					Log(LastException)
				End Try
			End If
			If targetMap.ContainsKey("creator") Then
				creator=targetMap.Get("creator")
			End If
			If targetMap.ContainsKey("note") Then
				extra.Put("note",targetMap.Get("note"))
			End If
		End If
		extra.Put("createdTime",time)
		extra.Put("creator",creator)
	End If
End Sub

Sub saveOneTranslationToTM(bitext As List,index As Int)
	If bitext.Get(1)="" Or bitext.Get(0)=bitext.Get(1) Then
		Return
	End If
	Dim createdTime As Long
	Dim creator As String
	Dim extra As Map
	extra=bitext.Get(4)
	Try
		createdTime=extra.GetDefault("createdTime",0)
	Catch
		Log(LastException)
	End Try

	creator=extra.GetDefault("creator","anonymous")
	
	Dim targetMap As Map
	targetMap.Initialize
	targetMap.Put("text",bitext.Get(1))
	targetMap.Put("createdTime",createdTime)
	targetMap.Put("creator",creator)
	targetMap.Put("filename",currentFilename)
	targetMap.Put("index",index)
	targetMap.Put("note",extra.GetDefault("note",""))
	
	projectTM.addPair(bitext.Get(0),targetMap)
	If settings.GetDefault("record_history",True)=True Then
		projectHistory.addSegmentHistory(bitext.Get(0),targetMap)
	End If
End Sub

Public Sub saveAlltheTranslationToTM
	Dim index As Int=0
	For Each bitext As List In segments
		saveOneTranslationToTM(bitext,index)
		index=index+1
    Next
End Sub

Public Sub saveAlltheTranslationToSegmentsInVisibleArea(FirstIndex As Int, LastIndex As Int)
	For i=Max(0,FirstIndex) To Min(LastIndex,Main.editorLV.Items.Size-1)
		Dim targetTextArea As TextArea
		Try
			Dim p As Pane
			p=Main.editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try

		targetTextArea=p.GetNode(1)
		setTranslation(i,targetTextArea.Text,False)
		
		'projectTM.addPair(bitext.Get(0),bitext.Get(1))
	Next
End Sub

Sub saveTranslation(targetTextArea As TextArea)
	Dim index As Int
	index=Main.editorLV.Items.IndexOf(targetTextArea.Parent)
	Dim bitext As List
	bitext=segments.Get(index)
	setTranslation(index,targetTextArea.Text,False)
	If targetTextArea.Text<>"" Then
		saveOneTranslationToTM(bitext,index)
	End If
End Sub

Sub runFilterPluginAccordingToExtension(filename As String,task As String,params As Map) As ResumableSub
	Log(Main.plugin.GetAvailablePlugins)
	For Each pluginName As String In Main.plugin.GetAvailablePlugins
		If pluginName.EndsWith("Filter") Then
			Dim extension As String
			extension=pluginName.Replace("Filter","")
			Dim filenameLowercase As String
			filenameLowercase=filename.ToLowerCase
			If filenameLowercase.EndsWith(extension) Then
				Log(pluginName)
				Log(task)
				wait for (Main.plugin.RunPlugin(pluginName,task,params)) Complete (result As Object)
				Return result
			End If
		End If
	Next
	Return ""
End Sub

Sub createWorkFileAccordingToExtension(filename As String) As ResumableSub
	Dim result As Boolean=False
	Try
		Dim filenameLowercase As String
		filenameLowercase=filename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") Then
			wait for (txtFilter.createWorkFile(filename,path,projectFile.Get("source"))) Complete (result As Boolean)
		Else if filenameLowercase.EndsWith(".idml") Then
			wait for (idmlFilter.createWorkFile(filename,path,projectFile.Get("source"))) Complete (result As Boolean)
		Else if filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff") Then
			wait for (xliffFilter.createWorkFile(filename,path,projectFile.Get("source"))) Complete (result As Boolean)
		Else
			Dim params As Map
			params.Initialize
			params.Put("filename",filename)
			params.Put("path",path)
			params.Put("sourceLang",projectFile.Get("source"))
			wait for (runFilterPluginAccordingToExtension(filename,"createWorkFile",params)) Complete (result As Boolean)
		End If
		Return result
	Catch
		Log("creating workfile for "&filename&" failed")
		Log(LastException)
		Return False
	End Try
End Sub

Sub readWorkFile(filename As String,filesegments As List,fillUI As Boolean,root As String)
	If Utils.conflictsUnSolvedFilename(File.Combine(root,"work"),filename&".json")<>"conflictsSolved" Then
		fx.Msgbox(Main.MainForm,filename&" has unresolved conflicts.","")
		Return
	End If
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(root,"work"),filename&".json"))
	workfile=json.NextObject
	If workfile.GetDefault("seg_enabled",False)=True Then
		If SegEnabledFiles.IndexOf(filename)=-1 Then
			SegEnabledFiles.Add(filename)
		End If
	End If
	If filename=currentFilename Then
		currentWorkFileFrame.Initialize
		For Each key As String In workfile.Keys
			If key<>"files" Then
				currentWorkFileFrame.Put(key,workfile.Get(key))
			End If
		Next
	End If
	
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
	    Dim innerFilename As String
	    innerFilename=sourceFileMap.GetKeyAt(0)
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		filesegments.AddAll(segmentsList)
		If fillUI Then
			For i=0 To segmentsList.Size-1
				'Sleep(0) 'should not use coroutine as when change file, it will be a problem.
				Main.editorLV.Items.Add("")
			Next
		End If
	Next
End Sub

Sub saveWorkFile(filename As String,fileSegments As List,root As String)
	Dim workfile As Map
	workfile=currentWorkFileFrame
	If SegEnabledFiles.IndexOf(filename)<>-1 Then
		workfile.Put("seg_enabled",True)
	Else
		workfile.Put("seg_enabled",False)
	End If


	
	Dim sourceFiles As List
	sourceFiles.Initialize
	
	Dim segmentsForEachFile As List
	segmentsForEachFile.Initialize
	
	Dim previousInnerFilename As String
	Dim firstBitext As List
	firstBitext=fileSegments.Get(0)
	previousInnerFilename= firstBitext.Get(3)
	For Each bitext As List In fileSegments
		If previousInnerFilename=bitext.Get(3) Then
			segmentsForEachFile.Add(bitext)
		Else
			Dim newsegments As List
			newsegments.Initialize
			newsegments.AddAll(segmentsForEachFile)
			Dim sourceFileMap As Map
			sourceFileMap.Initialize
			sourceFileMap.Put(previousInnerFilename,newsegments)
			sourceFiles.Add(sourceFileMap)
			previousInnerFilename=bitext.Get(3)
			segmentsForEachFile.Clear
			segmentsForEachFile.Add(bitext)
		End If
	Next
	'repeat as for the last file, filename will not change
	Dim newsegments As List
	newsegments.Initialize
	newsegments.AddAll(segmentsForEachFile)
	Dim sourceFileMap As Map
	sourceFileMap.Initialize
	sourceFileMap.Put(previousInnerFilename,newsegments)
	sourceFiles.Add(sourceFileMap)
	
	workfile.Put("files",sourceFiles)
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(root,"work"),filename&".json",json.ToPrettyString(4))
End Sub

Sub saveFile(filename As String)
	If filename="" Then
		Return
	End If
	Dim visibleRange As Range
	visibleRange=Main.getVisibleRange(Main.editorLV)
	saveAlltheTranslationToSegmentsInVisibleArea(visibleRange.firstIndex,visibleRange.lastIndex)
	saveAlltheTranslationToTM
	saveWorkFile(filename,segments,path)
	contentChanged=False
	Main.MainForm.Title=Main.MainForm.Title.Replace("*","")
End Sub


Sub getAllSegments(filename As String) As List
	Dim allSegments As List
	allSegments.Initialize
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	For Each sourceFileMap As Map In sourceFiles
		Dim innerFilename As String
		innerFilename=sourceFileMap.GetKeyAt(0)
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerFilename)
		allSegments.AddAll(segmentsList)
	Next
	Return allSegments
End Sub

Public Sub generateTargetFiles
	Main.TargetFileGeneratingProgress.Total=files.Size
	Main.TargetFileGeneratingProgress.Done=0
	For Each filename As String In files
		Sleep(0)
		generateTargetFileForOne(filename)
	Next
End Sub

Sub generateTargetFileForOne(filename As String)
	Dim filenameLowercase As String
	filenameLowercase=filename.ToLowerCase
	Dim okapiExtractedFiles As List
	okapiExtractedFiles.Initialize
	If projectFile.ContainsKey("okapiExtractedFiles") Then
		okapiExtractedFiles.AddAll(projectFile.Get("okapiExtractedFiles"))
	End If
	If okapiExtractedFiles.IndexOf(filename)<>-1 Then
		Dim outputDir As String
		outputDir=File.GetFileParent(File.Combine(File.Combine(path,"target"),filename))
		If filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff") Then
			xliffFilter.generateFile(filename,path,projectFile)
			Dim targetPath As String
			targetPath=File.Combine(File.Combine(path,"target"),filename)
			Dim sourceDir As String
			sourceDir=File.Combine(path,"source")
			tikal.merge(targetPath,sourceDir,outputDir)
		End If
	Else
		If filenameLowercase.EndsWith(".txt") Then
			txtFilter.generateFile(filename,path,projectFile)
		Else if filenameLowercase.EndsWith(".idml") Then
			idmlFilter.generateFile(filename,path,projectFile)
		Else if filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff") Then
			xliffFilter.generateFile(filename,path,projectFile)
		Else
			Dim params As Map
			params.Initialize
			params.Put("filename",filename)
			params.Put("path",path)
			params.Put("projectFile",projectFile)
			params.Put("main",Main)
			runFilterPluginAccordingToExtension(filename,"generateFile",params)
		End If
	End If
End Sub

Public Sub contentIsChanged
	If contentChanged=False Then
		contentChanged=True
		Main.MainForm.Title=Main.MainForm.Title&"*"
	End If
End Sub

Public Sub saveNewDataToWorkfile(changedKeys As List)
	Log(changedKeys)
	If settings.ContainsKey("updateWorkFile_enabled") Then
		If settings.Get("updateWorkFile_enabled")=False Then
			Return
		End If
	End If
	If changedKeys.Size<>0 Then
		Main.updateOperation("updating workfile...")
		
		Dim changes As Map
		changes=getChangedMap(changedKeys)
		For Each filename As String In changes.Keys
			If files.IndexOf(filename)=-1 Then 'file not in the project
				Continue
			End If
			Dim filesegments As List
			filesegments.Initialize
			readWorkFile(filename,filesegments,False,path)
			Dim changedSegmentsList As List
			changedSegmentsList=changes.Get(filename)
			For Each changedSegment As Map In changedSegmentsList
				Dim index As Int
				Dim target,source,creator,createdTime As String
				index=changedSegment.get("index")
				target=changedSegment.get("target")
				source=changedSegment.get("source")
				creator=changedSegment.get("creator")
				createdTime=changedSegment.get("createdTime")
				Dim bitext As List
				bitext=filesegments.Get(index)
				Dim extra As Map
				extra=bitext.Get(4)
				If bitext.Get(0)=source Then
					bitext.Set(1,target)
					extra.Put("creator",creator)
					extra.Put("createdTime",createdTime)
					If filename=currentFilename Then
						Dim segment As List 'also need to set the clv and segment
						segment=segments.Get(index)
						segment.Set(1,target)
						Dim extraOfTheSegment As Map
						extraOfTheSegment=segment.Get(4)
						extraOfTheSegment.Put("creator",creator)
						extraOfTheSegment.Put("createdTime",createdTime)
						fillOne(index,target)
					End If
				End If
			Next
			saveWorkFile(filename,filesegments,path)
		Next
	End If
	Main.updateOperation("updated")
End Sub

Sub getChangedMap(changedKeys As List) As Map
	Dim changes As Map
	changes.Initialize
	For Each key In changedKeys
		Dim targetMap As Map
		targetMap=projectTM.translationMemory.Get(key)
		Dim filename As String
		Dim target As String
		Dim index As String
		Dim createdTime,creator As String
		filename=targetMap.Get("filename")
		target=targetMap.Get("text")
		index=targetMap.Get("index")
		createdTime=targetMap.Get("createdTime")
		creator=targetMap.Get("creator")
		Dim changedSegmentsList As List
		If changes.ContainsKey(filename) Then
			changedSegmentsList=changes.Get(filename)
		Else
			changedSegmentsList.Initialize
		End If
		
		Dim changedSegment As Map
		changedSegment.Initialize
		changedSegment.Put("index",index)
		changedSegment.Put("target",target)
		changedSegment.Put("source",key)
		changedSegment.Put("createdTime",createdTime)
		changedSegment.Put("creator",creator)
		changedSegmentsList.Add(changedSegment)
		
		changes.Put(filename,changedSegmentsList)
	Next
	Return changes
End Sub