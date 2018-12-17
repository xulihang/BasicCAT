B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private HistoryListView As ListView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",500,300)
	frm.RootPane.LoadLayout("HistoryViewer")
End Sub


Public Sub Show(historyList As List)
	loadHistoryList(historyList)
	frm.Show
End Sub

Sub loadHistoryList(historyList As List)
	For Each item As Map In historyList
		Dim creator As String
		creator=item.Get("creator")
		Dim createdTime As Long
		createdTime=item.Get("createdTime")
		Dim p As Pane
		p.Initialize("")
		p.LoadLayout("HistoryItem")
		Dim ta As TextArea
		ta=p.GetNode(0)

		Dim infoLabel As Label
		infoLabel=p.GetNode(1)
		infoLabel.Text=creator&" "&DateTime.Date(createdTime)&" "&DateTime.Time(createdTime)
		HistoryListView.Items.Add(p)
		p.SetSize(HistoryListView.Width,100dip)
		
		Dim result As StringBuilder
		result.Initialize
		If item.ContainsKey("text") Then 'translation memory
			result.Append("target: ").Append(item.Get("text")).Append(CRLF)
			result.Append("note: ").Append(item.GetDefault("note",""))
		Else if item.ContainsKey("target") Then 'term
			result.Append("target: ").Append(item.Get("target")).Append(CRLF)
			result.Append("tag: ").Append(item.GetDefault("tag","")).Append(CRLF)
			result.Append("note: ").Append(item.GetDefault("note",""))
		End If
		ta.Text=result.ToString
	Next
End Sub