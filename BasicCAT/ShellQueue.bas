B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=3.61
@EndOfDesignText@
#Event: JobCompleted(Job as ShellQueueJob)
#Event: QueueFinished
'#RaisesSynchronousEvents: Shell_ProcessCompleted
'#RaisesSynchronousEvents: Timer_Queue_Tick

'Class module
Sub Class_Globals
	Private fx As JFX
	Private MAXTHREADS As Int = 1
	Private TIMEOUT As Int = 5000
	
	Type ShellQueueJob(Command As Shell, Status As String, Tag As Object, Success As Boolean, StdOut As String, StdErr As String)
	
	Private Const CMD_PENDING As String = "Pending"
	Private Const CMD_ACTIVE As String = "Active"
	Private Const CMD_SUCCESS As String = "Success"
	Private Const CMD_FAILED As String = "Failed"
	Private CMD_QUEUE As List
	Private CMD_SLOTS As List
	Private Timer_Queue As Timer
	Private oModule As Object
	Private sEventName As String
End Sub

'Initialize the queue.
'MaxConcurrentJobs: The maximum number of concurrent jobs. pass 0 or -1 for unlimited number of concurrent jobs.
'CommandTimeOut: timeout for the jobs.
'Module: the module that will receive the events. (Usually "Me")
'EventName: The event name:
Public Sub Initialize(MaxConcurrentJobs As Int, CommandTimeOut As Int, Module As Object, EventName As String)
	MAXTHREADS = MaxConcurrentJobs
	If MAXTHREADS < 1 Then
		MAXTHREADS = 99999999
	End If
	TIMEOUT = CommandTimeOut
	oModule = Module
	sEventName = EventName
	
	Timer_Queue.Initialize("Timer_Queue", 10)
	Timer_Queue.Enabled = False
	
	CMD_QUEUE.Initialize
	CMD_SLOTS.Initialize	
End Sub

'Starts the queue.
Public Sub StartQueue
	Timer_Queue.Enabled = True	
End Sub

'Pauses the queue:
Public Sub PauseQueue
	Timer_Queue.Enabled = False	
End Sub

'Clears the queue.
Public Sub ClearQueue
	CMD_QUEUE.Clear
	CMD_SLOTS.Clear
End Sub

'Adds a job to the queue.
'ShellJob: A jshell Job.
'DoNotHandleQuotes: Handles or not the quotes in the arguments.
'Tag: an object linked to this command.
Public Sub AddToQueue(Executable As String, Arguments As List, WorkingDirectory As String, DoNotHandleQuotes As Boolean, Tag As Object)
	Dim sh As Shell
	If DoNotHandleQuotes Then
		sh.InitializeDoNotHandleQuotes("Shell", Executable, Arguments)
	Else	
		sh.Initialize("Shell", Executable, Arguments)
	End If
	sh.WorkingDirectory = WorkingDirectory

	Dim Job As ShellQueueJob
	Job.Initialize
	Job.Command = sh
	Job.Status = CMD_PENDING
	Job.Tag = Tag
	
	CMD_QUEUE.Add(Job)
End Sub

Private Sub Timer_Queue_Tick	
	If CMD_QUEUE.Size = 0 Then
		'Finished.
		Timer_Queue.Enabled = False
		
		If oModule <> Null Then
			CallSubDelayed(oModule, sEventName & "_QueueFinished")
		End If
			
		Return
	End If
	
	Do While True
		If CMD_SLOTS.Size = MAXTHREADS Then
			Timer_Queue.Enabled = False
			Exit
		End If
		Dim Job As ShellQueueJob = FindPendingJob
		If Job = Null Then Exit
		Job.Status = CMD_ACTIVE	
		Job.Command.Run(TIMEOUT)
		CMD_SLOTS.Add(Job)
	Loop
End Sub

Private Sub FindPendingJob As ShellQueueJob
	For Each Job As ShellQueueJob In CMD_QUEUE
		If Job.Status = CMD_PENDING Then
			Return Job
		End If
	Next
	Return Null	
End Sub

Private Sub Shell_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	Dim sh As Shell = Sender

	For Each Job As ShellQueueJob In CMD_QUEUE
		If Job.Command = sh Then
			'Keep the info:
			Job.Success = Success
			Job.StdErr = StdErr
			Job.StdOut = StdOut
			
			If Success Then
				Job.Status = CMD_SUCCESS
			Else
				Job.Status = CMD_FAILED
			End If	

			'notify:
			If oModule <> Null Then
				CallSubDelayed2(oModule, sEventName & "_JobCompleted", Job)
			End If
		
			'remove job:
			CMD_QUEUE.RemoveAt(CMD_QUEUE.IndexOf(Job))
			CMD_SLOTS.RemoveAt(CMD_SLOTS.IndexOf(Job))
			
			'reenable the queue:
			Timer_Queue.Enabled = True
			
			Exit
		End If
	Next
End Sub
