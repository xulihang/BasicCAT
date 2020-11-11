B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6
@EndOfDesignText@
#IgnoreWarnings:12

Sub Process_Globals

	Private fx As JFX

End Sub

Sub createNonExistingDir(path As String)
	path=File.GetFileParent(path)
	Dim seperator As String=GetSystemProperty("file.separator","/")
	path=path.Replace(seperator,CRLF)
	Dim seperated As List
	seperated.Initialize
	seperated.addall(Regex.Split(CRLF,path))
	Dim newPath As String
	For Each item As String In seperated
		newPath=newPath&item&seperator
		If File.Exists(newPath,"")=False Then
			File.MakeDir(newPath,"")
		End If
	Next
End Sub

'Similar to File.Copy() but also folders with content can be copied
Sub Copy(DirSource As String, FileSource As String, DirTarget As String, FileTarget As String)
	If File.IsDirectory(DirSource, FileSource) Then
		Dim sourcePath As String = File.Combine(DirSource, FileSource)
		Dim targetPath As String = File.Combine(DirTarget, FileTarget)
		Dim sourceFiles As List = File.ListFiles(sourcePath)
		If sourceFiles.IsInitialized = False Then Return 'Return if folder is not accessible
		File.MakeDir(DirTarget, FileTarget)
		For Each name As String In sourceFiles
			Copy(sourcePath, name, targetPath, name) '+26/06/18
		Next
	Else
		File.Copy(DirSource, FileSource, DirTarget, FileTarget)
	End If
End Sub

'Similar to File.CopyAsync() but also folders with content can be copied
Public Sub CopyAsync (DirSource As String, FileSource As String, DirTarget As String, FileTarget As String) As ResumableSub '+26/06/18
	Dim innerSuccess As Boolean = True
	Dim sourcePath As String = File.Combine(DirSource, FileSource)
	Dim targetPath As String = File.Combine(DirTarget, FileTarget)
	If File.IsDirectory(DirSource, FileSource) Then
		Dim sourceFiles As List = File.ListFiles(sourcePath)
		If sourceFiles.IsInitialized = False Then Return False 'Return false if folder is not accessible
		File.MakeDir(DirTarget, FileTarget)
		For Each name As String In sourceFiles
			Dim obj As Object = CopyAsync(sourcePath, name, targetPath, name)
			Wait For (obj) Complete (Success As Boolean)
			innerSuccess = innerSuccess And Success
		Next
	Else
		Dim obj1 As Object = File.CopyAsync(sourcePath, name, targetPath, name)
		Wait For (obj1) Complete (Success As Boolean)
		innerSuccess = innerSuccess And Success
	End If
	Return innerSuccess
End Sub

'Similar to File.Delete() but also folders with content can be deleted
Sub Delete(Folder As String, FileName As String)
	If File.IsDirectory(Folder, FileName) Then
		Dim completePath As String = File.Combine(Folder, FileName)
		Dim files As List = File.ListFiles(completePath)
		For Each name As String In files
			If File.IsDirectory(completePath, name) Then
				Delete(completePath, name)
			End If
			File.Delete(completePath, name)
		Next
	End If
	File.Delete(Folder, FileName)
End Sub

Sub RenameTo(Folder As String, FileName As String, NewFileName As String) '+10/07/18
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File", Array(File.Combine(Folder, FileName)))
	Dim newFileJO As JavaObject
	newFileJO.InitializeNewInstance("java.io.File", Array(File.Combine(Folder, NewFileName)))
	fileJO.RunMethod("renameTo", Array(newFileJO))
End Sub

'Return a list of all the paths of the subfolders in rootFolder.
'The list will not contain RootFolder
Sub GetSubFolders(RootFolder As String) As List
	Dim subFolders As List
	subFolders.Initialize
	ExtractSubFolders(RootFolder, subFolders)
	Return subFolders
End Sub

'Extract subfolders from RootFolder recursively.
'Subfolder paths will be added to SubFolders
'Sub Folders will not contain RootFolder
Private Sub ExtractSubFolders(RootFolder As String, SubFolders As List)
	Dim tempList As List = File.ListFiles(RootFolder)
	For i = 0 To tempList.Size-1
		Dim watchedElement 	As String = tempList.Get(i)
		If File.IsDirectory(RootFolder, watchedElement) Then
			Dim newPath As String = File.Combine(RootFolder, watchedElement)
			SubFolders.Add(newPath)
			ExtractSubFolders(newPath,SubFolders)
		End If
	Next
End Sub

Sub GetFileCreation(dir As String,filename As String) As Long
	Dim jo As JavaObject=Me
	Return jo.RunMethod("getCreation",Array(File.Combine(dir,filename)))
End Sub

#if java
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
public static long getCreation(String filePath) throws IOException {
    File myfile = new File(filePath);
    Path path = myfile.toPath();
    BasicFileAttributes fatr = Files.readAttributes(path,
            BasicFileAttributes.class);
    return fatr.creationTime().toMillis();
}
#end if
