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
	
	Dim str1,str2,target,note As String
	str1=req.GetParameter("str1")
	str2=req.GetParameter("str2")
	target=req.GetParameter("target")
	note=req.GetParameter("note")
	resp.ContentType = "text/html"
	Log(str2)
	Dim result As List
	result.Initialize
	result.Add(TMUtils.getSimilarity(str1,str2))
	result.Add(str2)
	result.Add(target)
	result.Add(note)
	Dim json As JSONGenerator
	json.Initialize2(result)
	resp.Write(json.ToString)
End Sub