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

Sub getPureTextWithoutTrim(fullsource As String) As String
	Return Regex.Replace("<.*?>",fullsource,"")
End Sub

Sub exportToBiParagraph(segments As List,path As String,filename As String)
	Dim text As StringBuilder
	text.Initialize
	Dim sourceText As String
	Dim targetText As String
	Dim previousID As String="-1"
	For Each segment As List In segments
		Dim source,target,fullsource As String
		Dim translation As String
		source=segment.Get(0)
		target=segment.Get(1)
		fullsource=segment.Get(2)
		Dim extra As Map
		extra=segment.Get(4)
		If extra.ContainsKey("id") Then
			Dim id As String
			id=extra.Get("id")
			If previousID<>id Then
				fullsource=CRLF&fullsource
				previousID=id
			End If
		End If
		source=Regex.Replace2("<.*?>",32,source,"")
		target=Regex.Replace2("<.*?>",32,target,"")
		fullsource=Regex.Replace2("<.*?>",32,fullsource,"")
		translation=fullsource.Replace(source,target)
		sourceText=sourceText&fullsource
		targetText=targetText&translation
	Next
	Dim sourceList,targetList As List
	sourceList.Initialize
	targetList.Initialize
	sourceList.AddAll(Regex.Split(CRLF,sourceText))
	targetList.AddAll(Regex.Split(CRLF,targetText))
	For i=0 To Min(sourceList.Size,targetList.Size)-1
		text.Append(sourceList.Get(i)).Append(CRLF)
		text.Append(targetList.Get(i)).Append(CRLF).Append(CRLF)
	Next
    File.WriteString(path,"",text.ToString)
End Sub

Sub disableTextArea(p As Pane)
	Dim sourceTa As TextArea=p.GetNode(0)
	Dim targetTa As TextArea=p.GetNode(1)
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
	Dim ta As TextArea
	ta=p.GetNode(index)
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
		Dim mi As MenuItem = menus.Get(text)
		mi.Enabled = False
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

Sub ListViewParent_Resize(clv As CustomListView)
	If clv.Size=0 Then
		Return
	End If
	Dim itemWidth As Double = clv.AsView.Width
	Log(itemWidth)
	For i =  0 To clv.Size-1
		Dim p As Pane
		p=clv.GetPanel(i)
		If p.NumberOfNodes=0 Then
			Continue
		End If
		Dim sourcelbl,targetlbl As Label
		sourcelbl=p.GetNode(0)
		sourcelbl.SetSize(itemWidth/2,10)
		sourcelbl.WrapText=True
		targetlbl=p.GetNode(1)
		targetlbl.SetSize(itemWidth/2,10)
		targetlbl.WrapText=True
		Dim jo As JavaObject = p
		'force the label to refresh its layout.
		jo.RunMethod("applyCss", Null)
		jo.RunMethod("layout", Null)
		Dim h As Int = Max(Max(50, sourcelbl.Height + 20), targetlbl.Height + 20)
		p.SetLayoutAnimated(0, 0, 0, itemWidth, h + 10dip)
		sourcelbl.SetLayoutAnimated(0, 0, 0, itemWidth/2, h+5dip)
		targetlbl.SetLayoutAnimated(0, itemWidth/2, 0, itemWidth/2, h+5dip)
		clv.ResizeItem(i,h+10dip)
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

Sub CopyWorkFolderAsync(Source As String, targetFolder As String)
	Sleep(0)
	If File.Exists(targetFolder, "") = False Then File.MakeDir(targetFolder, "")
	For Each f As String In File.ListFiles(Source)
		Log(targetFolder)
		Log("f"&f)
		If File.IsDirectory(Source, f) Then
			CopyFolder(File.Combine(Source, f), File.Combine(targetFolder, f))
			Continue
		End If
		If f.EndsWith(".json")=False Then
			Continue
		End If
		File.Copy(Source, f, targetFolder, f)
	Next
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