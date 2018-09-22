B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.5
@EndOfDesignText@
'KeyValueStore: v2.20
Sub Class_Globals
	Private sql1 As SQL
	Private ser As B4XSerializator
End Sub

'Initializes the store and sets the store file.
Public Sub Initialize (Dir As String, FileName As String)
	If sql1.IsInitialized Then sql1.Close
#if B4J
	sql1.InitializeSQLite(Dir, FileName, True)
#else
	sql1.Initialize(Dir, FileName, True)
#end if
	CreateTable
End Sub

Public Sub Put(Key As String, Value As Object)
	sql1.ExecNonQuery2("INSERT OR REPLACE INTO main VALUES(?, ?)", Array (Key, ser.ConvertObjectToBytes(Value)))
End Sub

Public Sub Get(Key As String) As Object
	Dim rs As ResultSet = sql1.ExecQuery2("SELECT value FROM main WHERE key = ?", Array As String(Key))
	Dim result As Object = Null
	If rs.NextRow Then
		result = ser.ConvertBytesToObject(rs.GetBlob2(0))
	End If
	rs.Close
	Return result
End Sub

'Asynchronously retrieves the values from the store.
'The result is a map with the keys and values.
'<code>
'Wait For (Starter.kvs.GetMapAsync(Array("2 custom types", "time"))) Complete (Result As Map)
'</code>
Public Sub GetMapAsync (Keys As List) As ResumableSub
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("SELECT key, value FROM main WHERE ")
	For i = 0 To Keys.Size - 1
		If i > 0 Then sb.Append(" OR ")
		sb.Append(" key = ? ")
	Next
	Dim SenderFilter As Object = sql1.ExecQueryAsync("SQL", sb.ToString, Keys)
	Wait For (SenderFilter) SQL_QueryComplete (Success As Boolean, rs As ResultSet)
	Dim m As Map
	m.Initialize
	If Success Then
		Do While rs.NextRow
			Dim myser As B4XSerializator
			myser.ConvertBytesToObjectAsync(rs.GetBlob2(1), "myser")
			Wait For (myser) myser_BytesToObject (Success As Boolean, NewObject As Object)
			If Success Then
				m.Put(rs.GetString2(0), NewObject)	
			End If
		Loop
		rs.Close
	Else
		Log(LastException)
	End If
	Return m
End Sub

'Asynchronously inserts the keys and values from the map.
'Note that each pair is inserted as a separate item.
'Call it with Wait For if you want to wait for the insert to complete.
Public Sub PutMapAsync (Map As Map) As ResumableSub
	For Each key As String In Map.Keys
		Dim myser As B4XSerializator
		myser.ConvertObjectToBytesAsync(Map.Get(key), "myser")
		Wait For (myser) myser_ObjectToBytes (Success As Boolean, Bytes() As Byte)
		If Success Then
			sql1.AddNonQueryToBatch("INSERT OR REPLACE INTO main VALUES(?, ?)", Array(key, Bytes))
		Else
			Log("Failed to serialize object: " & Map.Get(key))
		End If
	Next
	Dim SenderFilter As Object = sql1.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Return Success
End Sub

Public Sub GetDefault(Key As String, DefaultValue As Object) As Object
	Dim res As Object = Get(Key)
	If res = Null Then Return DefaultValue
	Return res
End Sub

Public Sub PutEncrypted (Key As String, Value As Object, Password As String)
#if B4I
	Dim cipher As Cipher
#else
	Dim cipher As B4XCipher
#end if
	Put(Key, cipher.Encrypt(ser.ConvertObjectToBytes(Value), Password))
End Sub


Public Sub GetEncrypted (Key As String, Password As String) As Object
#if B4I
	Dim cipher As Cipher
#else
	Dim cipher As B4XCipher
#end if
	Dim b() As Byte = Get(Key)
	If b = Null Then Return Null
	Return ser.ConvertBytesToObject(cipher.Decrypt(b, Password))
End Sub

#if not(B4J)
Public Sub PutBitmap(Key As String, Value As Bitmap)
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Value.WriteToStream(out, 100, "PNG")
	Put(Key, out.ToBytesArray)
	out.Close
End Sub

Public Sub GetBitmap(Key As String) As Bitmap
	Dim b() As Byte = Get(Key)
	If b = Null Then Return Null
	Dim in As InputStream
	in.InitializeFromBytesArray(b, 0, b.Length)
	Dim bmp As Bitmap
	bmp.Initialize2(in)
	in.Close
	Return bmp
End Sub
#End If

'Removes the key and value mapped to this key.
Public Sub Remove(Key As String)
	sql1.ExecNonQuery2("DELETE FROM main WHERE key = ?", Array As Object(Key))
End Sub

'Returns a list with all the keys.
Public Sub ListKeys As List
	Dim c As ResultSet = sql1.ExecQuery("SELECT key FROM main")
	Dim res As List
	res.Initialize
	Do While c.NextRow
		res.Add(c.GetString2(0))
	Loop
	c.Close
	Return res
End Sub

'Tests whether a key is available in the store.
Public Sub ContainsKey(Key As String) As Boolean
	Return sql1.ExecQuerySingleResult2("SELECT count(key) FROM main WHERE key = ?", _
		Array As String(Key)) > 0
End Sub

'Deletes all data from the store.
Public Sub DeleteAll
	sql1.ExecNonQuery("DROP TABLE main")
	CreateTable
End Sub


'Closes the store.
Public Sub Close
	sql1.Close
End Sub


'creates the main table (if it does not exist)
Private Sub CreateTable
	sql1.ExecNonQuery("CREATE TABLE IF NOT EXISTS main(key TEXT PRIMARY KEY, value NONE)")
End Sub



