B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.01
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

'Adds the specified file extenstions.
'There must be the same number of Descriptions as Filters.
Public Sub AddExtensionFilters(FC As FileChooser, Descriptions As List, Filters As List)
	AddExtensionFilters4(FC,Descriptions, Filters, False,"", False)
End Sub

'Adds the specified file extenstions and optional merged item.
'There must be the same number of Descriptions as Filters.
Public Sub AddExtensionFilters2(FC As FileChooser, Descriptions As List, Filters As List, MergeName As String)
	AddExtensionFilters4(FC,Descriptions, Filters, True, MergeName, False)
End Sub

'Adds the specified file extenstions and optional AllFIles item.
'There must be the same number of Descriptions as Filters.
Public Sub AddExtensionFilters3(FC As FileChooser, Descriptions As List, Filters As List, AllFiles As Boolean)
	AddExtensionFilters4(FC,Descriptions, Filters, False, "", AllFiles)
End Sub

'Adds the specified file extenstions and optional merged item and optional All Files item.
'There must be the same number of Descriptions as Filters.
Public Sub AddExtensionFilters4(FC As FileChooser, Descriptions As List, Filters As List, Merge As Boolean, MergeName As String, AllFiles As Boolean)
	If Descriptions.Size <> Filters.Size Then
		Log("Extension filters not added")
		Return
	End If
	Dim ExtFilters As List
	ExtFilters.Initialize

	If AllFiles Then
		Dim ExtensionFilter As JavaObject
		ExtensionFilter.InitializeNewInstance("javafx.stage.FileChooser.ExtensionFilter",Array("All Files",Array As String("*.*")))
		ExtFilters.add(ExtensionFilter)
	End If

	If Merge Then
		Dim ExtensionFilter As JavaObject
		ExtensionFilter.InitializeNewInstance("javafx.stage.FileChooser.ExtensionFilter",Array(MergeName,Filters))
		ExtFilters.add(ExtensionFilter)
	End If

	For i = 0 To Filters.Size - 1
		Dim ExtensionFilter As JavaObject
		ExtensionFilter.InitializeNewInstance("javafx.stage.FileChooser.ExtensionFilter",Array(Descriptions.Get(i),Array As String(Filters.Get(i))))
		ExtFilters.add(ExtensionFilter)
	Next
	Dim FCJO As JavaObject = FC
	Dim EFs As List = FCJO.RunMethod("getExtensionFilters",Null)
	EFs.AddAll(ExtFilters)
End Sub

'Pass the Description to specify the initially selected file extension.  
'Pass the MergeName or 'All Files' if you use these options and want either to be preselected
Public Sub SetSelectedExtensionFilter(FC As FileChooser, Description As String)
	Dim FCJO As JavaObject = FC
	Dim EFs As List = FCJO.RunMethod("getExtensionFilters",Null)
	For Each EF As JavaObject In EFs
		If EF.RunMethod("getDescription",Null) = Description Then
			FCJO.RunMethod("setSelectedExtensionFilter",Array(EF))
			Exit
		End If
	Next
End Sub