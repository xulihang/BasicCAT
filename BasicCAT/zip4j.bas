B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private th As Thread
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	th.Initialise("th")
End Sub

Public Sub unzipAsync(dir As String,filename As String,outdir As String) As ResumableSub
	th.Start(Me,"unzip",Array As Object(dir,filename,outdir))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Return endedOK
End Sub

Public Sub zipFilesAsync(inDir As String,outDir As String,zipFilename As String) As ResumableSub
	th.Start(Me,"zipFiles",Array As Object(inDir,outDir,zipFilename))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Return endedOK
End Sub

Public Sub unzip(dir As String,filename As String,outdir As String)
	Dim zipFile As JavaObject
	zipFile.InitializeNewInstance("net.lingala.zip4j.core.ZipFile",Array(File.Combine(dir,filename)))
	zipFile.RunMethod("extractAll",Array(outdir))
End Sub

Public Sub zipFiles(inDir As String,outDir As String,zipFilename As String)
	If File.Exists(outDir,zipFilename) Then
		File.Delete(outDir,zipFilename)
	End If
	Dim zipFile As JavaObject
	zipFile.InitializeNewInstance("net.lingala.zip4j.core.ZipFile",Array(File.Combine(outDir,zipFilename)))
	Dim constants As JavaObject
	constants.InitializeStatic("net.lingala.zip4j.util.Zip4jConstants")
	Dim params As JavaObject
	params.InitializeNewInstance("net.lingala.zip4j.model.ZipParameters",Null)
	params.RunMethod("setCompressionMethod",Array(constants.GetField("COMP_DEFLATE")))
	params.RunMethod("setCompressionLevel",Array(constants.GetField("DEFLATE_LEVEL_NORMAL")))
	For Each filename In File.ListFiles(inDir)
		Dim path As String
		path=File.Combine(inDir,filename)
		If File.IsDirectory(inDir,filename) Then
			zipFile.RunMethod("addFolder",Array(path,params))
		Else
			zipFile.RunMethod("addFile",Array(getFile(path),params))
		End If
	Next
End Sub

Sub getFile(path As String) As JavaObject
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array(path))
	Return fileJO
End Sub
