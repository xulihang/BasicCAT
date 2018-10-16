B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private paramsTableView As TableView
	Private params As Map
	Private originalParams As Map
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(engineName As String,preferencesMap As Map)
	frm.Initialize("frm",300,300)
	frm.RootPane.LoadLayout("mtparamfiller")
	params.Initialize
	originalParams.Initialize

	Dim mtmap As Map
	mtmap.Initialize
	If preferencesMap.ContainsKey("mt") Then
		mtmap=preferencesMap.Get("mt")
		If mtmap.ContainsKey(engineName) Then
			params=mtmap.Get(engineName)
			' should not use originalParams=params
			For Each key As String In params.Keys
				originalParams.Put(key,params.Get(key))
			Next
		End If
	End If
	init(engineName)
End Sub

Public Sub showAndWait As Map
    frm.ShowAndWait
	Return params
End Sub

Sub init(engineName As String)
	Select engineName
		Case "baidu"
			paramsTableView.SetColumns(Array As String("param","value"))
			
			Dim Row1() As Object
			If params.ContainsKey("appid") Then
				Row1=Array ("appid", params.Get("appid"))
			Else
				Row1=Array ("appid", "")
			End If
			paramsTableView.Items.Add(Row1)
			params.Put(Row1(0),Row1(1))
			
			Dim Row2() As Object
			If params.ContainsKey("key") Then
				Row2=Array ("key", params.Get("key"))
			Else
				Row2=Array ("key", "")
			End If
			paramsTableView.Items.Add(Row2)
			params.Put(Row2(0),Row2(1))
		Case "yandex"
			paramsTableView.SetColumns(Array As String("param","value"))
			
			Dim Row1() As Object
			If params.ContainsKey("key") Then
				Row1=Array ("key", params.Get("key"))
			Else
				Row1=Array ("key", "")
			End If
			paramsTableView.Items.Add(Row1)
			params.Put(Row1(0),Row1(1))
		Case "youdao"
			paramsTableView.SetColumns(Array As String("param","value"))
			
			Dim Row1() As Object
			If params.ContainsKey("appid") Then
				Row1=Array ("appid", params.Get("appid"))
			Else
				Row1=Array ("appid", "")
			End If
			paramsTableView.Items.Add(Row1)
			params.Put(Row1(0),Row1(1))
			
			Dim Row2() As Object
			If params.ContainsKey("key") Then
				Row2=Array ("key", params.Get("key"))
			Else
				Row2=Array ("key", "")
			End If
			paramsTableView.Items.Add(Row2)
			params.Put(Row2(0),Row2(1))
		Case "google"
			paramsTableView.SetColumns(Array As String("param","value"))
			
			Dim Row1() As Object
			If params.ContainsKey("key") Then
				Row1=Array ("key", params.Get("key"))
			Else
				Row1=Array ("key", "")
			End If
			paramsTableView.Items.Add(Row1)
			params.Put(Row1(0),Row1(1))
	End Select
End Sub

Sub cancelButton_MouseClicked (EventData As MouseEvent)
	params=originalParams
	frm.Close
End Sub

Sub SaveButton_MouseClicked (EventData As MouseEvent)
	frm.Close
End Sub

Sub paramsTableView_MouseClicked (EventData As MouseEvent)
	If paramsTableView.SelectedRowValues<>Null Then
		Dim inpBox As InputBox
		inpBox.Initialize
		Dim row() As Object
		row=paramsTableView.Items.Get(paramsTableView.SelectedRow)
		row(1)=inpBox.showAndWait
		paramsTableView.Items.Set(paramsTableView.SelectedRow,row)
		params.Put(paramsTableView.SelectedRowValues(0),row(1))
	End If
End Sub