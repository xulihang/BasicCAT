B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4.19
@EndOfDesignText@

Sub Process_Globals
	Private sql As SQL
	Private lock As ReadWriteLock
End Sub

Public Sub Init
	sql.InitializeSQLite( File.DirApp, "serverdb.db", True)
	CreateDatabase
	lock.Initialize
End Sub

Private Sub CreateDatabase
	If sql.ExecQuerySingleResult("SELECT count(name) FROM sqlite_master WHERE type='table' AND name='data'") = 0 Then
		sql.ExecNonQuery("PRAGMA journal_mode = wal") 'best mode for multithreaded apps.
		Log("Creating new database!")
		Log($"journal mode: ${sql.ExecQuerySingleResult("PRAGMA journal_mode")}"$)
		sql.ExecNonQuery("CREATE TABLE data (user TEXT, key TEXT, value BLOB, id INTEGER, time INTEGER, PRIMARY KEY (user, key))")
		sql.ExecNonQuery("CREATE INDEX id_index ON data (id)")
	End If
End Sub

Public Sub AddItem(item As Item)
	lock.WriteLock
	Try
		Dim lastId As String = sql.ExecQuerySingleResult2("SELECT max(id) FROM data WHERE user = ?", Array(item.UserField))
		If lastId = Null Then lastId = 0
		Dim id As Long = lastId + 1
		If item.TimeField < DateTime.Now - 3 * DateTime.TicksPerMinute Then
			Log("checking old record")
			'this is an old record. Maybe there is a newer one...
			Dim rs As ResultSet = sql.ExecQuery2("SELECT time, value FROM data WHERE user = ? AND key = ?", Array(item.UserField, item.KeyField))
			If rs.NextRow Then
				Dim currentTime As Long = rs.GetLong("time")
				If currentTime > item.TimeField Then
					Log("Old record discarded.")
					item.ValueField = rs.GetBlob("value")
					item.TimeField = currentTime
				End If
			End If
			rs.Close
		End If
		
		sql.ExecNonQuery2("INSERT OR REPLACE INTO data VALUES (?, ?, ?, ?, ?)",  _
			Array (item.UserField, item.KeyField, item.ValueField, id, Min(item.TimeField, DateTime.Now)))
	Catch
		Log(LastException)
	End Try
	lock.WriteRelease
End Sub



Public Sub GetUserItemsSize (user As String) As Int
    Dim num As Int=0
	Dim rs As ResultSet = sql.ExecQuery2("SELECT key, value, id, time FROM data WHERE user = ?", Array(user))
	Do While rs.NextRow
		num=num+1
	Loop
	rs.Close
	Return num
End Sub

Public Sub GetUserItems (user As String, lastId As Int) As List
	Dim items As List
	items.Initialize
	Dim rs As ResultSet = sql.ExecQuery2("SELECT key, value, id, time FROM data WHERE user = ? AND id > ?", Array(user, lastId))
	Do While rs.NextRow
		Dim item As Item
		item.Initialize
		item.UserField = user
		item.KeyField = rs.GetString("key")
		item.ValueField = rs.GetBlob("value")
		item.idField = rs.GetLong("id")
		item.TimeField = rs.GetLong("time")
		items.Add(item)
	Loop
	rs.Close
	Return items
End Sub


Public Sub DeleteUser(user As String)
	lock.WriteLock
	Try
		sql.ExecNonQuery2("DELETE FROM data WHERE user = ?", Array(user))
	Catch
		Log(LastException)
	End Try
	lock.WriteRelease
End Sub