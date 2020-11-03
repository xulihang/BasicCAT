B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private URLTextField As TextField
	Private ParamsTextArea As TextArea
	Private TemplateTextField As TextField
	Private WebView1 As WebView
	Private Button1 As Button
	Private Button2 As Button
	Private Label1 As Label
	Private Label2 As Label
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "webMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	If frm.IsInitialized=False Then
		init
	End If
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("timeout (seconds)")
			Return paramsList
		Case "translate"
			If frm.Showing=False Then
				frm.Show
			End If
			wait for (translate(Params.Get("source"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("timeout (seconds)":"5")
	End Select
	Return ""
End Sub

Sub init
	frm.Initialize("frm",600,600)
	frm.Title="MT Webview"
	URLTextField.Initialize("")
	URLTextField.PromptText="http://"
	TemplateTextField.Initialize("")
	ParamsTextArea.Initialize("")
	WebView1.Initialize("WebView1")
	Button1.Initialize("Button1")
	Button2.Initialize("Button2")
	frm.RootPane.AddNode(URLTextField,0,0,500,30)
	frm.RootPane.SetRightAnchor(URLTextField,90)
	frm.RootPane.SetLeftAnchor(URLTextField,0)
	frm.RootPane.AddNode(Button1,530,0,40,30)
	frm.RootPane.SetRightAnchor(Button1,50)
	frm.RootPane.AddNode(Button2,530,50,40,30)
	frm.RootPane.SetRightAnchor(Button2,50)
	Label1.Initialize("")
	Label1.Text="URL Template:"
	frm.RootPane.AddNode(Label1,0,30,110,30)
	Label2.Initialize("")
	Label2.Text="Params:"
	frm.RootPane.AddNode(Label2,0,60,110,30)
	frm.RootPane.AddNode(TemplateTextField,110,30,200,30)
	frm.RootPane.SetRightAnchor(TemplateTextField,90)
	frm.RootPane.SetLeftAnchor(TemplateTextField,110)
	frm.RootPane.AddNode(ParamsTextArea,110,60,200,30)
	frm.RootPane.SetRightAnchor(ParamsTextArea,90)
	frm.RootPane.SetLeftAnchor(ParamsTextArea,110)
	frm.RootPane.AddNode(WebView1,0,110,-1,-1)
	frm.RootPane.SetAnchors(WebView1,0,110,0,0)
	Button1.Text="Go"
	Button2.Text="Go"
	TemplateTextField.Text="https://translate.google.cn/#view=home&op=translate&sl={sourceLang}&tl={targetLang}&text={text}"
	ParamsTextArea.Text=$"auto,zh-CN,translation
Hello World!"$
End Sub

Public Sub Show
	frm.Show
End Sub

Public Sub translate(text As String,preferencesMap As Map) As ResumableSub
	Dim sourceLang,targetLang,targetClass As String
	Dim timeout As Int=5000
	Try
		timeout=Max(timeout,getMap("web",getMap("mt",preferencesMap)).GetDefault("timeout (seconds)",5)*1000)
	Catch
		Log(LastException)
	End Try
	Dim params() As String=Regex.Split(",",ParamsTextArea.Text.SubString2(0,ParamsTextArea.Text.IndexOf(CRLF)))
	sourceLang=params(0)
	targetLang=params(1)
	targetClass=params(2)
	WebView1.LoadHtml("Loading...")
	Sleep(100)
	WebView1.LoadUrl(TemplateURLFilled(TemplateTextField.Text,sourceLang,targetLang,text))
	wait for (GetTranslaton(targetClass,timeout)) Complete (translation As String)
	Return translation
End Sub

Sub asJO(o As JavaObject) As JavaObject
	Return o
End Sub

Sub LoadURLBasedOnTemplate(template As String,sourceLang As String,targetLang As String,targetClass As String,text As String)
	WebView1.LoadHtml("Loading...")
	Sleep(100)
	WebView1.LoadUrl(TemplateURLFilled(template,sourceLang,targetLang,text))
	GetTranslaton(targetClass,5000)
End Sub

Sub GetTranslaton(className As String,timeout As Int) As ResumableSub
	Dim we As JavaObject
	we = asJO(WebView1).RunMethod("getEngine",Null)

	Dim getClassJS As String=$"document.getElementsByClassName("${className}")[0]"$
	Log(getClassJS)
	Dim jsobject As JavaObject 'netscape.javascript.JSObject
	jsobject=we.RunMethod("executeScript",Array As String(getClassJS))
	Dim slept As Int
	Do While jsobject="undefined" 'ignore
		Sleep(500)
		slept=slept+500
		If slept>timeout Then
			Return ""
		End If
		Log(jsobject)
		jsobject=we.RunMethod("executeScript",Array As String(getClassJS))
	Loop

	Dim result As String=we.RunMethod("executeScript",Array As String(getClassJS&".innerText"))
	Log("Translation:")
	Log(result)
	Return result
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub TemplateURLFilled(template As String,sourceLang As String,targetLang As String,text As String) As String
	Dim url As String=template
	Dim matcher1 As Matcher
	Dim pattern As String="\{(.*?)\}"
	matcher1=Regex.Matcher(pattern,url)
	Do While matcher1.Find
		Dim replace As String
		If matcher1.Group(1)="sourceLang" Then
			replace=sourceLang
		else if matcher1.Group(1)="targetLang" Then
			replace=targetLang
		else if matcher1.Group(1)="text" Then
			replace=EncodeURL(text)
		End If
		url=url.Replace(matcher1.Match,replace)
		matcher1=Regex.Matcher(pattern,url)
	Loop
	Log(url)
	Return url
End Sub

Sub EncodeURL(text As String) As String
	Dim su As StringUtils
	text=su.EncodeUrl(text,"UTF8")
	'text=text.Replace("+","%20")
	Return text
End Sub

Sub Button1_MouseClicked (EventData As MouseEvent)
	'"https://translate.google.cn/#view=home&op=translate&sl=auto&tl=zh-CN&text=Hello%20world!"
	WebView1.LoadUrl(URLTextField.Text)
End Sub

Sub WebView1_LocationChanged (Location As String)
	URLTextField.Text=Location
End Sub

Sub WebView1_PageFinished (Url As String)
	Log(Url)
End Sub

Sub Button2_MouseClicked (EventData As MouseEvent)
	Dim sourceLang,targetLang,targetClass,text As String
	Dim params() As String=Regex.Split(",",ParamsTextArea.Text.SubString2(0,ParamsTextArea.Text.IndexOf(CRLF)))
	sourceLang=params(0)
	targetLang=params(1)
	targetClass=params(2)
	text=ParamsTextArea.Text.SubString2(ParamsTextArea.Text.IndexOf(CRLF),ParamsTextArea.Text.Length)
	LoadURLBasedOnTemplate(TemplateTextField.Text,sourceLang,targetLang,targetClass,text)
End Sub

