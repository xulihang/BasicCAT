B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private menus As Map
End Sub

Sub escapeSQL(text As String) As String
	For Each str As String In Array As String("'",$"""$,":",";","(",")","[","]","|","\","@")
		text=text.Replace(str,"'"&str)
	Next
End Sub

Sub removeDuplicated(source As List)
	Dim newList As List
	newList.Initialize
	For Each item As Object In source
		If newList.IndexOf(item)=-1 Then
			newList.Add(item)
		End If
	Next
	source.Clear
	source.AddAll(newList)
End Sub

Sub splitByStrs(strs() As String,text As String) As List
	For Each str As String In strs
		Dim matcher As Matcher
		matcher=Regex.Matcher(str.ToLowerCase,text.ToLowerCase)
		Dim offset As Int=0
		Do While matcher.Find
			Dim startIndex,endIndex As Int
			startIndex=matcher.GetStart(0)+offset
			endIndex=matcher.GetEnd(0)+offset
			text=text.SubString2(0,endIndex)&"<--->"&text.SubString2(endIndex,text.Length)
			text=text.SubString2(0,startIndex)&"<--->"&text.SubString2(startIndex,text.Length)
			offset=offset+"<--->".Length*2
		Loop
	Next
	Dim result As List
	result.Initialize
	For Each str As String In Regex.Split("<--->",text)
		result.Add(str)
	Next
	Return result
End Sub

'find is the text within a whole text
Sub splitByFind(text As String,find As String,textSegments As List)
	Dim textLeft As String
	textLeft=text
	Dim currentSegment As String
	Dim length As Int
	length=text.Length-find.Length
	For i=0 To length
		Log(i)
		Dim endIndex As Int
		endIndex=i+find.Length
		currentSegment=text.SubString2(i,endIndex)
		Log(currentSegment)
		If currentSegment=find Then
			Log(True)
			Dim textBefore As String
			Log(textLeft)
			textBefore=textLeft.SubString2(0,textLeft.IndexOf(find))
			If textBefore<>"" Then
				textSegments.Add(textBefore)
			End If
			textSegments.Add(find)
			textLeft=textLeft.SubString2(textLeft.IndexOf(find)+find.Length,textLeft.Length)
		End If
	Next
	textSegments.Add(textLeft)
End Sub

Sub LanguageHasSpace(lang As String) As Boolean
	Dim languagesWithoutSpaceList As List
	languagesWithoutSpaceList=File.ReadList(File.DirAssets,"languagesWithoutSpace.txt")
	For Each code As String In languagesWithoutSpaceList
		If lang.ToLowerCase.StartsWith(code) Then
			Return False
		End If
	Next
	Return True
End Sub

Sub readLanguageCode(codesfilePath As String) As Map
	Dim linesList As List
	linesList=File.ReadList(File.DirAssets,"langcodes.txt")
	If codesfilePath<>"" Then
		If File.Exists(codesfilePath,"") Then
			linesList=File.ReadList(codesfilePath,"")
		End If
	End If
	
	Dim headsList As List
	headsList.Initialize
	headsList.AddAll(Regex.Split("	",linesList.Get(0)))
	'Log(headsList)
	
	Dim langcodes As Map
	langcodes.Initialize
	Dim lineNum As Int=1
	For Each line As String In linesList
		If lineNum=1 Then
			lineNum=lineNum+1
			Continue
		End If
		Dim colIndex As Int=0
		Dim code As String=Regex.Split("	",line)(0)
		Dim codesMap As Map
		codesMap.Initialize
		For Each value As String In Regex.Split("	",line)
			If colIndex=0 Then
				colIndex=colIndex+1
				Continue
			End If
			If value<>"" Then
				codesMap.Put(headsList.Get(colIndex),value)
			End If
			colIndex=colIndex+1
		Next
		langcodes.Put(code,codesMap)
	Next
	Return langcodes
End Sub

Sub conflictsUnSolvedFilename(dirPath As String,filename As String) As String
	If File.Exists(dirPath,filename) Then
		Dim content As String
		content=File.ReadString(dirPath,filename)
		If content.Contains("<<<<<<<") And content.Contains("=======") And content.Contains(">>>>>>>") Then
			Return filename
		End If
	End If
	Return "conflictsSolved"
End Sub

Sub replaceOnce(text As String,match As String,replacement As String) As String
	Try
		text=text.SubString2(0,text.IndexOf(match))&replacement&text.SubString2(text.IndexOf(match)+match.Length,text.Length)
	Catch
		Log(LastException)
	End Try
	Return text
End Sub

Sub replaceOnceFromTheEnd(text As String,match As String,replacement As String) As String
	Try
		text=text.SubString2(0,text.LastIndexOf(match))&replacement&text.SubString2(text.LastIndexOf(match)+match.Length,text.Length)
	Catch
		Log(LastException)
	End Try
	Return text
End Sub

Sub getPureTextWithoutTrim(fullsource As String) As String
	Return Regex.Replace("<.*?>",fullsource,"")
End Sub


Sub shouldAddSpace(sourceLang As String,targetLang As String,index As Int,segmentsList As List) As Boolean
	Dim bitext As List=segmentsList.Get(index)
	Dim fullsource As String=bitext.Get(2)

	If LanguageHasSpace(sourceLang)=False And LanguageHasSpace(targetLang)=True Then
		If index+1<=segmentsList.Size-1 Then
			Dim nextBitext As List
			nextBitext=segmentsList.Get(index+1)
			Dim nextfullsource As String=nextBitext.Get(2)
			If fullsource.EndsWith(CRLF)=False And nextfullsource.StartsWith(CRLF)=False Then
				Try
					If Regex.IsMatch("\s",nextfullsource.CharAt(0))=False And Regex.IsMatch("\s",fullsource.CharAt(fullsource.Length-1))=False Then
						Return True
					End If
				Catch
					Log(LastException)
				End Try
			End If
		End If
	End If
	Return False
End Sub

Sub exportToMarkdownWithNotes(segments As List,path As String,filename As String,sourceLang As String,targetLang As String,settings As Map,projectPath As String)
	Dim text As StringBuilder
	text.Initialize
	Dim noteIndex As Int=0
	Dim noteText As StringBuilder
	noteText.Initialize
	noteText.Append(CRLF).Append(CRLF)
	Dim previousID As String="-1"
	Dim previousInnerFilename As String=""
	Dim index As Int=-1
	For Each segment As List In segments
		index=index+1
		Dim source,target,fullsource As String
		Dim translation As String
		Dim innerFilename As String
		source=segment.Get(0)
		target=segment.Get(1)
		innerFilename=segment.Get(3)
		If target="" Then
			target=source
		Else
			If shouldAddSpace(sourceLang,targetLang,index,segments) Then
				target=target&" "
			End If
		End If
		fullsource=segment.Get(2)
		Dim extra As Map
		extra=segment.Get(4)
        If extra.ContainsKey("note") Then
			Dim note As String
			note=extra.Get("note")
			Dim noteID As String
			noteID="[^note"&noteIndex&"]"
			target=target&noteID
			noteText.Append(noteID).Append(": ").Append(note).Append(CRLF)
        End If
		If extra.ContainsKey("id") Then
			Dim id As String
			id=extra.Get("id")
			If previousID<>id Then
				If id<>-1 Then
					fullsource=CRLF&fullsource
				End If
				previousID=id
			End If
		End If
		If innerFilename<>previousInnerFilename Then
			If previousInnerFilename<>"" Then
				fullsource=CRLF&fullsource
			End If
			previousInnerFilename=innerFilename
		End If
		source=Regex.Replace2("<.*?>",32,source,"")
		target=Regex.Replace2("<.*?>",32,target,"")
		fullsource=Regex.Replace2("<.*?>",32,fullsource,"")
		translation=fullsource.Replace(source,target)
		If LanguageHasSpace(targetLang)=False Then
			If source<>target Then
				translation=segmentation.removeSpacesAtBothSides(projectPath,targetLang,translation,settings.GetDefault("remove_space",True))
			End If
		End If
		text.Append(translation)
	Next
    Dim result As String
	result=text.ToString.Replace(CRLF,CRLF&CRLF)
	result=result&noteText.ToString
	File.WriteString(path,"",result)
End Sub

Sub exportToBiParagraph(segments As List,path As String,filename As String,sourceLang As String,targetLang As String,settings As Map,projectPath As String)
	Dim text As StringBuilder
	text.Initialize
	Dim sourceText As StringBuilder
	sourceText.Initialize
	Dim targetText As StringBuilder
	targetText.Initialize
	Dim previousID As String="-1"
	Dim previousInnerFilename As String=""
	Dim index As Int=-1
	For Each segment As List In segments
		index=index+1
		Dim source,target,fullsource As String
		Dim translation As String
		Dim innerFilename As String
		source=segment.Get(0)
		target=segment.Get(1)
		innerFilename=segment.Get(3)
		If shouldAddSpace(sourceLang,targetLang,index,segments) Then
			target=target&" "
		End If
		fullsource=segment.Get(2)
		Dim extra As Map
		extra=segment.Get(4)
		If extra.ContainsKey("id") Then
			Dim id As String
			id=extra.Get("id")
			If previousID<>id Then
				If previousID<>-1 Then
					fullsource=CRLF&fullsource
				End If
				previousID=id
			End If
		End If
		If innerFilename<>previousInnerFilename Then
			If previousInnerFilename<>"" Then
				fullsource=CRLF&fullsource
			End If
			previousInnerFilename=innerFilename
		End If
		source=Regex.Replace2("<.*?>",32,source,"")
		target=Regex.Replace2("<.*?>",32,target,"")
		fullsource=Regex.Replace2("<.*?>",32,fullsource,"")
		translation=fullsource.Replace(source,target)
		If LanguageHasSpace(targetLang)=False Then
			If source<>target Then
				translation=segmentation.removeSpacesAtBothSides(projectPath,targetLang,translation,settings.GetDefault("remove_space",True))
			End If
		End If
		sourceText.Append(fullsource)
		targetText.Append(translation)
	Next
	Dim sourceList,targetList As List
	sourceList.Initialize
	targetList.Initialize
	sourceList.AddAll(Regex.Split(CRLF,sourceText.ToString))
	targetList.AddAll(Regex.Split(CRLF,targetText.ToString))
	For i=0 To Min(sourceList.Size,targetList.Size)-1
		text.Append(sourceList.Get(i)).Append(CRLF)
		text.Append(targetList.Get(i)).Append(CRLF).Append(CRLF)
	Next
    File.WriteString(path,"",text.ToString)
End Sub

Sub appendSourceToTarget(segments As List,segEnabled As Boolean,extension As String,targetLang As String)

	Dim previousID As String="-1"
	Dim index As Int=-1
	Dim startIndexofOneTU As Int = 0 'startIndexofOneTransUnit
	Dim transUnitStartIndexes As List
	transUnitStartIndexes.Initialize
	Dim source As String
	Dim fullsource As String
	Dim translation As String
	Dim fullSourceMap As Map
	fullSourceMap.Initialize
	Dim translationMap As Map
	translationMap.Initialize
	Dim sourceMap As Map
	sourceMap.Initialize
	For Each segment As List In segments
		index=index+1
		Dim sourceForOne As String=segment.Get(0)
		Dim targetForOne As String=segment.Get(1)
		Dim fullSourceForOne As String=segment.Get(2)
		Dim extra As Map
		extra=segment.Get(4)
		If extra.ContainsKey("id") Then
			Dim id As String
			id=extra.Get("id")
			If previousID<>id Then 'new trans-unit
				If previousID<>-1 Then
					transUnitStartIndexes.Add(startIndexofOneTU)
					fullSourceMap.Put(startIndexofOneTU,fullsource)
					sourceMap.put(startIndexofOneTU,source)
					translationMap.put(startIndexofOneTU,translation)
					startIndexofOneTU=index
					fullsource=""
					translation=""
					source=""
				End If
				previousID=id
			End If
		End If
		source=source&sourceForOne
		translation=translation&fullSourceForOne.Replace(sourceForOne,targetForOne)
		fullsource=fullsource&segment.Get(2)
	Next
	sourceMap.Put(startIndexofOneTU,source)
	fullSourceMap.Put(startIndexofOneTU,fullsource)
	translationMap.put(startIndexofOneTU,translation)
	Log(fullSourceMap)
	Log(translationMap)
	If segEnabled Then
		For Each index As Int In fullSourceMap.Keys
			Dim segment As List=segments.Get(index)
			Dim source As String=segment.Get(0)
			Dim target As String=segment.Get(1)
			Dim fullsource As String=segment.Get(2)
			Dim fullsourceInTU As String=fullSourceMap.Get(index)
			Dim translation As String
			translation=fullsource.Replace(source,target)
			translation=fullsourceInTU&"---seperator between source and target---"&translation
			segment.Set(0,fullsource)
			segment.Set(1,translation)
		Next
	Else
		mergeTransUnits(segments,transUnitStartIndexes,extension,targetLang)
		appendSource(segments)
	End If

End Sub

Sub mergeTransUnits(segments As List,transUnitStartIndexes As List,extension As String,targetLang As String)
	transUnitStartIndexes.Sort(False) ' eg. 15,13,12
	Dim index As Int=transUnitStartIndexes.Size-1
	Dim isFirst As Boolean=True
	For Each startIndex As Int In transUnitStartIndexes
		Dim size As Int=segments.Size
		Dim endIndex As Int
		If isFirst Then
			Log("first")
			endIndex=size-1
		Else
			endIndex=transUnitStartIndexes.Get(index-1)
		End If
		Log("start:"&startIndex)
		Log("end:"&endIndex)
		For i=startIndex To endIndex
			filterGenericUtils.mergeInternalSegment(segments,startIndex,targetLang,extension)
		Next
		index=index-1
	Next
End Sub

Sub appendSource(segments As List)
	For Each segment As List In segments
		Dim source As String=segment.Get(0)
		Dim target As String=segment.Get(1)
		segment.Set(1,source&"---seperator between source and target---"&target)
	Next
End Sub


Sub disableTextArea(p As Pane)
	Dim sourceTa As RichTextArea=p.GetNode(0).Tag
	Dim targetTa As RichTextArea=p.GetNode(1).Tag
	sourceTa.Enabled=False
	targetTa.Enabled=False
End Sub

Sub getList(index As Int,parentlist As List) As List
	Return parentlist.Get(index)
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub get_isEnabled(key As String,parentmap As Map) As Boolean
	If parentmap.ContainsKey(key) = False Then
		Return False
	Else
		Return parentmap.Get(key)
	End If
End Sub

Sub getTextFromPane(index As Int,p As Pane) As String
	Dim ta As RichTextArea
	ta=p.GetNode(index).Tag
	Return ta.Text 
End Sub

Sub enableMenuItems(mb As MenuBar,menuText As List)
	If menus.IsInitialized=False Then
		menus.Initialize
		CollectMenuItems(mb.Menus)
	End If
	For Each text As String In menuText
		Dim mi As MenuItem = menus.Get(text)
		mi.Enabled = True
	Next
End Sub

Sub disableMenuItems(mb As MenuBar,menuText As List)
	If menus.IsInitialized=False Then
		menus.Initialize
		CollectMenuItems(mb.Menus)
	End If
	For Each text As String In menuText
		If menus.ContainsKey(text) Then
			Dim mi As MenuItem = menus.Get(text)
			mi.Enabled = False
		End If
	Next
End Sub

Sub CollectMenuItems(Items As List)
	For Each mi As MenuItem In Items
		If mi.Text <> Null And mi.Text <> "" Then menus.Put(mi.Text, mi)
		If mi Is Menu Then
			Dim mn As Menu = mi
			CollectMenuItems(mn.MenuItems)
		End If
	Next
End Sub

Sub GetScreenPosition(n As Node) As Map
	Dim m As Map = CreateMap("x": 0, "y": 0)
	Dim x = 0, y = 0 As Double
	Dim joNode = n, joScene, joStage As JavaObject
  
	'Get the scene position:
	joScene = joNode.RunMethod("getScene",Null)
	If joScene.IsInitialized = False Then Return m
	x = x + joScene.RunMethod("getX", Null)
	y = y + joScene.RunMethod("getY", Null)

	'Get the stage position:
	joStage = joScene.RunMethod("getWindow", Null)
	If joStage.IsInitialized = False Then Return m
	x = x + joStage.RunMethod("getX", Null)
	y = y + joStage.RunMethod("getY", Null)
  
	'Get the node position in the scene:
	Do While True
		y = y + joNode.RunMethod("getLayoutY", Null)
		x = x + joNode.RunMethod("getLayoutX", Null)
		joNode = joNode.RunMethod("getParent", Null)
		If joNode.IsInitialized = False Then Exit
	Loop

	m.Put("x", x)
	m.Put("y", y)
	Return m
End Sub

Sub buildHtmlString(raw As String) As String
	Dim result As String
	Dim htmlhead As String
	htmlhead="<!DOCTYPE HTML><html><head><meta charset="&Chr(34)&"utf-8"&Chr(34)&" /><style type="&Chr(34)&"text/css"&Chr(34)&">p {font-size: 18px}</style></head><body>"
	Dim htmlend As String
	htmlend="</body></html>"
	result=result&"<p>"&raw&"</p>"
	result=htmlhead&result&htmlend
	Return result
End Sub

Sub CopyFolder(Source As String, targetFolder As String)
	If File.Exists(targetFolder, "") = False Then File.MakeDir(targetFolder, "")
	For Each f As String In File.ListFiles(Source)
		Log(targetFolder)
		Log("f"&f)
		If File.IsDirectory(Source, f) Then
			CopyFolder(File.Combine(Source, f), File.Combine(targetFolder, f))
			Continue
		End If
		File.Copy(Source, f, targetFolder, f)
	Next
End Sub

Sub CopyFolderAsync(Source As String, targetFolder As String) As ResumableSub
	If File.Exists(targetFolder, "") = False Then File.MakeDir(targetFolder, "")
	For Each f As String In File.ListFiles(Source)
		Log(targetFolder)
		Log("f"&f)
		If File.IsDirectory(Source, f) Then
			wait for (CopyFolderAsync(File.Combine(Source, f), File.Combine(targetFolder, f))) Complete (result As Object)
			Continue
		End If
		File.CopyAsync(Source, f, targetFolder, f)
	Next
	Return True
End Sub

Sub CopyWorkFolderAsync(Source As String, targetFolder As String) As ResumableSub
	If File.Exists(targetFolder, "") = False Then File.MakeDir(targetFolder, "")
	For Each f As String In File.ListFiles(Source)
		Log(targetFolder)
		Log("f"&f)
		If File.IsDirectory(Source, f) Then
			wait for (CopyFolderAsync(File.Combine(Source, f), File.Combine(targetFolder, f))) Complete (result As Object)
			Continue
		End If
		If f.EndsWith(".json")=False Then
			Continue
		End If
		File.CopyAsync(Source, f, targetFolder, f)
	Next
	Return True
End Sub

Sub leftTrim(text As String) As String
	Dim new As String
	new=text
	For i=0 To text.Length-1
		Dim character As String
		character=text.CharAt(i)
		If Regex.IsMatch("\s",character) Then
			new=new.SubString(1)
		Else
			Return new
		End If
	Next
	Return new
End Sub

Sub rightTrim(text As String) As String
	Dim new As String
	new=text
	For i=text.Length-1 To 0 Step -1
		Dim character As String
		character=text.CharAt(i)
		If Regex.IsMatch("\s",character) Then
			new=new.SubString2(0,i)
		Else
			Return new
		End If
	Next
	Return new
End Sub

Sub richTextCSS As String
	Dim tags As String=$".bracket{
-fx-fill: darkgray;
}"$
	Dim spaces As String=$".space{
-fx-underline:true;
-fx-fill: darkgray;
}"$
	Dim text As String=$".styled-text-area .text {
	 -fx-fill: white;
	 }
    .styled-text-area .caret {
        -fx-stroke: white;
    }
	"$
    Dim sb As StringBuilder
	sb.Initialize
	sb.Append(tags)
	If Main.preferencesMap.GetDefault("underline_spaces",False) Then
		sb.Append(CRLF).Append(spaces)
	End If
	If Main.preferencesMap.GetDefault("darktheme",False) Then
		sb.Append(CRLF).Append(text)
	End If
    Return sb.ToString
End Sub

Sub darkenTextArea(ta As RichTextArea)
	CSSUtils.SetBackgroundColor(ta.GetObject,fx.Colors.Black)
End Sub

Sub MeasureMultilineTextHeight (Font As Font, Width As Double, Text As String) As Double
	Dim jo As JavaObject = Me
	Return jo.RunMethod("MeasureMultilineTextHeight", Array(Font, Text, Width))
End Sub

Sub isList(o As Object) As Boolean
	If GetType(o)="java.util.ArrayList" Then
		Return True
	Else
		Return False
	End If
End Sub

Sub isChinese(text As String) As Boolean
	Dim jo As JavaObject
	jo=Me
	Return jo.RunMethod("isChinese",Array As String(text))
End Sub

#If JAVA
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import javafx.scene.text.Font;
import javafx.scene.text.TextBoundsType;

public static double MeasureMultilineTextHeight(Font f, String text, double width) throws Exception {
  Method m = Class.forName("com.sun.javafx.scene.control.skin.Utils").getDeclaredMethod("computeTextHeight",
  Font.class, String.class, double.class, TextBoundsType.class);
  m.setAccessible(true);
  return (Double)m.invoke(null, f, text, width, TextBoundsType.LOGICAL);
  }

private static boolean isChinese(char c) {

    Character.UnicodeBlock ub = Character.UnicodeBlock.of(c);

    if (ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS || ub == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS

            || ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A || ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B

            || ub == Character.UnicodeBlock.CJK_SYMBOLS_AND_PUNCTUATION || ub == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS

            || ub == Character.UnicodeBlock.GENERAL_PUNCTUATION) {

        return true;

    }

    return false;

}



// 完整的判断中文汉字和符号

public static boolean isChinese(String strName) {

    char[] ch = strName.toCharArray();

    for (int i = 0; i < ch.length; i++) {

        char c = ch[i];

        if (isChinese(c)) {

            return true;

        }

    }

    return false;

}
#End If