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
	Private allsegments As List
	Private filtered As Boolean=False
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
	Private previousTaSelectionEnd As Int=-1
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
	allsegments.Initialize
	settings.Initialize
	SegEnabledFiles.Initialize
	currentWorkFileFrame.Initialize
	cm.Initialize("cm")
End Sub

Sub initializeTM(projectPath As String,isExistingProject As Boolean)
	projectTM.Initialize(projectPath,projectFile.Get("source"),projectFile.Get("target"))

	If isExistingProject Then
		If Main.preferencesMap.ContainsKey("checkExternalTMOnOpening") Then
			If Main.preferencesMap.Get("checkExternalTMOnOpening")=False Then
			    Return
			Else
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
			End If
		End If
	End If
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
	Return ""
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
	Main.LoadHTMLWithBackground(Main.LogWebView,"")
	Main.searchTableView.Items.Clear
	segments.Clear
	allsegments.Clear
	currentFilename=filename

	readWorkFile(currentFilename,segments,True,path)
	allsegments.AddAll(segments)
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
	Main.LoadHTMLWithBackground(Main.LogWebView,"")
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
	Dim mi8 As MenuItem
	mi8.Initialize("Reimport","reimportMi")
	mi8.Tag=filename
	fileCM.MenuItems.Add(mi)
	fileCM.MenuItems.Add(mi2)
	fileCM.MenuItems.Add(exportMenu)
	fileCM.MenuItems.Add(mi6)
	fileCM.MenuItems.Add(mi7)
	fileCM.MenuItems.Add(mi8)
	
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
	configsList.Add("stopwords.txt")
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
#region git
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
		Main.updateOperation("committed")
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
		wait for (updateLocalFileBasedonFetch(username,password,email)) Complete (success As Object)
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

Sub updateLocalFileBasedonFetch(username As String,password As String,email As String)  As ResumableSub
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
	Return True
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

#End Region

#region ui
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
	updateSegmentsWithWorkfile(workFilePath,segments)

	refillVisiblePane
	contentIsChanged
	fx.Msgbox(Main.MainForm,"Done","")
End Sub

Sub updateSegmentsWithWorkfile(workFilePath As String,segmentsToUpdate As List)
	Dim fileSegments As List
	fileSegments.Initialize
	fileSegments=readWorkfileToSegments(workFilePath)
	
	Dim sourceMap As Map
	sourceMap.Initialize
	For Each segment As List In fileSegments
		Dim source As String
		source=segment.Get(0)
		sourceMap.Put(source,segment)
	Next
	
	'progressDialog.Show("Updating","update")
	'Dim size As Int=segments.Size
	Dim index As Int
	'progressDialog.update(index,size)
	'Sleep(0)
	For Each segment As List In segmentsToUpdate
		index=index+1
		'progressDialog.update(index,size)
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
				If extra.ContainsKey("id") Then
					extraFromWorkfile.Put("id",extra.Get("id"))
				End If
				segment.Clear
				segment.AddAll(segmentFromWorkfile)
			End If
		End If
	Next
	'progressDialog.close
End Sub

Sub readWorkfileToSegments(workFilePath As String) As List
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
	Return fileSegments
End Sub

Sub reimportMI_Action
	Dim mi As MenuItem=Sender
	reimportFile(mi.Tag)
End Sub

Sub reimportFile(filename As String) As ResumableSub
	Dim workFilePath,workFileBackupPath As String
	workFilePath=File.Combine(File.Combine(path,"work"),filename&".json")
	workFileBackupPath=File.Combine(File.Combine(path,"work"),filename&".json.bak")
	Dim sourceFilePath As String=File.Combine(File.Combine(path,"source"),filename)
	Dim fileUpdated As Boolean=File.LastModified(sourceFilePath,"")>FileUtils.GetFileCreation(workFilePath,"")
	If projectFile.ContainsKey("okapiExtractedFiles") Then
		Dim okapiExtractedFiles As List=projectFile.get("okapiExtractedFiles")
		If okapiExtractedFiles.IndexOf(filename)<>-1 Then
			Dim originalFilename As String
			originalFilename=filename.SubString2(0,filename.LastIndexOf("."))
			Dim originalFilePath As String=File.Combine(File.Combine(path,"source"),originalFilename)
			fileUpdated=File.LastModified(originalFilePath,"")>FileUtils.GetFileCreation(workFilePath,"")
			If fileUpdated Then
				Dim sl,tl As String
				sl=projectFile.Get("source")
				tl=projectFile.Get("target")
				Dim tempPath As String=File.Combine(File.DirTemp,originalFilename)
				File.Copy(originalFilePath,"",tempPath,"")
				wait for (tikal.extract(sl,tl,tempPath,File.Combine(path,"source"),settings.GetDefault("tikal_codeattrs",False))) complete (success As Boolean)
				File.Delete(tempPath,"")
				If success=False Then
					Return ""
				End If
			End If
		End If
	End If

	If fileUpdated Then
		File.Copy(workFilePath,"",workFileBackupPath,"")
		wait for (createWorkFileAccordingToExtension(filename)) Complete (result As Object)
		Dim fileSegments As List
		fileSegments.Initialize
		readWorkFile(filename,fileSegments,False,path)
		updateSegmentsWithWorkfile(workFileBackupPath,fileSegments)
		saveWorkFile(filename,fileSegments,path)
		File.Delete(workFileBackupPath,"")
		If filename=currentFilename Then
			openFile(filename,False)
		End If
	End If
	Return ""
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
	
	Dim ta As RichTextArea
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
			If before="" Or after="" Then
				Continue
			End If
			Dim text As String=ta.Text
			If ta.SelectionEnd-before.Length>=0 Then
				Dim startIndex,endIndex As Int
				startIndex=ta.SelectionEnd-before.Length
				endIndex=ta.SelectionEnd
				match=text.SubString2(startIndex,endIndex)
				If match=before Then
					ta.Text=text.SubString2(0,startIndex)&after&text.SubString2(ta.SelectionEnd,text.Length)
					ta.SetSelection(startIndex+after.Length,startIndex+after.Length)
					corrected=True
				End If
			End If
		Next
	End If
	

	#region autocomplete
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
	'Log("last"&lastString&"last")
	'Log(ta.SelectionStart)
	ShowITPContextMenu(ta,lastString)
	#end region
	CallSubDelayed(Main, "ListViewParent_Resize")
End Sub

Sub ShowITPContextMenu(ta As RichTextArea,lastString As String)
	If cmClicked=True Then
		cmClicked=False
	Else
		If (ta.Tag Is List And lastString.Length>0) Or (ta.Tag Is List And ta.SelectionStart=0) Then
			Dim segmentsList As List
			segmentsList=ta.Tag
			Dim maxSuggestionNum As Int
			maxSuggestionNum=Main.preferencesMap.GetDefault("maxSuggestionNum",5)
			Dim suggestions As List
			suggestions.Initialize
			Dim num As Int=0
			For Each text As String In segmentsList
				If lastString.Length>0 Then
					If text.ToLowerCase.StartsWith(lastString.ToLowerCase) And text<>lastString Then
						num=num+1
						If text.StartsWith(lastString) Then
							suggestions.Add(text)
						Else
							'suggestion: translation, lastString: Tr
                            suggestions.Add(Utils.replaceOnce(text.ToLowerCase,lastString.ToLowerCase,lastString))
						End If
					End If
				Else
					num=num+1
					suggestions.Add(text)
				End If
				If num>=maxSuggestionNum Then
					Exit
				End If
			Next

			If suggestions.Size>0 Then
				If ContextMenuItemsChanged(cm,suggestions) Or cm.MenuItems.Size=0 Then
					cm.MenuItems.Clear
					Sleep(0)
					For Each suggestion As String In suggestions
						Dim mi As MenuItem
						mi.Initialize(suggestion, "mi")
						mi.Tag=lastString
						cm.MenuItems.Add(mi)
					Next

					Dim jo As JavaObject = cm
					jo.RunMethod("show", Array(ta.BasePane, ta.CaretMaxX, ta.CaretMaxY))
					If Main.preferencesMap.GetDefault("auto_select_firstone",True) Then
						jo.RunMethodJO("getSkin",Null).RunMethodJO("getNode",Null).RunMethodJO("lookup",Array(".menu-item")).RunMethod("requestFocus",Null)
					End If
					'cm.getSkin().getNode().lookup(".menu-item").requestFocus();
				Else
					For Each mi As MenuItem In cm.MenuItems
						mi.Tag=lastString
					Next
				End If
			Else
				cm.MenuItems.Clear
			End If
		End If
	End If
End Sub

Sub ContextMenuItemsChanged(cm1 As ContextMenu,list1 As List) As Boolean
	Dim list2 As List
	list2.Initialize
	For Each mi As MenuItem In cm1.MenuItems
		list2.Add(mi.Text)
	Next
	If list1.Size<>list2.Size Then
		Return True
	End If
	For Each s As String In list1
		If list2.IndexOf(s)=-1 Then
			Return True
		End If
	Next
	Return False
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
	Dim useRichTextArea As Boolean=Main.preferencesMap.GetDefault("use_richtextarea",True)
	If useRichTextArea=False Then
		segmentpane.LoadLayout("segmentUsingTextArea")
	Else
		segmentpane.LoadLayout("segment")
	End If

	segmentpane.SetSize(Main.editorLV.Width,50dip)
	Dim sourceTextArea As RichTextArea
	sourceTextArea=segmentpane.GetNode(0).Tag
	sourceTextArea.Text=source
	sourceTextArea.WrapText=True
	Main.setTextAreaStyle(sourceTextArea,"sourceFont")
	addKeyEvent(sourceTextArea.BasePane,"sourceTextArea")
	If LanguageUtils.LanguageIsRight2Left(projectFile.Get("source")) Then
		If useRichTextArea Then
			sourceTextArea.GetObjectJO.RunMethodJO("getStylesheets",Null).RunMethod("add",Array(File.GetUri(File.DirAssets,"right-aligned-richtext.css")))
		Else
			sourceTextArea.SetNodeOrientation("RIGHT_TO_LEFT")
		End If
	End If
	
	Dim targetTextArea As RichTextArea
	targetTextArea=segmentpane.GetNode(1).Tag
	targetTextArea.Text=target
	targetTextArea.WrapText=True
	Main.setTextAreaStyle(targetTextArea,"targetFont")
	addKeyEvent(targetTextArea.BasePane,"targetTextArea")
	If LanguageUtils.LanguageIsRight2Left(projectFile.Get("target")) Then
		If useRichTextArea Then
			targetTextArea.GetObjectJO.RunMethodJO("getStylesheets",Null).RunMethod("add",Array(File.GetUri(File.DirAssets,"right-aligned-richtext.css")))
		Else
			targetTextArea.SetNodeOrientation("RIGHT_TO_LEFT")
		End If
	End If
	
	sourceTextArea.BasePane.Left=0
	sourceTextArea.BasePane.SetSize(Main.editorLV.Width/2-20dip,50dip)
	targetTextArea.BasePane.Left=sourceTextArea.BasePane.Left+sourceTextArea.BasePane.Width
	targetTextArea.BasePane.SetSize(Main.editorLV.Width/2-20dip,50dip)
End Sub

Sub addKeyEvent(textarea1 As Object,eventName As String)
	Dim CJO As JavaObject = textarea1
	Dim O As Object = CJO.CreateEventFromUI("javafx.event.EventHandler",eventName&"_KeyPressed",Null)
	CJO.RunMethod("setOnKeyPressed",Array(O))
	CJO.RunMethod("setFocusTraversable",Array(True))
End Sub

Sub sourceTextArea_SelectedTextChanged(old As Object, new As Object)
	Dim ta As RichTextArea
	ta=Sender
	onSelectionChanged(new,ta,True)
End Sub

Sub targetTextArea_SelectedTextChanged(old As Object, new As Object)
	Dim ta As RichTextArea
	ta=Sender
	onSelectionChanged(new,ta,False)
End Sub

Sub onSelectionChanged(selectedText As String,ta As RichTextArea,isSource As Boolean)
	If selectedText.Trim<>"" Then
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
		If Main.preferencesMap.GetDefault("lookup_usingF1",False)=False Then
			showWordMeaning(selectedText,ta)
		End If
	Else
		index=1
	End If
	'------------------ show word meaning
	Dim selectionEnd As Int=ta.SelectionEnd
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
			Dim row() As Object = Array As Object(Utils.LabelWithText(segment.Get(segment.Size-1)), _ 
													Utils.LabelWithText(segment.Get(0)), _ 
													Utils.LabelWithText(segment.Get(1)))
			Main.searchTableView.Items.Add(row)
		Next
		Main.changeWhenSegmentOrSelectionChanges
	End If
	'---------- show segment search
End Sub

Sub showWordMeaning(selectedText As String,ta As RichTextArea)
	If cmClicked=True Then
		cmClicked=False
	Else
		cm.MenuItems.Clear
		wait for (getMeans(selectedText)) complete (result As List)
		
		Dim p As Pane
		p.Initialize("")
		p.SetSize(24dip,24dip)
		Dim cvs As B4XCanvas
		cvs.Initialize(p)
		Dim xui As XUI
		For Each meaningMap As Map In result
			Dim mi As MenuItem
			mi.Initialize(meaningMap.Get("text"), "mi")
			If Main.preferencesMap.GetDefault("lookup_showSource",False)=True Then
				Dim initial As String=meaningMap.Get("source")
				initial=initial.CharAt(0)
				cvs.ClearRect(cvs.TargetRect)
				DrawTextWithCircle(cvs,initial.ToUpperCase,xui.CreateDefaultFont(12),xui.Color_DarkGray,12dip,12dip)
				mi.Image=cvs.CreateBitmap
			End If
			cm.MenuItems.Add(mi)
		Next
		Sleep(100)
		Dim jo As JavaObject = cm
		jo.RunMethod("show", Array(ta.BasePane, Main.getLeft, Main.getTop))
	End If
End Sub

Sub DrawTextWithCircle (cvs1 As B4XCanvas, Text As String, Fnt As B4XFont, Clr As Int, CenterX As Int, CenterY As Int)
	Dim r As B4XRect = cvs1.MeasureText(Text, Fnt)
	Dim BaseLine As Int = CenterY - r.Height / 2 - r.Top
	cvs1.DrawText(Text, CenterX, BaseLine, Fnt, Clr, "CENTER")
	cvs1.DrawCircle(CenterX, CenterY, r.Height , Clr, False, 1)
End Sub

Sub mi_Action
	cmClicked=True
	Dim mi As MenuItem
	mi=Sender
	Try
		Dim p As Pane
		p=Main.editorLV.Items.Get(lastEntry)
		Dim targetTextArea As RichTextArea
		targetTextArea=p.GetNode(1).Tag
		If mi.Tag<>Null Then ' do not respond to space
			If targetTextArea.Text<>"" Then
				If targetTextArea.Text.SubString2(targetTextArea.SelectionEnd-1,targetTextArea.SelectionEnd)=" " Then
					cmClicked=False
					Return
				End If
			End If
		End If

		Dim before,replace,after As String
		before=targetTextArea.Text.SubString2(0,targetTextArea.SelectionStart)
		'eg. mi.text: vision mi.tag: vi
		replace=Utils.replaceOnce(mi.Text,mi.Tag,"")
		after=targetTextArea.Text.SubString2(targetTextArea.SelectionStart,targetTextArea.Text.Length)
		targetTextArea.Text=before&replace&after
		Sleep(0)
		targetTextArea.SetSelection(before.Length+replace.Length,before.Length+replace.Length)
	Catch
		Log(LastException)
	End Try
	
End Sub

Sub sourceTextArea_MouseClicked (EventData As MouseEvent)
	Dim ta As RichTextArea
	ta=Sender
	lastEntry=Main.editorLV.Items.IndexOf(ta.Parent)
	If ta.SelectionEnd=ta.SelectionStart Then
		Dim jo As JavaObject = cm
		jo.RunMethod("hide", Null)
	End If
End Sub


Sub sourceTextArea_KeyPressed (result As String)
	Dim sourceTextArea As RichTextArea
	sourceTextArea=Sender
	Log(result)
    If result="ENTER" Then
		If SegEnabledFiles.IndexOf(currentFilename)<>-1 Then
			fx.Msgbox(Main.MainForm,"This file does not support spliting and merging segments","")
			Return
		End If
		If filtered Then
			fx.Msgbox(Main.MainForm,"Not in this mode","")
			Return
		End If
		contentIsChanged
		Dim filenameLowercase As String
		filenameLowercase=currentFilename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") And filterIsEnabled("txt (BasicCAT)") Then
			txtFilter.splitSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".idml") And filterIsEnabled("idml (BasicCAT)") Then
			idmlFilter.splitSegment(sourceTextArea)
		Else if (filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff"))  And filterIsEnabled("xliff (BasicCAT)") Then
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
		allsegments.Clear
		allsegments.AddAll(segments)
	Else if result="DELETE" Then
		If SegEnabledFiles.IndexOf(currentFilename)<>-1 Then
			fx.Msgbox(Main.MainForm,"This file does not support spliting and merging segments","")
			Return
		End If
		If filtered Then
			fx.Msgbox(Main.MainForm,"Not in this mode","")
			Return
		End If
		contentIsChanged
		Dim filenameLowercase As String
		filenameLowercase=currentFilename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") And filterIsEnabled("txt (BasicCAT)") Then
			txtFilter.mergeSegment(sourceTextArea)
		Else if filenameLowercase.EndsWith(".idml") And filterIsEnabled("idml (BasicCAT)") Then
			idmlFilter.mergeSegment(sourceTextArea)
		Else if (filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff")) And filterIsEnabled("xliff (BasicCAT)") Then
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
		allsegments.Clear
		allsegments.AddAll(segments)
	else if result="F1" Then
		If Main.preferencesMap.GetDefault("lookup_usingF1",False)=True Then
			Dim selectedText As String=sourceTextArea.Text.SubString2(sourceTextArea.SelectionStart,sourceTextArea.SelectionEnd)
			showWordMeaning(selectedText,sourceTextArea)
		End If
	Else if result="TAB" Then
		swithTextArea(sourceTextArea,1)
	End If
End Sub

Sub filterIsEnabled(filterName As String) As Boolean
	Dim disabledFilters As List
	If settings.ContainsKey("disabled_filters") Then
		disabledFilters=settings.get("disabled_filters")
	Else
		disabledFilters.Initialize
		disabledFilters.Add("idml (BasicCAT)") 'idml is disabled by default
	End If
	If disabledFilters.IndexOf(filterName)=-1 Then
		Return True
	Else
		Log(filterName&" is disabled")
		Return False
	End If
End Sub

Sub targetTextArea_KeyPressed (result As String)
	'Log(result)
	Dim targetTextArea As RichTextArea
	targetTextArea=Sender
	Dim selectionEnd As Int=targetTextArea.SelectionEnd
	If result="ENTER" Then
		changeSegment(1,targetTextArea)
	Else if result="DOWN" And selectionEnd=previousTaSelectionEnd Then
			changeSegment(1,targetTextArea)
	Else if result="UP" And selectionEnd=previousTaSelectionEnd Then
			changeSegment(-1,targetTextArea)
	Else if result="TAB" Then
		swithTextArea(targetTextArea,0)
	Else
		previousTaSelectionEnd=selectionEnd
	End If
End Sub

Sub swithTextArea(ta As RichTextArea,index As Int)
	If ta.Text.SubString2(0,ta.SelectionEnd).EndsWith("	") Then
		Return
	End If
	Dim pane As Pane
	pane=ta.Parent
	Dim targetTA As RichTextArea=pane.GetNode(index).Tag
	targetTA.RequestFocus
End Sub

Sub changeSegment(offset As Int,targetTextArea As RichTextArea)
	Try
		'targetTextArea.Text=targetTextArea.Text.Replace(CRLF,"")
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
		Dim nextTA As RichTextArea
		nextTA=nextPane.GetNode(1).Tag
		nextTA.RequestFocus
		Select offset
			Case -1
			    nextTA.setSelection(nextTA.Length,nextTA.Length)
			Case 1
			    nextTA.setSelection(0,0)
		End Select
		previousTaSelectionEnd=nextTA.SelectionEnd
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
	Dim TextArea1 As RichTextArea
	TextArea1=Sender
	If HasFocus Then
		TextArea1.Tag=TextArea1.Text
	Else
		If TextArea1.Tag<>TextArea1.Text Then
			TextArea1.Text=TextArea1.Tag
		End If
	End If
End Sub

Sub targetTextArea_FocusChanged (HasFocus As Boolean)
	Dim TextArea1 As RichTextArea
	TextArea1=Sender
	'Sleep(0)
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
		'Log(TextArea1.Text)
		'Log(previousEntry)
		'Log(lastEntry)
		showTM(TextArea1)
		showTerm(TextArea1)
		Main.updateSegmentLabel(Main.editorLV.Items.IndexOf(TextArea1.Parent),segments.Size)
	Else
		Log("loseFocus")
		'Log("previous"&previousEntry)
		'Log("lastentry"&lastEntry)
		'Log(TextArea1.Text)
		If previousEntry<>lastEntry Then
			languagecheck(TextArea1,lastEntry)
		End If
		previousEntry=lastEntry
	End If
End Sub

Sub languagecheck(ta As RichTextArea,entry As Int)
	If Main.getCheckLVSize<=1 Then
		If Main.preferencesMap.ContainsKey("languagetoolEnabled") Then
			If Main.preferencesMap.Get("languagetoolEnabled")=True Then
				wait for (LanguageTool.check(ta.Text,projectFile.Get("target"))) complete (matches As List)
				showReplacements(matches,entry)
			End If
		End If
	End If
End Sub

Sub showReplacements(matches As List,entry As Int)
	If matches.Size=0 Then
		Main.noErrors
		Return
	End If
	If Main.getCheckLVSize>1 Then
		Return
	End If
	Try
		Dim p As Pane
		p=Main.editorLV.Items.Get(entry)
	Catch
		Log(LastException)
		Return
	End Try

	Dim ta As RichTextArea
	ta=p.GetNode(1).Tag
	
	Dim match As Map=matches.Get(0)
	Main.addCheckList(matches,entry,ta.Text)
	
	Dim replacementsCM As ContextMenu
	replacementsCM.Initialize("replacementsCM")
	Dim replacements As List
	replacements=match.Get("replacements")
	Dim offset,length As Int
	offset=match.Get("offset")
	length=match.Get("length")

	Dim maxCheckDropdownNum As Int=5
	If Main.preferencesMap.ContainsKey("maxCheckDropdownNum") Then
		maxCheckDropdownNum=Main.preferencesMap.Get("maxCheckDropdownNum")
	End If
	Dim num As Int=0
	For Each replace As Map In replacements
		Log(replace)
		num=num+1
		Dim replacement As String
		replacement=replace.Get("value")
		Dim mi As MenuItem
		mi.Initialize(replacement, "replacementMi")
		Dim tagList As List
		tagList.Initialize
		tagList.Add(offset)
		tagList.Add(length)
		tagList.Add(replacement)
		tagList.Add(entry)
		tagList.Add(matches)
		'tagList.Add(ta)
		mi.Tag=tagList
		replacementsCM.MenuItems.Add(mi)
		If num=maxCheckDropdownNum Then
			Exit
		End If
	Next
	Sleep(100)
	Dim map1 As Map
	map1=Utils.GetScreenPosition(ta.BasePane)
	Log(map1)
	Dim jo As JavaObject = replacementsCM
	jo.RunMethod("show", Array(ta.BasePane, map1.Get("x")+ta.Width/10, map1.Get("y")+ta.Height))
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
		'Log(thisPreviousEntry)
		Dim replacement As String
		replacement=tagList.Get(2)
		'Log(replacement)
		Dim p As Pane
		p=Main.editorLV.Items.Get(thisPreviousEntry)
		Dim targetTextArea As RichTextArea
		targetTextArea=p.GetNode(1).Tag
		targetTextArea.Text=targetTextArea.Text.SubString2(0,offset)&replacement&targetTextArea.Text.SubString2(offset+length,targetTextArea.Text.Length)
		Sleep(0)
		targetTextArea.SetSelection(targetTextArea.Text.Length,targetTextArea.Text.Length)
		Main.checkLVClear
		targetTextArea.RequestFocus
	Catch
		Log(LastException)
	End Try
End Sub

Sub loadITPSegments(targetTextArea As RichTextArea,words As List,chunks As List,longphrases As List,engine As String,fullTranslation As String)
	Dim result As List
	result.Initialize
	wait for (ITP.getTranslation(words,chunks,longphrases,engine)) Complete (segmentTranslations As List)
	'result.Add(fullTranslation)
	result.AddAll(segmentTranslations)
	result.AddAll(ITP.getWords(fullTranslation,projectFile.Get("target")))
	result.AddAll(ITP.getChunks(fullTranslation,projectFile.Get("target")))
	If Main.preferencesMap.GetDefault("addSourceWords",False) Then
		result.AddAll(words)
	End If
	result=StopWordsRemoved(result)
	Log(result)
	If targetTextArea.Tag Is List Then
		Dim list1 As List
		list1=targetTextArea.Tag
		list1.AddAll(result)
		targetTextArea.Tag=ITP.duplicatedRemovedList(list1)
	Else
		targetTextArea.Tag=result
	End If
End Sub

Sub StopWordsRemoved(list1 As List) As List
	Dim configPath As String=File.Combine(path,"config")
	If File.Exists(configPath,"stopwords.txt") Then
		Dim new As List
		new.Initialize
		Dim stopwords As List=File.ReadList(configPath,"stopwords.txt")
		For Each item As String In list1
			If stopwords.IndexOf(item.ToLowerCase)=-1 Then
				new.Add(item)
			End If
		Next
		Return new
	Else
		Return list1
	End If
End Sub

Sub showTM(targetTextArea As RichTextArea)
	Dim time As Long
	time=DateTime.Now
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As RichTextArea
	sourceTA=pane.GetNode(0).Tag
	Dim targetTA As RichTextArea
	targetTA=pane.GetNode(1).Tag

	If projectTM.currentSource=sourceTA.Text Then 'avoid loading the same many times
		Return
	End If
	Main.tmTableView.Items.Clear
	Main.LoadHTMLWithBackground(Main.LogWebView,"")
	projectTM.currentSource=sourceTA.Text
	'Log("source")
	'Log(sourceTA.Text)
	showMT(sourceTA.Text,targetTextArea)
	
	Dim matchrate As Double
	If Main.currentProject.settings.ContainsKey("matchrate") Then
		matchrate=Main.currentProject.settings.Get("matchrate")
	Else
		matchrate=0.5
	End If
	
	Dim limit As Int
	limit=settings.GetDefault("TM_limit",500)
	
	Dim tmMatches As List
	tmMatches.Initialize
	For Each isExternal As Boolean In Array(False,True)
		Dim senderFilter As Object = projectTM.getMatchList(isExternal,sourceTA.Text,matchrate,False,limit)
		Wait For (senderFilter) Complete (Result As List)
		tmMatches.AddAll(Result)
	Next
	tmMatches=projectTM.subtractedAndSortMatchList(tmMatches,4)
	Dim index As Int=0
	For Each matchList As List In tmMatches
		If matchList.Get(1)=sourceTA.Text And targetTA.Text=matchList.Get(2) Then
			Continue 'itself
		End If
		Dim row() As Object = Array As Object(Utils.LabelWithText(matchList.Get(0)), _
												Utils.LabelWithText(matchList.Get(1)), _ 
												Utils.LabelWithText(matchList.Get(2)), _ 
												Utils.LabelWithText(matchList.Get(3)))
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

Sub showMT(source As String,targetTextArea As RichTextArea)
	Dim mtPreferences As Map
	If Main.preferencesMap.ContainsKey("mt") Then
		mtPreferences=Main.preferencesMap.get("mt")
	Else
		Return
	End If
 
	Dim autocompleteEnabled As Boolean=Main.preferencesMap.GetDefault("autocompleteEnabled",False)
	If autocompleteEnabled Then
        Dim words As List
		words=ITP.getWords(source,projectFile.Get("source"))
		Dim chunks As List
		chunks=ITP.getChunks(source,projectFile.Get("source"))
		wait for (ITP.getLongPhrasesFromText(source,projectFile.Get("source"),words)) Complete (longphrases As List)
	End If

	For Each engine As String In MT.getMTList
		If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
			wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),engine)) Complete (Result As String)
			If Result<>"" Then
				'Log("mt:"&Result)
				Dim row() As Object = Array As Object(Utils.LabelWithText(""),Utils.LabelWithText(""),Utils.LabelWithText(Result),Utils.LabelWithText(engine))
				Main.tmTableView.Items.add(row)
				Main.changeWhenSegmentOrSelectionChanges
			End If
			If autocompleteEnabled Then
				loadITPSegments(targetTextArea,words,chunks,longphrases,engine,Result)
			End If
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
				For Each meaning As String In Result
					Dim meaningMap As Map
					meaningMap.Initialize
					meaningMap.Put("source","YoudaoDict")
					meaningMap.Put("text",meaning)
					resultList.Add(meaningMap)
				Next

			End If
		End If
	End If

	If Main.preferencesMap.ContainsKey("lookupWordUsingMT") Then
		If Main.preferencesMap.Get("lookupWordUsingMT")=True Then
			For Each engine As String In MT.getMTList
				'If engine="youdao" Then
				'	Continue
				'End If
				If Utils.get_isEnabled(engine&"_isEnabled",mtPreferences)=True Then
					wait for (MT.getMT(source,projectFile.Get("source"),projectFile.Get("target"),engine)) Complete (one As String)
					If one<>"" Then
						Dim meaningMap As Map
						meaningMap.Initialize
						meaningMap.Put("source",engine)
						meaningMap.Put("text",one)
						resultList.Add(meaningMap)
					End If
				End If
			Next
		End If
	End If

	
	
	Return resultList
End Sub

Sub showTerm(targetTextArea As RichTextArea)
	Main.termLV.Items.Clear
	Dim pane As Pane
	pane=targetTextArea.Parent
	Dim sourceTA As RichTextArea
	sourceTA=pane.GetNode(0).Tag
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
		
		#region for autocomplete
		Dim autocompleteEnabled As Boolean=Main.preferencesMap.GetDefault("autocompleteEnabled",False)
		If autocompleteEnabled Then
			If targetTextArea.Tag Is List Then
				Dim tagList As List=targetTextArea.Tag
				If tagList.IndexOf(lbl2.Text)=-1 Then
					tagList.Add(lbl2.Text)
				End If
			Else
				Dim tagList As List
				tagList.Initialize
				tagList.Add(lbl2.Text)
				targetTextArea.Tag=tagList
			End If
		End If
		#end region

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
			'Sleep(0)
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
				Dim similarity,matchrate As Double
				matchrate=options.Get("rate")
				Dim limit As Int
				limit=settings.GetDefault("TM_limit",500)
				Wait For (projectTM.getOneUseMemory(bitext.Get(0),matchrate,limit)) Complete (Result As List)
				If Result=Null Then
					completed=completed+1
					progressDialog.update(completed,segments.Size)
					Continue
				End If
				resultList=Result
				
				similarity=resultList.Get(0)
				If similarity>=matchrate Then
					setTranslation(index,resultList.Get(2),True,resultList.Get(1))
					'setSegment(bitext,index)
					fillOne(index,resultList.Get(2))
				End If
			Else if options.Get("type")="MT" Then
				Dim interval As Int=options.GetDefault("interval",0)
				If interval>0 Then
					Sleep(interval)
				End If
				wait for (MT.getMT(bitext.Get(0),projectFile.Get("source"),projectFile.Get("target"),options.Get("engine"))) Complete (translation As String)
				If translation<>"" Then
					setTranslation(index,translation,False,"")
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
		Dim targetTextArea As RichTextArea
		targetTextArea=p.GetNode(1).Tag
		targetTextArea.Text=translation
		Dim bitext As List
		bitext=segments.Get(index)
		Dim extra As Map
		extra=bitext.Get(4)
		setPaneStatus(extra,p)
		contentIsChanged
	Catch
		Log("fillone_error")
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
			Dim ta As RichTextArea=segmentPane.GetNode(1).Tag
			ta.DefaultBorderColor=fx.Colors.RGB(0,128,0)
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
		Dim targetTextArea As RichTextArea
		targetTextArea=p.GetNode(1).Tag
		Dim bitext As List
		bitext=segments.Get(i)
		targetTextArea.Text=bitext.Get(1)
	Next
End Sub

#End Region

'impl
'--------------------------

Public Sub setTranslation(index As String,translation As String,isFromTM As Boolean,TMSource As String)
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
		Dim creator As String=GetSystemProperty("user.name","anonymous")
		Dim vcs_username As String=Main.preferencesMap.GetDefault("vcs_username","")
		If vcs_username<>"" Then
			creator=vcs_username
		End If
		If isFromTM Then
			Dim targetMap As Map
			targetMap.Initialize
			If projectTM.translationMemory.ContainsKey(TMSource) Then
				targetMap=projectTM.translationMemory.Get(TMSource)
			else If projectTM.externalTranslationMemory.ContainsKey(TMSource) Then
				targetMap=projectTM.externalTranslationMemory.Get(TMSource)
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
		Dim targetTextArea As RichTextArea
		Try
			Dim p As Pane
			p=Main.editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try

		targetTextArea=p.GetNode(1).tag
		setTranslation(i,targetTextArea.Text,False,"")
		
		'projectTM.addPair(bitext.Get(0),bitext.Get(1))
	Next
End Sub

Sub saveTranslation(targetTextArea As RichTextArea)
	Dim index As Int
	index=Main.editorLV.Items.IndexOf(targetTextArea.Parent)
	Dim bitext As List
	bitext=segments.Get(index)
	setTranslation(index,targetTextArea.Text,False,"")
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
	Dim sentenceLevel As Boolean=settings.GetDefault("sentence_level_segmentation",True)
	Try
		Dim filenameLowercase As String
		filenameLowercase=filename.ToLowerCase
		If filenameLowercase.EndsWith(".txt") And filterIsEnabled("txt (BasicCAT)") Then
			wait for (txtFilter.createWorkFile(filename,path,projectFile.Get("source"),sentenceLevel)) Complete (result As Boolean)
		Else if filenameLowercase.EndsWith(".idml") And filterIsEnabled("idml (BasicCAT)") Then
			wait for (idmlFilter.createWorkFile(filename,path,projectFile.Get("source"),sentenceLevel)) Complete (result As Boolean)
		Else if (filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff")) And filterIsEnabled("xliff (BasicCAT)") Then
			wait for (xliffFilter.createWorkFile(filename,path,projectFile.Get("source"),sentenceLevel)) Complete (result As Boolean)
		Else
			Dim params As Map
			params.Initialize
			params.Put("filename",filename)
			params.Put("path",path)
			params.Put("sourceLang",projectFile.Get("source"))
			params.Put("sentenceLevel",sentenceLevel)
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
	If filtered Then
		saveWorkFile(filename,allsegments,path)
	Else
		saveWorkFile(filename,segments,path)
	End If
	contentChanged=False
	Main.MainForm.Title=Main.MainForm.Title.Replace("*","")
End Sub


Sub getAllSegments(filename As String) As List
	Dim all As List
	all.Initialize
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
		all.AddAll(segmentsList)
	Next
	Return all
End Sub

Public Sub generateBilingualTargetFiles
	For Each filename As String In files
		Dim extension As String=filename.SubString2(filename.LastIndexOf(".")+1,filename.Length)
		If extension.EndsWith("xlf")=False Then
			Continue
		End If
		Dim fileSegments As List
		fileSegments.Initialize
		File.Copy(File.Combine(path,"work"),filename&".json",File.Combine(path,"work"),filename&".json.bak")
		readWorkFile(filename,fileSegments,False,path)
		If SegEnabledFiles.IndexOf(currentFilename)<>-1 Then
			Utils.appendSourceToTarget(fileSegments,True,extension,projectFile.Get("source"))
		Else
			Utils.appendSourceToTarget(fileSegments,False,extension,projectFile.Get("target"))
		End If
		
		saveWorkFile(filename,fileSegments,path)
		generateTargetFileForOne(filename)
	Next
	For Each filename As String In files
		If extension.EndsWith("xlf")=False Then
			Continue
		End If
		File.Copy(File.Combine(path,"work"),filename&".json.bak",File.Combine(path,"work"),filename&".json")
		File.Delete(File.Combine(path,"work"),filename&".json.bak")
	Next
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
		If (filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff")) And filterIsEnabled("xliff (BasicCAT)") Then
			xliffFilter.generateFile(filename,path,projectFile)
			Dim targetPath As String
			targetPath=File.Combine(File.Combine(path,"target"),filename)
			Dim sourceDir As String
			sourceDir=File.Combine(path,"source")
			tikal.merge(targetPath,sourceDir,outputDir)
		End If
	Else
		If filenameLowercase.EndsWith(".txt") And filterIsEnabled("txt (BasicCAT)") Then
			txtFilter.generateFile(filename,path,projectFile)
		Else if filenameLowercase.EndsWith(".idml") And filterIsEnabled("idml (BasicCAT)") Then
			idmlFilter.generateFile(filename,path,projectFile)
		Else if (filenameLowercase.EndsWith(".xlf") Or filenameLowercase.EndsWith(".xliff")) And filterIsEnabled("xliff (BasicCAT)") Then
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

Public Sub filterSegments(indexList As List)
	filtered=True
	segments.Clear
    For Each index As Int In indexList
		segments.Add(allsegments.Get(index))
	Next
	ReloadEditor
End Sub

Public Sub showAllSegments
	filtered=False
	segments.Clear
	segments.AddAll(allsegments)
	ReloadEditor
End Sub

Sub ReloadEditor
	Main.editorLV.Items.Clear
	For i=0 To segments.Size-1
		Main.editorLV.Items.Add("")
	Next
	refillVisiblePane
End Sub
