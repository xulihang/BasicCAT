B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Sub extract(sl As String,tl As String,filepath As String,outputDir As String, showCodeAttrs As Boolean) As ResumableSub
	Dim sh As Shell
	Dim args As List
	args.Initialize
	Dim extension As String
	Dim filename As String
	Dim dir As String
	filename=File.GetName(filepath)
	dir=File.GetFileParent(filepath)
	extension=getExtension(filename)
	Log("dir"&dir)
	Log("filename"&filename)
	Log("extension"&extension)
	Dim fcConfMap As Map
	fcConfMap=getfcConfMap
	If fcConfMap.ContainsKey(extension) Then
		Dim settings As Map
		settings=fcConfMap.Get(extension)
		Dim configId As String
		configId=settings.Get("configId")
		args.AddAll(Array As String("-cp",Quoted(tikalLibPath),"net.sf.okapi.applications.tikal.Main","-x","-sl",sl,"-tl",tl,Quoted(filepath),"-fc",configId,"-od",Quoted(outputDir)))
	Else
		args.AddAll(Array As String("-cp",Quoted(tikalLibPath),"net.sf.okapi.applications.tikal.Main","-x","-sl",sl,"-tl",tl,Quoted(filepath),"-od",Quoted(outputDir)))
	End If
	
	If showCodeAttrs Then
		args.Add("-codeattrs")
	End If
	
	sh.Initialize("sh","java",args)
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		Log(StdOut)
		File.Copy(filepath,"",outputDir,filename)
		Success=True
	Else
	    Log(StdOut)
		Log("Error: " & StdErr)
		Success=False
	End If
	Return Success
End Sub

Sub merge(filepath As String,sourceDir As String,outputDir As String) As ResumableSub
	Dim sh As Shell
	Dim args As List
	args.Initialize
	Dim extension As String
	Dim filename As String
	filename=File.GetName(filepath)
	Dim originalFilename As String
	originalFilename=filename.SubString2(0,filename.LastIndexOf("."))
	extension=getExtension(originalFilename)
	Dim fcConfMap As Map
	fcConfMap=getfcConfMap
	
	If fcConfMap.ContainsKey(extension) Then
		Dim settings As Map
		settings=fcConfMap.Get(extension)
		Dim configId As String
		configId=settings.Get("configId")
		If settings.ContainsKey("oe") Then
			Dim outPutEncoding As String=settings.Get("oe")
			args.AddAll(Array As String("-cp",tikalLibPath,"net.sf.okapi.applications.tikal.Main","-m",Quoted(filepath),"-fc",configId,"-sd",Quoted(sourceDir),"-od",Quoted(outputDir),"-oe",outPutEncoding))
		Else	
			args.AddAll(Array As String("-cp",tikalLibPath,"net.sf.okapi.applications.tikal.Main","-m",Quoted(filepath),"-fc",configId,"-sd",Quoted(sourceDir),"-od",Quoted(outputDir)))
		End If
		
	Else
		args.AddAll(Array As String("-cp",tikalLibPath,"net.sf.okapi.applications.tikal.Main","-m",Quoted(filepath),"-sd",Quoted(sourceDir),"-od",Quoted(outputDir)))
	End If
	Log(args)
	sh.Initialize("sh","java",args)
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log("Success")
		Log(StdOut)
		Success=True
	Else
		Log("Error: " & StdErr)
		Success=False
	End If
	Return Success
End Sub

Sub Quoted(text As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append($"""$)
	sb.Append(text)
	sb.Append($"""$)
	Return sb.ToString
End Sub

Sub tikalLibPath As String
	Return File.Combine(File.Combine(File.Combine(File.DirApp,"okapi"),"lib"),"*")
End Sub

Sub tikalPath As String 'ignore
	Return File.Combine(File.Combine(File.Combine(File.DirApp,"okapi"),"lib"),"tikal.jar")
End Sub

Sub getExtension(filename As String) As String
	Try
		Return filename.SubString2(filename.LastIndexOf(".")+1,filename.Length)
	Catch
		Log(LastException)
		Return ""
	End Try
End Sub

Sub getfcConfMap As Map
	Dim result As Map
	result.Initialize
	Try
		Dim confPath As String
		If File.Exists(File.Combine(Main.currentProject.path,"config"),"fc.conf") Then
			confPath=File.Combine(File.Combine(Main.currentProject.path,"config"),"fc.conf")
		Else
			confPath=File.Combine(File.Combine(File.DirApp,"okapi"),"fc.conf")
		End If
		Dim conf As List
		conf=File.ReadList(confPath,"")
		For Each line In conf
			Dim settings As Map
			settings.Initialize
			Dim extension,configId As String
			extension=Regex.Split("	",line)(0)
			configId=Regex.Split("	",line)(1)
			If configId.Contains("@") Then 'user specified config
				If File.Exists(configId,"")=False Then
					configId=File.Combine(File.Combine(Main.currentProject.path,"config"),configId)
				End If
			End If
			settings.Put("configId",configId)
            Try
				Dim outputEncoding As String
				outputEncoding=Regex.Split("	",line)(2)
				settings.Put("oe",outputEncoding)
			Catch
				Log(LastException)
			End Try
			result.Put(extension,settings)
		Next
	Catch
		Log(LastException)
	End Try
	Return result
End Sub