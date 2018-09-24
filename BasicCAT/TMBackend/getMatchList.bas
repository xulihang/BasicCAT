B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim source,path As String
	source=req.GetParameter("source")
	path=req.GetParameter("path")
	resp.ContentType = "text/html"
	Log(path)
	Log(source)
	Dim projectTM As TM
	projectTM.Initialize(path)
    Dim matchList As List
    matchList.Initialize
	matchList.AddAll(projectTM.getList(source))
	Dim json As JSONGenerator
	json.Initialize2(matchList)
	resp.Write(json.ToString)
End Sub