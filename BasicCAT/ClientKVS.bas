B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
'version: 1.00
#Event: NewData
Sub Class_Globals
	Private sql As SQL
	Private url As String
	Private SendingJob As Boolean
	Private csu As CallSubUtils
	Private autoRefreshTimer As Timer
	Private AutoRefreshUsers As List
	Private mCallback As Object
	Private mEventName As String
	Private changedItems As List
End Sub

'Initializes the client.
Public Sub Initialize (Callback As Object, EventName As String, ServerUrl As String,dir As String,filename As String)
	csu.Initialize
	changedItems.Initialize
#if B4J
	sql.InitializeSQLite(dir, filename, True)
#else if B4A
	sql.Initialize(File.DirInternal, "db.db", True)
#else if B4i
	sql.Initialize(File.DirLibrary, "db.db", True)
#end if
	CreateDatabase
	url = ServerUrl & "/action"
	autoRefreshTimer.Initialize("AutoRefresh", 1000)
	mCallback = Callback
	mEventName = EventName
	HandleQueue
	If False Then CallSub(Me, "HandleQueue") 'to avoid obfuscation issues
End Sub

Private Sub CreateDatabase
	If sql.ExecQuerySingleResult("SELECT count(name) FROM sqlite_master WHERE type='table' AND name='data'") = 0 Then
		Log("Creating new database!")
		sql.ExecNonQuery("CREATE TABLE data (user TEXT, key TEXT, value BLOB, id INTEGER, time INTEGER, PRIMARY KEY (user, key))")
		sql.ExecNonQuery("CREATE INDEX id_index ON data (id)")
		sql.ExecNonQuery("CREATE TABLE queue (qid INTEGER PRIMARY KEY AUTOINCREMENT, task BLOB, taskname TEXT, user TEXT, key TEXT)")
		sql.ExecNonQuery("CREATE INDEX id_index2 ON queue (user, key)")
	End If
End Sub

Private Sub HandleQueue
	If SendingJob = True Then
		Return
	End If
	Dim rs As ResultSet = sql.ExecQuery("SELECT qid, task, taskname FROM queue ORDER BY qid")
	If rs.NextRow Then
		Dim queue_id As Long = rs.GetLong("qid")
		Dim Job As HttpJob
		Job.Initialize("job", Me)
		Job.PostBytes(url,rs.GetBlob("task"))
		Job.Tag = CreateMap("queue_id": queue_id, "taskname": rs.GetString("taskname"))
		SendingJob = True
	End If
	
	rs.Close
End Sub

Private Sub JobDone(job As HttpJob)
	SendingJob = False
	If job.Success Then
		Dim m As Map = job.Tag
		Dim taskname As String = m.Get("taskname")
		Dim queue_id As Long = m.Get("queue_id")
		If taskname.StartsWith("getuser") Then
			Dim ser As B4XSerializator
			ser.Tag = m
			ser.ConvertBytesToObjectAsync(Bit.InputStreamToBytes(job.GetInputStream), "ser")
		Else
			DeleteFromQueue(queue_id)
			HandleQueue
		End If
	Else
		Log($"Error sending task: ${job.ErrorMessage}"$)
		csu.CallSubDelayedPlus(Me, "HandleQueue", 30000)
	End If
	job.Release
End Sub

Private Sub ser_BytesToObject (Success As Boolean, NewObject As Object)
	Dim ser As B4XSerializator = Sender
	Dim m As Map = ser.Tag
	If Success Then
		Dim items As List = NewObject
		If items.Size > 0 Then
			For Each item1 As Item In items
				changedItems.Add(item1)
				InsertItemIntoData(item1, True)
			Next
			sql.ExecNonQueryBatch("getuser")
		End If
	Else
		Log("Error reading server response")
	End If
	DeleteFromQueue(m.Get("queue_id"))
	HandleQueue
End Sub

Private Sub GetUser_NonQueryComplete (Success As Boolean)
	If Not(Success) Then
		Log("Error writing to database: " & LastException)
	End If
	CallSub2(mCallback, mEventName & "_newdata",changedItems)
End Sub

Private Sub InsertItemIntoData(item As Item, async As Boolean)
	Dim cmd1 As String = "INSERT OR REPLACE INTO data VALUES (?, ?, ?, ?, ?)"
	Dim args As List = Array (item.UserField, item.KeyField, item.ValueField, item.idField, item.TimeField)
	If async Then
		sql.AddNonQueryToBatch(cmd1, args)
	Else
		sql.ExecNonQuery2(cmd1, args)
	End If
End Sub

Private Sub DeleteFromQueue(qid As Long)
	sql.ExecNonQuery2("DELETE FROM queue WHERE qid = ?", Array(qid))
End Sub

'Utility methods that prints the database.
Public Sub UtilPrintData
	Dim rs As ResultSet = sql.ExecQuery("SELECT distinct(user) FROM data")
	Do While rs.NextRow
		Dim user As String = rs.GetString("user")
		Log($" **** User: ${user} ****"$)
		Dim m As Map = GetAll(user)
		For Each key As String In m.Keys
			Log($"${key} -> ${m.Get(key)}"$)
		Next
	Loop
	rs.Close
End Sub



'Puts an item in the store.
'User - The item's group.
'Key - The item's key.
'Value - The item's value. The value will be serialized with B4XSerializator. Pass Null to "delete" this key.
'The item is added to the local store and then uploaded to the remote store.
Public Sub Put(user As String, key As String, Value As Object)
	Put2(user, key, Value, False)
End Sub

'Similar to Put. If the IsDefault parameter is set to True then the item will not replace an existing item on the server.
Public Sub Put2 (user As String, key As String, Value As Object, IsDefault As Boolean)
	Dim item As Item = CreateItem(user, key, ObjectToBytes(Value))
	If IsDefault Then item.TimeField = 0
	sql.BeginTransaction
	Try
		InsertItemIntoData(item, False)
		Dim task1 As Task
		task1.Initialize
		task1.TaskName = "additem"
		task1.TaskItem = item
		sql.ExecNonQuery2("DELETE FROM queue WHERE user = ? AND key = ?", Array (user, key))
		AddTaskToQueue(task1)
		sql.TransactionSuccessful
	Catch
#if B4J or B4I
		sql.Rollback
#end if
		Log(LastException)
	End Try
#if B4A
	sql.EndTransaction
#end if
	HandleQueue
End Sub

Private Sub ObjectToBytes (o As Object) As Byte()
	If o = Null Then Return Null
	Dim ser As B4XSerializator
	Return ser.ConvertObjectToBytes(o)
End Sub

Private Sub BytesToObject(b() As Byte) As Object
	If b = Null Or b.Length = 0 Then Return Null
	Dim ser As B4XSerializator
	Return ser.ConvertBytesToObject(b)
End Sub


Private Sub AddTaskToQueue(task As Task)
	Dim ser As B4XSerializator
	sql.ExecNonQuery2("INSERT INTO queue VALUES (NULL, ?, ?, ?, ?)", _
		 Array(ser.ConvertObjectToBytes(task), task.TaskName, task.TaskItem.UserField, task.TaskItem.KeyField))
End Sub

'Gets the value of the item with the given user and key fields.
'Returns Null if there is no such item.
'The data is always fetched from the local store.
Public Sub Get(User As String, Key As String) As Object
	Dim rs As ResultSet = sql.ExecQuery2("SELECT value FROM data WHERE user = ? AND key = ?", Array As String(User, Key))
	Dim result As Object = Null
	If rs.NextRow Then
		result = BytesToObject(rs.GetBlob2(0))
	End If
	rs.Close
	Return result
End Sub

'Similar to Get. Returns the DefaultValue if no item was found.
Public Sub GetDefault(User As String, Key As String, DefaultValue As Object) As Object
	Dim o As Object = Get(User, Key)
	If o = Null Then Return DefaultValue Else Return o
End Sub

'Similar to Get. If the item was not found then it puts the DefaultValue in the database and returns it.
Public Sub GetDefaultAndPut(User As String, Key As String, DefaultValue As Object) As Object
	Dim o As Object = Get(User, Key)
	If o = Null Then
		Put2(User, Key, DefaultValue, True)
		Return DefaultValue 
	Else
		Return o
	End If
End Sub

'Returns true if there is an item mapped to the given user and key.
Public Sub ContainsKey (User As String, Key As String) As Boolean
	Return Get(User, Key) <> Null
End Sub

'Enables the auto refresh timer. 
'users - List (or array) of the user names that will be auto refreshed.
'IntervalMinutes - Interval between the refreshes.
Public Sub SetAutoRefresh(users As List, IntervalMinutes As Double)
	AutoRefreshUsers = users
	autoRefreshTimer.Interval = IntervalMinutes * DateTime.TicksPerMinute
	autoRefreshTimer.Enabled = True
	AutoRefresh_Tick
End Sub

Private Sub AutoRefresh_Tick
	For Each user As String In AutoRefreshUsers
		If sql.ExecQuerySingleResult2("SELECT count(*) FROM queue WHERE taskname = ?", Array As String("getuser_" & user)) = 0 Then
			changedItems.Clear
			RefreshUser(user)	
		End If
	Next
End Sub

'Sends a refresh request for the given user.
Public Sub RefreshUser(user As String)
	Dim task1 As Task
	task1.Initialize
	task1.TaskName = "getuser_" & user
	Dim lastId As String = sql.ExecQuerySingleResult2("SELECT max(id) FROM data WHERE user = ?", Array As String(user))
	If lastId = Null Then lastId = 0
	task1.TaskItem = CreateItem(user, lastId, Null)
	AddTaskToQueue(task1)
	HandleQueue
End Sub

'Returns a map with the keys and values of the given user.
Public Sub GetAll(user As String) As Map
	Dim res As Map
	res.Initialize
	Dim ser As B4XSerializator
	Dim rs As ResultSet = sql.ExecQuery2("SELECT key, value FROM data WHERE user = ? AND value IS NOT NULL", Array As String(user))
	Do While rs.NextRow
		res.Put(rs.GetString("key"), ser.ConvertBytesToObject(rs.GetBlob("value")))
	Loop
	rs.Close
	Return res
End Sub

Private Sub CreateItem (user As String, key As String, value() As Byte) As Item
	Dim i As Item
	i.Initialize
	i.UserField = user
	i.KeyField = key
	i.ValueField = value
	i.idField = -1
	i.TimeField = DateTime.Now
	Return i
End Sub