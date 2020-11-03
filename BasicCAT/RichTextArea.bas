B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.19
@EndOfDesignText@
#IgnoreWarnings: 12
#Event: TextChanged(Text As String)
#DesignerProperty: Key: Editable, DisplayName: Editable, FieldType: Boolean, DefaultValue: True, Description: Whether the text of the CodeView is Editable
'Class module
Private Sub Class_Globals

	Private mCallBack As Object
    Private mEventName As String
	Private mForm As Form 'ignore
	Private mBase As Pane
	Private DesignerCVCalled As Boolean
	Private Initialized As Boolean 'ignore
	Private CustomViewName As String = "RichTextArea" 'Set this to the name of your custom view to provide meaningfull error logging
	Private fx As JFX
	
	'Custom View Specific Vars
	Private JO As JavaObject				'To hold the wrapped CoreArea object
	Private CustomViewNode As Node			'So that we can call B4x exposed methods on the object and don't have to use Javaobject's RunMethod for everything
	Private mBaseJO As JavaObject			'So that we can call Methods not exposed to B4x on the base pane.
	'For string matching
	Private BRACKET_PATTERN  As String
	Private SPACE_PATTERN As String
	Private offset As Int=8
	Public Font As Font
	Public Tag As Object
	Private previousComposedText As String
	Private mDefaultBorderColor As Paint
	Private mHighLightColor As Paint
	Private mLineHeightTimes As Double=0
End Sub

'Initializes the object.
'For a custom view these should not be changed, if you need more parameters for a Custom view added by code, you can add them to the
'setup sub, or an additional Custom view control method
'Required for both designer and code setup. 
Public Sub Initialize (vCallBack As Object, vEventName As String)
	'CallBack Module and eventname are provided by the designer, and need to be provided if setting up in code
	'These allow callbacks to the defining module using CallSub(mCallBack,mEventname), or CallSub2 or CallSub3 to pass parameters, or CallSubDelayed....
	mCallBack = vCallBack
	mEventName = vEventName
	Font=fx.DefaultFont(15)
	mDefaultBorderColor=fx.Colors.DarkGray
	mHighLightColor=fx.Colors.RGB(135,206,235)
	If File.Exists(File.DirData("BasicCAT"),"offset") Then
		offset=File.ReadString(File.DirData("BasicCAT"),"offset")
	End If
End Sub

Public Sub DesignerCreateView(Base As Pane, Lbl As Label, Props As Map)
	'Check this is not called from setup
	If Not(Props.GetDefault("CVfromsetup",False)) Then DesignerCVCalled = True
	
	'Assign vars to globals
	mBase = Base
	mBase.Tag=Me
	SetDefaultBorder
	'So that we can Call Runmethod on the Base Panel to run non exposed methods
	mBaseJO = Base

	'This is passed from either the designer or setup
	mForm = Props.get("Form")

	'Initialize our wrapper object
	JO.InitializeNewInstance("org.fxmisc.richtext.CodeArea",Null)
	setupIM
	addContextMenu
	'Cast the wrapped view to a node so we can use B4x Node methods on it.
	CustomViewNode = GetObject
	'Add the stylesheet to colour matching words to the code area node
	'JO.RunMethodJO("getStylesheets",Null).RunMethod("add",Array(File.GetUri(File.DirAssets,"richtext.css")))
	
	
	'TextProperty Listener
	'Add an eventlistener to the ObservableValue "textProperty" so that we can get changes to the text
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","TextChanged","")
	JO.RunMethodJO("textProperty",Null).RunMethod("addListener",Array(Event))
	
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","SelectedTextChanged","")
	JO.RunMethodJO("selectedTextProperty",Null).RunMethod("addListener",Array(Event))
	
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","FocusChanged","")
	JO.RunMethodJO("focusedProperty",Null).RunMethod("addListener",Array(Event))
	
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","RedoAvailable","")
	JO.RunMethodJO("redoAvailableProperty",Null).RunMethod("addListener",Array(Event))
	
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","UndoAvailable","")
	JO.RunMethodJO("undoAvailableProperty",Null).RunMethod("addListener",Array(Event))
	
	
	Dim r As Reflector
	r.Target = JO
	r.AddEventFilter("Scroll", "javafx.scene.input.ScrollEvent.SCROLL")
	Dim r As Reflector
	r.Target = JO
	r.AddEventFilter("KeyPressed", "javafx.scene.input.KeyEvent.KEY_PRESSED")
	
	'BaseChanged Listener
	'Add an eventlistener to the ReadOnlyObjectProperty "layoutBoundsProperty" on the Base Pane so that we can change the internal layout to fit
	Dim Event As Object = JO.CreateEvent("javafx.beans.value.ChangeListener","BaseResized","")
	mBaseJO.RunMethodJO("layoutBoundsProperty",Null).RunMethod("addListener",Array(Event))
	
	Dim O As Object = JO.CreateEventFromUI("javafx.event.EventHandler","KeyPressed",Null)
	JO.RunMethod("setOnKeyPressed",Array(O))
	JO.RunMethod("setFocusTraversable",Array(True))

	
	'Deal with properties we have been passed
	setEditable(Props.Get("Editable"))
	
	
	'Create your CustomView layout in sub CreateLayout
	CreateLayout
	
	'Other Custom Initializations
	InitializePatterns
	
	'Finally
	Initialized = True
End Sub

'Manual Setup of Custom View Pass Null to Pnl if adding to Form
Sub Setup(Form As Form,Pnl As Pane,Left As Int,Top As Int,Width As Int,Height As Int)
	'Check if DesignerCreateView has been called
	If DesignerCVCalled Then
		Log(CustomViewName & ": You should not call setup if you have defined this view in the designer")
		ExitApplication
	End If
	
	mForm = Form
	
	'Create our own base panel
	Dim Base As Pane
	Base.Initialize("")
	
	'If Null was passed, a Panel wii be created by casting, but it won't be initialized
	If Pnl.IsInitialized Then
		Pnl.AddNode(Base,Left,Top,Width,Height)
	Else
		Form.RootPane.AddNode(Base,Left,Top,Width,Height)
	End If
		
	'Set up variables to pass to DesignerCreateView so we don't have to maintain two identical subs to create the custom view
	Dim M As Map
	M.Initialize
	M.Put("Form",Form)
	M.Put("Editable",True)
	'As we are passing a map, we can use it to pass an additional flag for our own use 
	'with an ID unlikely To be used by B4a In the future
	M.Put("CVfromsetup",True)
	
	'We need a label to pass to DesignerCreateView
	Dim L As Label
	L.Initialize("")
	'Default text alignment
	CSSUtils.SetStyleProperty(L,"-fx-text-alignment","center")
	'Default size for Custom View text in designer is 15
	L.Font = fx.DefaultFont(15)
	
	'Call designer create view
	DesignerCreateView(Base,L,M)
	
End Sub


'Set the initial layout for the custom view
Private Sub CreateLayout
	
	'Add the wrapper object to customview mBase
    mBase.AddNode(CustomViewNode,offset,offset,mBase.Width-2*offset,mBase.Height-2*offset)
	
	'Add any other Nodes to the CustomView
	
End Sub

'Called by a BaseChanged Listener when mBase size changes
Private Sub BaseResized_Event(MethodName As String,Args() As Object) As Object			'ignore
	
	'Make our node added to the Base Pane the same size as the Base Pane
    CustomViewNode.PrefWidth = mBase.Width-2*offset
    CustomViewNode.PrefHeight = mBase.Height-2*offset
	
	'Make any changes needed to other integral nodes
	UpdateLayout
End Sub

'Update the layout as needed when the Base Pane has changed size.
Private Sub UpdateLayout
	
End Sub

Public Sub setLeft(left As Int)
	mBase.Left=left
End Sub

Sub setEnabled(enabled As Boolean)
	mBase.Enabled=enabled
	If enabled=False Then
		CustomViewNode.Alpha=0.5
		'CSSUtils.SetBackgroundColor(CustomViewNode,fx.Colors.DarkGray)
	Else
		CustomViewNode.Alpha=1.0
	End If
End Sub

Sub setLineHeightTimes(times As Double)
	mLineHeightTimes=times
End Sub

Sub getBasePane As Pane
	Return mBase
End Sub

Sub getHeight As Double
	Return mBase.Height
End Sub

Sub setHeight(height As Double)
	mBase.PrefHeight=height
End Sub

Sub getWidth As Double
	Return mBase.width
End Sub

Sub setWidth(width As Double)
	mBase.PrefWidth=width
End Sub

Sub getParent As Node
	Return mBase.Parent
End Sub

Sub getSelectionStart As Double
	Return getSelection(0)
End Sub

Sub getSelectionEnd As Double
	Return getSelection(1)
End Sub

Sub setSelection(startIndex As Int,endIndex As Int)
	JO.RunMethod("selectRange",Array(startIndex,endIndex))
End Sub

Sub RequestFocus
	JO.RunMethod("requestFocus",Null)
End Sub

Sub setWrapText(wrap As Boolean)
	JO.RunMethod("setWrapText",Array(wrap))
End Sub

Public Sub resetBorderColor
	mDefaultBorderColor=fx.Colors.DarkGray
End Sub

Public Sub setDefaultBorderColor(color As Paint)
	mDefaultBorderColor=color
	SetDefaultBorder
End Sub

Public Sub getDefaultBorderColor As Paint
	Return mDefaultBorderColor
End Sub

Public Sub SetDefaultBorder
	Dim width As Double
	If mDefaultBorderColor<>fx.Colors.DarkGray Then
		width=3
	Else
		width=0.5
	End If
	CSSUtils.SetBorder(mBase,width,mDefaultBorderColor,3)
	'CSSUtils.SetStyleProperty(mBase,"-fx-effect","null")
End Sub

Public Sub SetBorderInHighlight(color As Paint)
	CSSUtils.SetBorder(mBase,3,color,3)
	'CSSUtils.SetStyleProperty(mBase,"-fx-effect","dropshadow(gaussian, skyblue , 3, 1, 0, 0)")
End Sub

Sub FocusChanged_Event (MethodName As String,Args() As Object) As Object							'ignore
	Dim hasFocus As Boolean=Args(2)
	If SubExists(mCallBack,mEventName & "_FocusChanged") Then
		CallSubDelayed2(mCallBack,mEventName & "_FocusChanged",hasFocus)
	End If
	CallSubDelayed2(Me,"AdjustBorder",hasFocus)
End Sub

Sub AdjustBorder(hasFocus As Boolean)
	If hasFocus Then
		SetBorderInHighlight(mHighLightColor)
	Else
		SetDefaultBorder
	End If
End Sub

Public Sub setHighLightColor(color As Paint)
	mHighLightColor=color
End Sub

Public Sub getHighLightColor As Paint
	Return mHighLightColor
End Sub

Sub KeyPressed_Event (MethodName As String, Args() As Object) As Object 'ignore
	Dim KEvt As JavaObject = Args(0)
	Dim result As String
	result=KEvt.RunMethod("getCode",Null)
	If SubExists(mCallBack,mEventName & "_KeyPressed") Then
		CallSubDelayed2(mCallBack,mEventName & "_KeyPressed",result)
	End If
End Sub

Sub getSelection As Int()
	Dim indexRange As String=JO.RunMethodJO("getSelection",Null).RunMethod("toString",Null)
	Dim selectionStart,selectionEnd As Int
	selectionStart=Regex.Split(",",indexRange)(0)
	selectionEnd=Regex.Split(",",indexRange)(1)
	Return Array As Int(selectionStart,selectionEnd)
End Sub

'Convenient method to assign a single style class.
Public Sub SetStyleClass(SetFrom As Int, SetTo As Int, Class As String)
	JO.RunMethod("setStyleClass",Array As Object(SetFrom, SetTo, Class))
End Sub

'Gets the value of the property length.
Public Sub Length As Int
	Return JO.RunMethod("getLength",Null)
End Sub

Public Sub getText As String
	Return JO.RunMethod("getText",Null)
End Sub

Public Sub setText(str As String)
	JO.RunMethod("replaceText",Array As Object(0, Length, str))
	updateStyleSpans
End Sub

'Replaces a range of characters with the given text.
Public Sub ReplaceText(Start As Int, ThisEnd As Int, str As String)
	JO.RunMethod("replaceText",Array As Object(Start, ThisEnd, str))
	updateStyleSpans
End Sub

'Get/Set the CodeArea Editable
Public Sub setEditable(Editable As Boolean)
	JO.RunMethod("setEditable",Array(Editable))
End Sub

Public Sub getEditable As Boolean
	Return JO.RunMethod("isEditable",Null)
End Sub

'Get the unwrapped object
Public Sub GetObject As Object
	Return JO
End Sub

'Get the unwrapped object As a JavaObject
Public Sub GetObjectJO As JavaObject
	Return JO
End Sub
'Comment if not needed

'Set the underlying Object, must be of correct type
Public Sub SetObject(Obj As Object)
	JO = Obj
End Sub

Public Sub LineHeight As Double
	Return Utils.MeasureMultilineTextHeight(Font,mBase.Width-2*offset,"a")
End Sub

Public Sub totalHeightEstimate As Double
	Dim height As Double=20
	Try
		height=Max(height,JO.RunMethod("getTotalHeightEstimate",Null))
	Catch
		'Log(LastException)
		Return mBase.Height
	End Try
	height=height+2*offset
	Return height
End Sub

Public Sub totalHeight As Double
	Dim height As Double=20
	Try
		height=Max(height,JO.RunMethod("getTotalHeightEstimate",Null))
		If mLineHeightTimes>0 Then
			height=height+mLineHeightTimes*LineHeight
		End If
	Catch
		'Log(LastException)
		Return mBase.Height
	End Try
	height=height+2*offset
	Return height
End Sub

Sub AdjustHeight
	mBase.SetSize(mBase.Width,totalHeightEstimate)
End Sub

Sub setFontFamily(name As String)
	CSSUtils.SetStyleProperty(JO,"-fx-font-family",name)
	Font=fx.CreateFont(name,Font.Size,False,False)
End Sub

Sub setFontSzie(pixel As Int)
	CSSUtils.SetStyleProperty(JO,"-fx-font-size",pixel&"px")
	Font=fx.CreateFont(Font.FamilyName,pixel,False,False)
End Sub

'Callback from TextProperty Listener when the codearea text changes
Sub TextChanged_Event(MethodName As String,Args() As Object) As Object							'ignore
	updateStyleSpans
	If SubExists(mCallBack,mEventName & "_TextChanged") Then
		CallSubDelayed3(mCallBack,mEventName & "_TextChanged",Args(1),Args(2))
	End If
End Sub

Sub updateStyleSpans
	JO.RunMethod("setStyleSpans",Array(0,ComputeHighlightingB4x(getText)))
End Sub

Sub SelectedTextChanged_Event(MethodName As String,Args() As Object) As Object							'ignore
	If SubExists(mCallBack,mEventName & "_SelectedTextChanged") Then
		CallSubDelayed3(mCallBack,mEventName & "_SelectedTextChanged",Args(1),Args(2))
	End If
	updateContextMenuBasedOnSelection(Args(2))
End Sub

'Setup for pattern matching
Sub InitializePatterns
    BRACKET_PATTERN="<.*?>"
    SPACE_PATTERN = " *"
End Sub

'Create the style types for matching words
Sub ComputeHighlightingB4x(str As String) As JavaObject

	'Dim PMatcher As PatternMatcher = Pattern1.Matcher(Text)
    Dim Matcher As Matcher = Regex.Matcher($"(?<BRACKET>${BRACKET_PATTERN})|(?<SPACE>${SPACE_PATTERN})"$,str)
	Dim MJO As JavaObject = Matcher
	
	Dim SpansBuilder As JavaObject
	SpansBuilder.InitializeNewInstance("org.fxmisc.richtext.model.StyleSpansBuilder",Null)
	
	Dim Collections As JavaObject
	Collections.InitializeStatic("java.util.Collections")
	
	Dim LastKwEnd As Int = 0
	Dim StyleClass As String
	Dim Index As Int
	Do While Matcher.Find
		StyleClass = ""
		If Matcher.Group(2) <> Null Then
			Index = 2
			StyleClass = "space"
		Else
			If Matcher.Group(1) <> Null Then 
				Index = 1
				StyleClass = "bracket"
			End If
		End If
		Dim StrLength As Int = Matcher.GetStart(Index) - LastKwEnd
		SpansBuilder.RunMethod("add",Array(Collections.RunMethod("emptyList",Null),StrLength))
		StrLength = MJO.RunMethod("end",Null) - Matcher.GetStart(Index)
		SpansBuilder.RunMethod("add",Array(Collections.RunMethod("singleton",Array(StyleClass)),StrLength))
		LastKwEnd = Matcher.GetEnd(Index)
	Loop
	SpansBuilder.RunMethod("add",Array(Collections.RunMethod("emptyList",Null),str.Length - LastKwEnd))
	Return SpansBuilder.RunMethod("create",Null)
End Sub

Public Sub setupIM
	Dim o As JavaObject
	o.InitializeNewInstance("com.xulihang.InputMethodRequestsObject",Null)
	o.RunMethod("setArea",Array(GetObject))
	Dim event As Object = JO.CreateEventFromUI("javafx.event.EventHandler","InputMethodTextChanged",Null)
	JO.RunMethod("setInputMethodRequests",Array(o))
	JO.RunMethod("setOnInputMethodTextChanged",Array(event))
End Sub

Sub InputMethodTextChanged_Event(MethodName As String,Args() As Object) As Object							'ignore
	Dim e As JavaObject=Args(0)
	JO.RunMethod("replaceSelection",Array(""))
	Dim startIndex,endIndex As Int
	startIndex=JO.RunMethod("getCaretPosition",Null)-previousComposedText.Length
	endIndex=JO.RunMethod("getCaretPosition",Null)
	JO.RunMethod("deleteText",Array(startIndex, endIndex))
	If e.RunMethod("getCommitted",Null)<>"" Then
		JO.RunMethod("insertText",Array(JO.RunMethod("getCaretPosition",Null), e.RunMethod("getCommitted",Null)))
		previousComposedText=""
	Else
		Dim sb As StringBuilder
		sb.Initialize
		Dim composed As List=e.RunMethod("getComposed",Null)
		For Each run As JavaObject In composed
			sb.Append(run.RunMethod("getText",Null))
		Next
		previousComposedText=sb.ToString
		JO.RunMethod("insertText",Array(JO.RunMethod("getCaretPosition",Null), sb.ToString))
	End If
End Sub

Sub Scroll_Filter (EventData As Event)
	If mBase.Height>totalHeightEstimate-2*offset Then
		Dim e As JavaObject = EventData
		Dim Parent As Node
		Parent=mBase.Parent
		Dim ParentJO As JavaObject=Parent
		Dim event As Object=e.RunMethod("copyFor",Array(e.RunMethod("getSource",Null),Parent))
		ParentJO.RunMethod("fireEvent",Array(event))
		EventData.Consume
	End If
End Sub

Sub KeyPressed_Filter (EventData As Event)
	Dim e As JavaObject = EventData
	Dim code As String = e.RunMethod("getCode", Null)
	If code = "ENTER" Then
		If SubExists(mCallBack,mEventName & "_KeyPressed") Then
			CallSubDelayed2(mCallBack,mEventName & "_KeyPressed",code)
		End If
		EventData.Consume
	End If
End Sub

Sub UndoAvailable_Event(MethodName As String,Args() As Object) As Object							'ignore
	updateContextMenuInTermsofUndoRedo
End Sub

Sub RedoAvailable_Event(MethodName As String,Args() As Object) As Object							'ignore
	updateContextMenuInTermsofUndoRedo
End Sub

Sub addContextMenu
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim style As String=$"-fx-font-size:16px;-fx-font-family:"serif";"$
	For Each text As String In Array("Cut","Copy","Paste","Undo","Redo","Select all")
		Dim mi As MenuItem
		mi.Initialize(text,"mi")
		Dim miJO As JavaObject=mi
		miJO.RunMethod("setStyle",Array(style))
		cm.MenuItems.Add(mi)
	Next
	JO.RunMethod("setContextMenu",Array(cm))
	updateContextMenuBasedOnSelection("")
	updateContextMenuInTermsofUndoRedo
End Sub

Sub updateContextMenuBasedOnSelection(new As String)
	Dim cm As ContextMenu=JO.RunMethod("getContextMenu",Null)
	For Each mi As MenuItem In cm.MenuItems
		If mi.Text="Copy" Or mi.Text="Cut" Then
			If new="" Then
				mi.Enabled=False
			Else
				mi.Enabled=True
			End If
		End If
	Next
End Sub

Sub updateContextMenuInTermsofUndoRedo
	Dim cm As ContextMenu=JO.RunMethod("getContextMenu",Null)
	For Each mi As MenuItem In cm.MenuItems
		Select mi.Text
			Case "Undo"
				If JO.RunMethod("isUndoAvailable",Null) Then
					mi.Enabled=True
				Else
					mi.Enabled=False
				End If
			Case "Redo"
				If JO.RunMethod("isRedoAvailable",Null) Then
					mi.Enabled=True
				Else
					mi.Enabled=False
				End If
		End Select
	Next
End Sub


Sub mi_Action
	Dim mi As MenuItem=Sender
	Select mi.Text
		Case "Copy"
			JO.RunMethod("copy",Null)
		Case "Cut"
			JO.RunMethod("cut",Null)
		Case "Paste"
			JO.RunMethod("paste",Null)
		Case "Select all"
			setSelection(0,getText.Length)
		Case "Undo"
			JO.RunMethod("undo",Null)
		Case "Redo"
			JO.RunMethod("redo",Null)
	End Select
End Sub
