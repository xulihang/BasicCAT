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

Sub getXmlMap(xmlstring As String) As Map
	Dim ParsedData As Map
	Dim xm As Xml2Map
	xm.Initialize
	ParsedData = xm.Parse(xmlstring)
	Return ParsedData
End Sub

Sub getXmlFromMap(map1 As Map) As String
	Dim mx As Map2Xml
	mx.Initialize
	Return mx.MapToXml(map1)
End Sub

Sub GetElements (m As Map, key As String) As List
	Dim res As List
	If m.ContainsKey(key) = False Then
		res.Initialize
		Return res
	Else
		Dim value As Object = m.Get(key)
		If value Is List Then Return value
		res.Initialize
		res.Add(value)
		Return res
	End If
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

Sub leftTrim(text As String) As String
	For i=0 To text.Length-1
		Dim character As String
		character=text.CharAt(i)
		If Regex.IsMatch("\s",character) Then
			text=text.SubString(1)
		Else
			Return text
		End If
	Next
	Return text
End Sub

Sub rightTrim(text As String) As String
	For i=text.Length-1 To 0 Step -1
		Dim character As String
		character=text.CharAt(i)
		If Regex.IsMatch("\s",character) Then
			text=text.SubString2(0,i)
		Else
			Return text
		End If
	Next
	Return text
End Sub


Sub isList(o As Object) As Boolean
	If GetType(o)="java.util.ArrayList" Then
		Return True
	Else
		Return False
	End If
End Sub

Sub MeasureMultilineTextHeight (Font As Font, Width As Double, Text As String) As Double
	Dim jo As JavaObject = Me
	Return jo.RunMethod("MeasureMultilineTextHeight", Array(Font, Text, Width))
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
#End if