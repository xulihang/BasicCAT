B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=5.8
@EndOfDesignText@
#Event: ItemClick (Value As String)
#DesignerProperty: Key: HighlightColor, DisplayName: Highlight Color, FieldType: Color, DefaultValue: 0xFFFC1010
#DesignerProperty: Key: TextColor, DisplayName: Text Color, FieldType: Color, DefaultValue: 0xFF000000
'Class module
Sub Class_Globals
	Private fx As JFX
	Private prefixList As Map
	Private substringList As Map
	Private et As TextField
	Private lv As ListView
	Private MIN_LIMIT = 1, MAX_LIMIT = 4 As Int 'doesn't limit the words length. Only the index.
	Private mCallback As Object
	Private mEventName As String
	Private mBase As Pane
	Private highlightColor, textColor As Paint
	Private ROWHEIGHT As Int = 25
	Private tf As TextFlow
	Private CodesMap As Map
End Sub

Public Sub Initialize (vCallback As Object, vEventName As String)
	mEventName = vEventName
	mCallback = vCallback
	prefixList.Initialize
	substringList.Initialize
	tf.Initialize
End Sub

Public Sub DesignerCreateView (Base As Pane, Lbl As Label, Props As Map)
	mBase = Base
	CSSUtils.SetBorder(mBase,0,fx.Colors.Transparent,0)
	highlightColor = Props.Get("HighlightColor")
	textColor = Props.Get("TextColor")
	Sleep(0) 'it is not possible to load a layout while another one is loaded. By using Sleep we wait for the first layout to be loaded.
	mBase.LoadLayout("SearchView")
	'lv.Visible = False
	Dim r As Reflector
	r.Target = et
	r.AddEventFilter("et", "javafx.scene.input.KeyEvent.KEY_PRESSED")
	r.Target = lv
	r.AddEventFilter("lv", "javafx.scene.input.KeyEvent.KEY_PRESSED")
End Sub



Sub et_Filter (EventData As Event)
	Dim jo As JavaObject = EventData
	Dim code As String = jo.RunMethod("getCode", Null)
	If code = "DOWN" And lv.Visible = True And lv.Items.Size > 0 Then
		lv.RequestFocus
		lv.SelectedIndex = 0
		EventData.Consume
	End If
End Sub

Sub lv_Filter (EventData As Event)
	Dim jo As JavaObject = EventData
	Dim code As String = jo.RunMethod("getCode", Null)
	If code = "UP" And lv.SelectedIndex <= 0 Then
		et.RequestFocus
		EventData.Consume
	Else if code = "ENTER" Then
		SelectItem
		EventData.Consume
	End If
End Sub


Public Sub GetBase As Pane
	Return mBase
End Sub

Sub lv_MouseClicked (EventData As MouseEvent)
	SelectItem
End Sub

Sub SelectItem
	Sleep(0) 'let the selected item be updated if needed
	If lv.SelectedIndex > -1 Then
		Dim p As Pane = lv.SelectedItem
		If CodesMap.IsInitialized Then
			et.Text = CodesMap.GetDefault(p.Tag,"")
		End If
		Sleep(0) 'pass et_TextChanged event
		et.SetSelection(et.Text.Length, et.Text.Length)
		lv.Visible = False
		If SubExists(mCallback, mEventName & "_ItemClick") Then
			CallSub3(mCallback, mEventName & "_ItemClick", et.Text,p.Tag)
		End If
	End If
End Sub

Public Sub getText As String
	If et.IsInitialized Then
		Return et.Text
	Else
		Return ""
	End If
End Sub

Public Sub setText(text As String)
	Try
		et.Text=text
	Catch
		Log(LastException)
	End Try
End Sub


Private Sub et_TextChanged (Old As String, New As String)
	lv.Items.Clear
	If New.Length = 0 Or (Old.Length=0 And New.Length>1) Then
		lv.Visible = False
		Return
	End If
	If lv.Visible = False Then lv.Visible = True
	If New.Length < MIN_LIMIT Then Return
	Dim str1, str2 As String
	str1 = New.ToLowerCase
	If str1.Length > MAX_LIMIT Then
		str2 = str1.SubString2(0, MAX_LIMIT)
	Else
		str2 = str1
	End If
	AddItemsToList(prefixList.Get(str2), str1)
	AddItemsToList(substringList.Get(str2), str1)
	If lv.Items.Size=0 Then
		lv.Visible=False
	End If
	lv.PrefHeight = Min(mBase.PrefHeight - et.PrefHeight, Max(5, lv.Items.Size) * (ROWHEIGHT + 9))
End Sub

Private Sub AddItemsToList(li As List, full As String)
	If li.IsInitialized = False Then Return
	For i = 0 To li.Size - 1
		Dim item As String = li.Get(i)
		Dim x As Int = item.ToLowerCase.IndexOf(full)
		If x = -1 Then
			Continue
		End If
		tf.Reset.AddText(item.SubString2(0, x)).SetColor(textColor).AddText(item.SubString2(x, x + full.Length)).SetColor(highlightColor)
		tf.AddText(item.SubString(x + full.Length)).SetColor(textColor)
		Dim p As Pane = tf.CreateTextFlow
		p.Tag = item
		p.PrefHeight = ROWHEIGHT
		lv.Items.Add(p)
	Next
End Sub

'Builds the index and returns an object which you can store as a process global variable
'in order to avoid rebuilding the index when the device orientation changes.
Public Sub SetItems(Items As List) As Object
	Dim startTime As Long
	startTime = DateTime.Now
	Dim noDuplicates As Map
	noDuplicates.Initialize
	prefixList.Clear
	substringList.Clear
	Dim m As Map
	Dim li As List
	For i = 0 To Items.Size - 1
		Dim item As String
		item = Items.Get(i)
		item = item.ToLowerCase
		noDuplicates.Clear
		For start = 0 To item.Length
			Dim count As Int
			count = MIN_LIMIT
			Do While count <= MAX_LIMIT And start + count <= item.Length
				Dim str As String
				str = item.SubString2(start, start + count)
				If noDuplicates.ContainsKey(str) = False Then
					noDuplicates.Put(str, "")
					If start = 0 Then m = prefixList Else m = substringList
					li = m.Get(str)
					If li.IsInitialized = False Then
						li.Initialize
						m.Put(str, li)
					End If
					li.Add(Items.Get(i)) 'Preserve the original case
				End If
				count = count + 1
			Loop
		Next
	Next
	Log("Index time: " & (DateTime.Now - startTime) & " ms (" & Items.Size & " Items)")
	Return Array As Object(prefixList, substringList)
End Sub

Public Sub setLangCodesMap(codes As Map)
	CodesMap=codes
End Sub



