B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private WebView1 As WebView
	Private thisReviews As List
	Private thisSegments As List
	Private index As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(reviews As List,currentSegments As List)
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("confirmReview")
	thisReviews=reviews
	thisSegments=currentSegments
	index=-1
End Sub

Sub loadNextOne
	If index+1>thisReviews.Size-1 Then
		fx.Msgbox(frm,"There is no segments left for confirm.","")
		frm.Close
		Return
	End If
	index=index+1
	Dim onerow() As String
	onerow=thisReviews.Get(index)
	Dim segment As List
	segment=thisSegments.Get(index)
	If onerow(0)=segment.Get(0) Then
		Dim review As String
		review=onerow(1)
		If review.Contains("  --------note: ") Then
			review=review.SubString2(0,review.IndexOf("  --------note: "))
		End If
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append("<p>source:&nbsp;").Append(onerow(0)).Append("</p>")
		sb.Append("<p>target:&nbsp;").Append(segment.Get(1)).Append("</p>")
		sb.Append("<p>review:&nbsp;").Append(review).Append("</p>")
		loadHtml(sb.ToString)
	Else
		loadNextOne
	End If
	
End Sub

Sub loadHtml(text As String)
	text=Regex.Replace("\r",text,"")
	text=Regex.Replace("\n",text,"<br/>")
	Dim htmlhead,htmlend As String
	htmlhead=$"<!DOCTYPE HTML>
	<html>
	<head>
	<meta charset="utf-8"/>
 </head><body>
	"$
	
	htmlend=$"</body>
	</html>"$
	text=htmlhead&text&htmlend
	WebView1.LoadHtml(text)
End Sub

Public Sub ShowAndWait
	loadNextOne
	frm.ShowAndWait
End Sub

Sub skipButton_MouseClicked (EventData As MouseEvent)
	loadNextOne
End Sub

Sub confirmButton_MouseClicked (EventData As MouseEvent)
	Dim onerow() As String
	onerow=thisReviews.Get(index)
	Dim target As String
	target=onerow(1)
	If target.Contains("  --------note: ") Then
		target=target.SubString2(0,target.IndexOf("  --------note: "))
	End If
	Dim segment As List
	segment=thisSegments.Get(index)
	segment.Set(1,target)
	fillOne(target)
	loadNextOne
End Sub

Sub confirmAllButton_MouseClicked (EventData As MouseEvent)
	index=-1
	For Each row() As String In thisReviews
		index=index+1
		Dim segment As List
		segment=thisSegments.Get(index)
		segment.Set(1,row(1))
		fillOne(row(1))
	Next
	fx.Msgbox(frm,"Done","")
	frm.Close
End Sub

Sub fillOne(text As String)
	Dim p As Pane
	p=Main.editorLV.GetPanel(index)
	If p.NumberOfNodes=0 Then
		Return
	End If
	Dim targetTextArea As TextArea
	targetTextArea=p.GetNode(1)
	targetTextArea.Text=text
	Main.currentProject.contentIsChanged
End Sub