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
	Select req.GetParameter("type")
		Case "size"
			If req.GetParameter("user")<>"" Then
				resp.Write(DB.GetUserItemsSize(req.GetParameter("user")))
				Return
			End If
	End Select
	resp.SendError(500,"lack parameters")
End Sub