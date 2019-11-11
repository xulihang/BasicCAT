B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private sql1 As SQL
	'Private ser As B4XSerializator
	Private sourceLang As String
	Private targetLang As String
End Sub

'Initializes the store and sets the store file.
Public Sub Initialize (Dir As String, FileName As String,pSourceLang As String,pTargetLang As String)
	sourceLang=pSourceLang
	targetLang=pTargetLang
	If sql1.IsInitialized Then sql1.Close
#if B4J
	sql1.InitializeSQLite(Dir, FileName, True)
#else
	sql1.Initialize(Dir, FileName, True)
#end if
	If File.Exists(File.DirData("BasicCAT"),"wal_enabled.conf") Then
		If File.ReadString(File.DirData("BasicCAT"),"wal_enabled.conf")=0 Then
			sql1.ExecNonQuery("PRAGMA journal_mode = wal")
		End If
	Else
		sql1.ExecNonQuery("PRAGMA journal_mode = wal")
	End If
	
	If checkIsFTSEnabled=False Then
		CreateTable
		createIdx
	Else
		CreateTable
	End If
End Sub

Public Sub Put(source As String, targetMap As Map)
	Dim ser As B4XSerializator
	Dim bytes() As Byte=ser.ConvertObjectToBytes(targetMap)
	sql1.ExecNonQuery2("INSERT OR REPLACE INTO main VALUES(?, ?)", Array (source,bytes))
	sql1.ExecNonQuery2("INSERT OR REPLACE INTO idx VALUES(?, ?, ?)", Array (source,getStringForIndex(source,sourceLang),getStringForIndex(targetMap.Get("text"),targetLang)))
End Sub

Public Sub PutWithTransaction(map1 As Map)
	sql1.BeginTransaction
	For Each source As String In map1.Keys
		Dim targetMap As Map=map1.Get(source)
		Dim ser As B4XSerializator
		Dim bytes() As Byte=ser.ConvertObjectToBytes(targetMap)
		sql1.ExecNonQuery2("INSERT OR REPLACE INTO main VALUES(?, ?)", Array (source,bytes))
		sql1.ExecNonQuery2("INSERT OR REPLACE INTO idx VALUES(?, ?, ?)", Array (source,getStringForIndex(source,sourceLang),getStringForIndex(targetMap.Get("text"),targetLang)))
	Next
	sql1.TransactionSuccessful
End Sub

Public Sub Get(Key As String) As Object
	'Log(Key)
	Dim rs As ResultSet = sql1.ExecQuery2("SELECT value FROM main WHERE key = ?", Array As String(Key))
	Dim result As Object = Null
	If rs.NextRow Then
		Dim ser As B4XSerializator
		result = ser.ConvertBytesToObject(rs.GetBlob2(0))
	End If
	rs.Close
	Return result
End Sub

Public Sub GetDefault(Key As String, DefaultValue As Object) As Object
	Dim res As Object = Get(Key)
	If res = Null Then Return DefaultValue
	Return res
End Sub

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
	sql1.ExecNonQuery("CREATE VIRTUAL TABLE IF NOT EXISTS idx USING fts4(key, source, target, notindexed=key)")
End Sub


Sub createIdx
	Dim resultMap As Map = asMap
	sql1.BeginTransaction
	For Each key As String In resultMap.Keys
		Dim targetMap As Map=resultMap.Get(key)
		sql1.ExecNonQuery2("INSERT OR REPLACE INTO idx VALUES(?, ?, ?)", Array (key, getStringForIndex(key,sourceLang),getStringForIndex(targetMap.Get("text"),targetLang)))
	Next
	sql1.TransactionSuccessful
End Sub

'Returns the database as a map.
Public Sub asMap As Map
	Dim map1 As Map
	map1.Initialize
	Dim c As ResultSet = sql1.ExecQuery("SELECT * FROM main")
	Do While c.NextRow
		Dim result As Object
		Dim ser As B4XSerializator
		result = ser.ConvertBytesToObject(c.GetBlob2(1))
		map1.Put(c.GetString2(0),result)
	Loop
	c.Close
	Return map1
End Sub

Sub checkIsFTSEnabled As Boolean
	Try
		sql1.ExecQuery("SELECT * FROM idx")
		Return True
	Catch
		Log(LastException)
		Return False
	End Try
End Sub

Public Sub GetMatchedMapAsync(text As String,isSource As Boolean,matchAll As Boolean) As ResumableSub
	'Dim maxLength As Int=text.Length*2
	Dim sqlStr As String
	Dim matchTarget As String
	Dim operator As String
	Dim lang As String
	Dim words As List
	words.Initialize
	If isSource Then
		lang=sourceLang
		matchTarget="source"
	Else
		lang=targetLang
		matchTarget="target"
	End If
	If matchAll Then
		matchTarget="idx"
		operator="AND"
		If text.StartsWith($"""$) And text.EndsWith($"""$) Then
			words.Add(text)
		Else
			words=getWordsForAll(text)
		End If
	Else
		operator="OR"
		words=LanguageUtils.TokenizedList(text,lang)
	End If
	text=getQuery(words,operator)
	
	sqlStr="SELECT key, rowid, quote(matchinfo(idx)) as rank FROM idx WHERE "&matchTarget&" MATCH '"&text&"' ORDER BY rank DESC LIMIT 1000 OFFSET 0"
	Log(sqlStr)
	Dim SenderFilter As Object = sql1.ExecQueryAsync("SQL", sqlStr, Null)
	Wait For (SenderFilter) SQL_QueryComplete (Success As Boolean, rs As ResultSet)
	Dim resultMap As Map
	resultMap.Initialize
	Dim result As Object = Null
	If Success Then
		Do While rs.NextRow
			result=GetDefault(rs.GetString2(0),Null)
			If result<>Null Then
				resultMap.Put(rs.GetString2(0),result)
			Else
				Log("not exist")
				DeleteIdxRow(rs.GetInt2(1))
			End If
		Loop
		rs.Close
	Else
		Log(LastException)
	End If
	Return resultMap
End Sub

Sub DeleteIdxRow(rowid As Int)
	Log(rowid)
	sql1.ExecNonQuery("DELETE FROM idx WHERE rowid = "&rowid)
End Sub

Sub getWordsForAll(text As String) As List
	Dim words As List
	words.Initialize
	words.AddAll(LanguageUtils.TokenizedList(text,sourceLang))
	words.AddAll(LanguageUtils.TokenizedList(text,targetLang))
	Utils.removeDuplicated(words)
	LanguageUtils.removeCharacters(words)
	LanguageUtils.removeMultiBytesWords(words)
	Return words
End Sub

Sub getQuery(words As List,operator As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	For index =0 To words.Size-1
		Dim word As String=words.Get(index)
		If word.Trim<>"" Then
			sb.Append(word)
			If index<>words.Size-1 Then
				sb.Append(" "&operator&" ") ' AND OR NOT
			End If
		End If
	Next
	Return sb.ToString
End Sub

Sub getStringForIndex(source As String,lang As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim words As List=LanguageUtils.TokenizedList(source,lang)
	For index =0 To words.Size-1
		sb.Append(words.Get(index)).Append(" ")
	Next
	Return sb.ToString.Trim
End Sub