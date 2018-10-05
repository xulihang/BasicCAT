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
		If File.IsDirectory(Source, f) Then
			CopyFolder(File.Combine(Source, f), File.Combine(targetFolder, f))
			Continue
		End If
		wait for (File.CopyAsync(Source, f, targetFolder, f)) Complete (Success As Boolean)
	Next
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