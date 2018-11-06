B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=3.71
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private fx As JFX
	Private texts As List
	Private lastItem As JavaObject
	Private allText As String
End Sub

Public Sub Initialize
	texts.Initialize
End Sub

Public Sub AddText(text As String) As TextFlow
	Dim lastItem As JavaObject
	lastItem.InitializeNewInstance("javafx.scene.text.Text", Array(text))
	texts.Add(lastItem)
	allText=allText&text
	Return Me
End Sub

Public Sub AddTextWithStrikethrough(text As String,realText As String) As TextFlow
	Dim lastItem As JavaObject
	lastItem.InitializeNewInstance("javafx.scene.text.Text", Array(text))
	texts.Add(lastItem)
	allText=allText&realText
	lastItem.RunMethod("setStrikethrough", Array(True))
	Return Me
End Sub

Public Sub getText As String
	Return allText
End Sub

Public Sub SetFont(Font As Font) As TextFlow
	lastItem.RunMethod("setFont", Array(Font))
	Return Me
End Sub

Public Sub SetColor(Color As Paint) As TextFlow
	lastItem.RunMethod("setFill", Array(Color))
	Return Me	
End Sub

Public Sub SetUnderline(Underline As Boolean) As TextFlow
	lastItem.RunMethod("setUnderline", Array(Underline))
	Return Me
End Sub

Public Sub SetStrikethrough(Strikethrough As Boolean) As TextFlow
	lastItem.RunMethod("setStrikethrough", Array(Strikethrough))
	Return Me
End Sub

Public Sub AddMonoText(text As String) As TextFlow
	allText=allText&text
	Dim lastItem As JavaObject
	lastItem.InitializeNewInstance("javafx.scene.text.Text", Array(text))
	CSSUtils.SetStyleProperty(lastItem," -fx-font-family","monospace")
	texts.Add(lastItem)
	Return Me
End Sub

Public Sub Reset As TextFlow
	texts.Initialize
	Return Me
End Sub


Public Sub CreateTextFlowWithWidth(width As Double) As Pane
	Dim tf As JavaObject
	tf.InitializeNewInstance("javafx.scene.text.TextFlow", Null)
	tf.RunMethodJO("getChildren", Null).RunMethod("addAll", Array(texts))
	tf.RunMethod("setMaxWidth",Array(width))
	Return tf
End Sub

Public Sub CreateTextFlow As Pane
	Dim tf As JavaObject
	tf.InitializeNewInstance("javafx.scene.text.TextFlow", Null)
	tf.RunMethodJO("getChildren", Null).RunMethod("addAll", Array(texts))
	Return tf
End Sub