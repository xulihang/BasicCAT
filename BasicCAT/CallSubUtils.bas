B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private RunDelayed As Map
	Type RunDelayedData (Module As Object, SubName As String, Arg() As Object, Delayed As Boolean)
End Sub

Public Sub Initialize

End Sub

'Similar to CallSubDelayed. This method allows you to set the delay (in milliseconds).
'Note that the sub name must include an underscore if compiled with obfuscation enabled.
Public Sub CallSubDelayedPlus(Module As Object, SubName As String, Delay As Int)
	CallSubDelayedPlus2(Module, SubName, Delay, Null)	
End Sub

'Similar to CallSubDelayed. This method allows you to set the delay (in milliseconds).
'Note that the sub name must include an underscore if compiled with obfuscation enabled.
'The target sub should have one parameter with a type of Object().
Public Sub CallSubDelayedPlus2(Module As Object, SubName As String, Delay As Int, Arg() As Object)
	PlusImpl(Module, SubName, Delay, Arg, True)
End Sub

'Similar to CallSub. This method allows you to set the delay (in milliseconds).
'Note that the sub name must include an underscore if compiled with obfuscation enabled.
Public Sub CallSubPlus(Module As Object, SubName As String, Delay As Int)
	CallSubPlus2(Module, SubName, Delay, Null)	
End Sub

'Similar to CallSub. This method allows you to set the delay (in milliseconds).
'Note that the sub name must include an underscore if compiled with obfuscation enabled.
'The target sub should have one parameter with a type of Object().
Public Sub CallSubPlus2(Module As Object, SubName As String, Delay As Int, Arg() As Object)
	PlusImpl(Module, SubName, Delay, Arg, False)
End Sub

Private Sub PlusImpl(Module As Object, SubName As String, Delay As Int, Arg() As Object, delayed As Boolean)
	If RunDelayed.IsInitialized = False Then RunDelayed.Initialize
	Dim tmr As Timer
	tmr.Initialize("tmr", Delay)
	Dim rdd As RunDelayedData
	rdd.Module = Module
	rdd.SubName = SubName
	rdd.Arg = Arg
	rdd.delayed = delayed
	RunDelayed.Put(tmr, rdd)
	tmr.Enabled = True
End Sub

Private Sub tmr_Tick
	Dim t As Timer = Sender
	t.Enabled = False
	Dim rdd As RunDelayedData = RunDelayed.Get(t)
	RunDelayed.Remove(t)
	If rdd.Delayed Then
		If rdd.Arg = Null Then
			CallSubDelayed(rdd.Module, rdd.SubName)
		Else
			CallSubDelayed2(rdd.Module, rdd.SubName, rdd.Arg)
		End If
	Else
		If rdd.Arg = Null Then
			CallSub(rdd.Module, rdd.SubName)
		Else
			CallSub2(rdd.Module, rdd.SubName, rdd.Arg)
		End If
	End If
End Sub