B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private gitJO As JavaObject
	Private gitJOStatic As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(path As String)
	gitJOStatic.InitializeStatic("org.eclipse.jgit.api.Git")
	If File.Exists(path,".git")=False Then
		Log("init")
		init(path)
	End If
	gitJO=gitJOStatic.RunMethodJO("open",Array(getFile(path)))
End Sub

Sub getFile(path As String) As JavaObject
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array(path))
	Return fileJO
End Sub

Public Sub init(path As String)
	gitJOStatic.RunMethodJO("init",Null).RunMethodJO("setDirectory",Array(getFile(path))).RunMethodJO("call",Null)
End Sub

Public Sub add(files As String)
	gitJO.RunMethodJO("add",Null).RunMethodJO("addFilepattern",Array(files)).RunMethodJO("call",Null)
End Sub

public Sub commit(message As String,name As String,email As String)
	Dim commitCommand As JavaObject
	commitCommand=gitJO.RunMethodJO("commit",Null)
	If name<>"" Then
		commitCommand.RunMethod("setCommitter",Array As String(name,email))
		commitCommand.RunMethod("setAuthor",Array As String(name,email))
		commitCommand.RunMethod("setAll",Array(True))
	End If
	commitCommand.RunMethodJO("setMessage",Array(message)).RunMethodJO("call",Null)
End Sub

Public Sub diffList As List
	Return  gitJO.RunMethodJO("diff",Null).RunMethod("call",Null)
End Sub