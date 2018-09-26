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
	Dim matchrate As Double
	Dim index As Int
	source=req.GetParameter("source")
	path=req.GetParameter("path")
	index=req.GetParameter("index")
	matchrate=req.GetParameter("matchrate")
	resp.ContentType = "text/html"
	Log(path)
	Log(source)
	Dim projectTM As TM
	projectTM.Initialize(path)
	Dim oneList As List
	oneList.Initialize
	oneList.AddAll(projectTM.getOneUseMemory(source,matchrate))
	oneList.Add(index)
	Dim json As JSONGenerator
	json.Initialize2(oneList)
	resp.Write(json.ToString)
End Sub