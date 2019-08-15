B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private iv As ImageView
	Private PercentageComboBox As ComboBox
	Private ImageScrollPane As ScrollPane
	Private pane As AnchorPane
	Private boxes As List
	Private isFrmInitialized As Boolean=False
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	'frm.Initialize("frm",500,200)
	'frm.RootPane.LoadLayout("itpPreview")
	boxes.Initialize
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "itpFilter"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Tag)
	Select Tag
		Case "createWorkFile"
			wait for (createWorkFile(Params.Get("filename"),Params.Get("path"),Params.Get("sourceLang"),Params.Get("sentenceLevel"))) Complete (result As Boolean)
			Return result
		Case "generateFile"
			generateFile(Params.Get("filename"),Params.Get("path"),Params.Get("projectFile"),Params.Get("main"))
		Case "mergeSegment"
			mergeSegment(Params.Get("MainForm"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "splitSegment"
			splitSegment(Params.Get("main"),Params.Get("sourceTextArea"),Params.Get("editorLV"),Params.Get("segments"),Params.Get("projectFile"))
		Case "previewText"
			Return previewText(Params.Get("editorLV"),Params.Get("segments"),Params.Get("lastEntry"),Params.Get("projectFile"),Params.Get("path"),Params.Get("filename"))
		Case "show"
			initPreviewWindow
		Case "loadImage"
			Dim path As String=Params.Get("path")
			loadImg(path)
		Case "addBoxes"
			removeBoxes
			Dim boxesList As List = Params.Get("boxes")
			For Each boxGeometry As Map In boxesList
				addBox(boxGeometry)
			Next
		Case "addBox"
			Dim boxGeometry As Map=Params.Get("boxGeometry")
			addBox(boxGeometry)
	End Select
	Return ""
End Sub

Sub initPreviewWindow
	'frm=Params.Get("frm")
	Log("initing...")
	isFrmInitialized=True
	frm.Initialize("frm",500,200)
	frm.Title="ImagePreview"

	ImageScrollPane.Initialize("ImageScrollPane")
	frm.RootPane.AddNode(ImageScrollPane,0,0,500,200)
	frm.RootPane.SetAnchors(ImageScrollPane,0,0,0,0)
	iv.Initialize("iv")
			
	pane.Initialize("pane")
	pane.AddNode(iv,0,0,500,200)
	pane.SetAnchors(iv,0,30,0,0)

	PercentageComboBox.Initialize("PercentageComboBox")
	PercentageComboBox.Items.AddAll(Array As String("10%","25%","50%","75%","100%"))
	PercentageComboBox.SelectedIndex=2
	ImageScrollPane.InnerNode=pane
	pane.AddNode(PercentageComboBox,0,0,100,30)
	frm.Show
End Sub

Sub loadImg(path As String)
	Dim percent As Double=getPercent
	Dim img As Image=fx.LoadImage(path,"")
	iv.SetImage(img)
	iv.SetSize(img.Width*percent,img.Height*percent)
	'frm.WindowWidth=img.Width*percent
	'frm.WindowHeight=img.Height*percent+30
End Sub

Public Sub createWorkFile(filename As String,path As String,sourceLang As String,sentenceLevel As Boolean) As ResumableSub
	Dim workfile As Map
	workfile.Initialize
	workfile.Put("filename",filename)
	
	Dim sourceFiles As List
	sourceFiles.Initialize
	

	Dim projectFile As Map=readProjectFile(File.Combine(File.Combine(path,"source"),filename))
	Dim imgMap As Map
	imgMap=projectFile.Get("images")
	Dim keys As List
	keys.Initialize
	For Each key As String In imgMap.Keys
		keys.Add(key)
	Next
	keys.Sort(True)
	keys=sortedList(keys)
	For Each innerfileName As String In keys
		Log(innerfileName)
		Dim oneImg As Map
		oneImg=imgMap.Get(innerfileName)
		Dim boxesList As List=oneImg.Get("boxes")
		Dim segmentsList As List
		segmentsList.Initialize
		Dim sourceFileMap As Map
		sourceFileMap.Initialize
		For Each box As Map In boxesList
			Dim segment As List
			segment.Initialize
			Dim source As String=box.Get("text")
			Dim target As String=box.GetDefault("target","")
			Dim boxGeometry As Map=box.Get("geometry")
			segment.Add(source)
			segment.Add(target)
			segment.Add(source)
			segment.Add(innerfileName)
			Dim extra As Map 
			extra.Initialize
			extra.Put("geometry",boxGeometry)
			segment.Add(extra)
			segmentsList.Add(segment)
		Next
		If segmentsList.Size<>0 Then
			sourceFileMap.Put(innerfileName,segmentsList)
			sourceFiles.Add(sourceFileMap)
		End If
	Next
	
	Log(sourceFiles)
    workfile.Put("dirPath",projectFile.Get("dirPath"))
	workfile.Put("files",sourceFiles)
	
	Dim json As JSONGenerator
	json.Initialize(workfile)
	File.WriteString(File.Combine(path,"work"),filename&".json",json.ToPrettyString(4))
	Return True
End Sub

Sub readProjectFile(path As String) As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(path,""))
	Dim projectFile As Map
	projectFile=json.NextObject
	Return projectFile
End Sub

Sub generateFile(filename As String,path As String,projectFile As Map,BCATMain As Object)
	Dim workfile As Map
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
	workfile=json.NextObject
	Dim sourceFiles As List
	sourceFiles=workfile.Get("files")
	Dim itpProjectFile As Map
	itpProjectFile=readProjectFile(File.Combine(File.Combine(path,"source"),filename))
	Dim imgMap As Map = itpProjectFile.Get("images")
	
	
	For Each sourceFileMap As Map In sourceFiles
		Dim innerfilename As String
		innerfilename=sourceFileMap.GetKeyAt(0)
		Dim oneMap As Map
		oneMap=imgMap.Get(innerfilename)
		Dim boxesList As List=oneMap.Get("boxes")
		Dim segmentsList As List
		segmentsList=sourceFileMap.Get(innerfilename)
		Dim boxindex As Int =0
		For Each segment As List In segmentsList
			Dim boxMapInProject As Map
			boxMapInProject=boxesList.Get(boxindex)
			boxMapInProject.Put("target",segment.Get(1))
			boxindex=boxindex+1
		Next
	Next
	Dim jsonGenerator As JSONGenerator
	jsonGenerator.Initialize(itpProjectFile)
	File.WriteString(File.Combine(path,"target"),filename,jsonGenerator.ToPrettyString(4))
	CallSub2(BCATMain,"updateOperation",filename&" generated!")
End Sub



Sub PercentageComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	Try
		Dim percent As Double=getPercent
		Dim img As Image=iv.GetImage
		iv.Width=img.Width*percent
		iv.Height=img.Height*percent
		ImageScrollPane.InnerNode.PrefHeight=iv.Height
		ImageScrollPane.InnerNode.PrefWidth=iv.Width
		
		frm.WindowWidth=img.Width*percent
		frm.WindowHeight=img.Height*percent+50
		reloadBoxes
	Catch
		Log(LastException)
	End Try
End Sub

Sub removeBoxes
	For Each boxMap As Map In boxes
		Dim box As ImageView=boxMap.Get("box")
		box.RemoveNodeFromParent
	Next
	boxes.Clear
End Sub

Sub reloadBoxes
	Dim boxesTmp As List
	boxesTmp.Initialize
	boxesTmp.AddAll(boxes)
	boxes.Clear
	For Each boxMap As Map In boxesTmp
		Dim box As ImageView=boxMap.Get("box")
		box.RemoveNodeFromParent
		Dim boxGeometry As Map
		boxGeometry=boxMap.Get("boxGeometry")
		addBox(boxGeometry)
	Next
End Sub

Sub getPercent As Double
	Dim percentageString As String=PercentageComboBox.Value
	percentageString=percentageString.Replace("%","")
	Dim percentage As Double
	percentage=percentageString/100
	Return percentage
End Sub

Sub lv_MouseClicked (EventData As MouseEvent)
	Log("clicked")
End Sub

Sub iv_MousePressed (EventData As MouseEvent)
	Log("image clicked")
End Sub

Sub box_MousePressed (EventData As MouseEvent)
	Log("image clicked")
	changeBoxColor(Sender,"green")
End Sub

Sub addBox(boxGeometry As Map)
	Dim percent As Double=getPercent
	Log(percent)
	Dim Box As ImageView
	Box=SelectionBox
	pane.AddNode(Box,boxGeometry.Get("X")*percent,30+boxGeometry.Get("Y")*percent,boxGeometry.Get("width")*percent,boxGeometry.Get("height")*percent)
	Dim boxMap As Map
	boxMap.Initialize
	boxMap.Put("box",Box)
	boxMap.Put("boxGeometry",boxGeometry)
	boxes.Add(boxMap)
End Sub

Sub changeBoxColor(Box As ImageView,color As String)
	Dim xui As XUI
	Dim colorInt As Int=xui.Color_Black
	Select color
		Case "red"
			colorInt=xui.Color_Red
		Case "green"
			colorInt=xui.Color_Green
	End Select
	iv.SetImage(drawBoxBC(Box.Width,Box.Height,colorInt,2))
End Sub

Sub SelectionBox As ImageView
	Dim Box As ImageView
	Box.Initialize("box")
	Box.PickOnBounds=True
	Dim xui As XUI
	Box.SetImage(drawBoxBC(100,100,xui.Color_Red,2))
	Return Box
End Sub

Sub drawBoxBC(width As Int,height As Int,color As Int,stroke As Int) As B4XBitmap
	Dim bc As BitmapCreator
	bc.Initialize(width,height)
	Dim r As B4XRect
	r.Initialize(0, 0, width, height)
	bc.DrawRect( r, color ,False,stroke)
	Return bc.Bitmap
End Sub

Sub sortedList(imageNames As List) As List
	Dim newList As List
	newList.Initialize
	Dim parents As Map
	parents.Initialize

	For Each name As String In imageNames
		Dim parent As String=GetParent(name)
		If parent="" Then
			parent="root"
		End If
		Dim files As List
		files.Initialize
		If parents.ContainsKey(parent) Then
			files=parents.Get(parent)
		End If
		files.Add(name)
		parents.Put(parent,files)

	Next
	For Each parent As String In parents.Keys
		Dim files As List
		files=parents.Get(parent)
		Dim nameMap As Map
		nameMap.Initialize
		Dim names As List
		names.Initialize
		Dim SortAsNumber As Boolean
		SortAsNumber=CanBeSortedAsNumber(files)
		For Each filename As String In files
			Dim pureFilename As String=GetFilenameWithoutExtensionAndParent(filename)
			nameMap.Put(pureFilename,filename)
			If SortAsNumber Then
				Dim nameAsInt As Int
				Try
					nameAsInt=pureFilename
					names.Add(nameAsInt)
				Catch
					Log(LastException)
				End Try
			Else
				names.Add(pureFilename)
			End If
		Next
		Log(names)
		names.Sort(True)
		Log(names)
		For Each name As String In names

			newList.Add(nameMap.Get(name))
		Next
	Next
	Log(newList)
	Return newList
End Sub

Sub GetParent(filename As String) As String
	Dim parent As String
	If filename.Contains("/") Then
		parent=filename.SubString2(0,filename.LastIndexOf("/"))
	End If
	If filename.Contains("\") Then
		parent=filename.SubString2(0,filename.LastIndexOf("\"))
	End If
	Return parent
End Sub

Sub CanBeSortedAsNumber(files As List) As Boolean
	For Each filename As String In files
		Dim pureFilename As String=GetFilenameWithoutExtensionAndParent(filename)
		If pureFilename.StartsWith("0") Then
			Return False
		End If
		Dim nameAsInt As Int
		Log(filename)
		Log(pureFilename)
		Try
			nameAsInt=pureFilename
		Catch
			Log(LastException)
			Return False
		End Try
	Next
	Return True
End Sub

Sub GetFilenameWithoutExtensionAndParent(filename As String) As String
	Try
		If filename.Contains(".") Then
			filename=filename.SubString2(0,filename.LastIndexOf("."))
		End If
		If filename.Contains("/") Then
			filename=filename.SubString2(filename.LastIndexOf("/")+1,filename.Length)
		End If
		If filename.Contains("\") Then
			filename=filename.SubString2(filename.LastIndexOf("\")+1,filename.Length)
		End If
	Catch
		Log(LastException)
	End Try
	Return filename
End Sub


Sub previewText(editorLV As ListView,segments As List,lastEntry As Int,projectFile As Map,path As String,filename As String) As String
	Log("itp preview")
	Dim text As StringBuilder
	text.Initialize
	If editorLV.Items.Size<>segments.Size Then
		Return ""
	End If
	For i=Max(0,lastEntry-3) To Min(lastEntry+7,segments.Size-1)
		Try
			Dim p As Pane
			p=editorLV.Items.Get(i)
		Catch
			Log(LastException)
			Continue
		End Try
		Dim sourceTextArea As TextArea
		Dim targetTextArea As TextArea
		sourceTextArea=p.GetNode(0)
		targetTextArea=p.GetNode(1)
		Dim bitext As List
		bitext=segments.Get(i)
		Dim source,target,fullsource,translation As String
		source=sourceTextArea.Text
		target=targetTextArea.Text
		fullsource=bitext.Get(2)
		Dim extra As Map
		extra=bitext.Get(4)
		Dim boxGeometry As Map = extra.Get("geometry")
		If target="" Then
			translation=fullsource
		Else
			translation=target
		End If
		If i=lastEntry Then
			translation=$"<span id="current" name="current" >${translation}</span>"$
			Log("frm is initialized:" & isFrmInitialized)
			Try
				frm.Show
			Catch
				Log(LastException)
				initPreviewWindow
			End Try
			frm.AlwaysOnTop=True
			Dim json As JSONParser
			json.Initialize(File.ReadString(File.Combine(path,"work"),filename&".json"))
			Dim workfile As Map
			workfile=json.NextObject
			loadImg(File.Combine(workfile.Get("dirPath"),bitext.Get(3)))
			removeBoxes
			addBox(boxGeometry)
			Log(boxGeometry.Get("Y"))
			Log(iv.GetImage.Height)
			ImageScrollPane.VPosition=boxGeometry.Get("Y")/iv.GetImage.Height
		End If
		text.Append(translation).Append(CRLF)
	Next
	Return text.ToString
End Sub

Sub mergeSegment(MainForm As Form,sourceTextArea As TextArea,editorLV As ListView,segments As List,projectFile As Map)
	Return
End Sub

Sub splitSegment(BCATMain As Object,sourceTextArea As TextArea,editorLV As ListView,segments As List,projectFile As Map)
	Return
End Sub