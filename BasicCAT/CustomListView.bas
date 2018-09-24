B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.3
@EndOfDesignText@
'xCustomListView v1.64

#Event: ItemClick (Index As Int, Value As Object)
#Event: ReachEnd
#Event: VisibleRangeChanged (FirstIndex As Int, LastIndex as Int)
#Event: ScrollChanged (Offset As Int)
#DesignerProperty: Key: DividerColor, DisplayName: Divider Color, FieldType: Color, DefaultValue: 0xFFD9D7DE
#DesignerProperty: Key: DividerHeight, DisplayName: Divider Height, FieldType: Int, DefaultValue: 2
#DesignerProperty: Key: PressedColor, DisplayName: Pressed Color, FieldType: Color, DefaultValue: 0xFF7EB4FA
#DesignerProperty: Key: InsertAnimationDuration, DisplayName: Insert Animation Duration, FieldType: Int, DefaultValue: 300
#DesignerProperty: Key: ListOrientation, DisplayName: List Orientation, FieldType: String, DefaultValue: Vertical, List: Vertical|Horizontal
#DesignerProperty: Key: ShowScrollBar, DisplayName: Show Scroll Bar, FieldType: Boolean, DefaultValue: True, Description: Whether to show the scrollbar (when needed).
Sub Class_Globals
	Private mBase As B4XView
	Public sv As B4XView
	Type CLVItem(Panel As B4XView, Size As Int, Value As Object, _
		Color As Int, TextItem As Boolean, Offset As Int)
	Private items As List
	Private mDividerSize As Float
	Private EventName As String
	Private CallBack As Object
	Public DefaultTextColor As Int
	Public DefaultTextBackgroundColor As Int
	Public AnimationDuration As Int = 300
	Private LastReachEndEvent As Long
	Private PressedColor As Int
	Private xui As XUI
	Private DesignerLabel As Label
	Private horizontal As Boolean
#if B4J
	Private fx As JFX
#else if B4A
	Private su As StringUtils
#else if B4i

#end if
	Private mFirstVisibleIndex, mLastVisibleIndex As Int
	Private MonitorVisibleRange As Boolean
	Private FireScrollChanged As Boolean
	Private ScrollBarsVisible As Boolean
End Sub

Public Sub Initialize (vCallBack As Object, vEventName As String)
	EventName = vEventName
	CallBack = vCallBack
	items.Initialize
	DefaultTextBackgroundColor = xui.Color_White
	DefaultTextColor = xui.Color_Black
	MonitorVisibleRange = xui.SubExists(CallBack, EventName & "_VisibleRangeChanged", 2)
	FireScrollChanged = xui.SubExists(CallBack, EventName & "_ScrollChanged", 1)
	ResetVisibles
End Sub

Private Sub ResetVisibles
	mFirstVisibleIndex = -1
	mLastVisibleIndex = 0x7FFFFFFF
End Sub

'Causes the VisibleRangeChanged event to be raised
Public Sub Refresh
	ResetVisibles
	UpdateVisibleRange
End Sub

Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	Dim o As String = Props.GetDefault("ListOrientation", "Vertical")
	horizontal = o = "Horizontal"
	sv = CreateScrollView
	mBase.AddView(sv, 0, 0, mBase.Width, mBase.Height)
	'sv.ScrollViewInnerPanel.Color = xui.PaintOrColorToColor(Props.Get("DividerColor"))
	sv.ScrollViewInnerPanel.Color = xui.Color_White
	mDividerSize = DipToCurrent(Props.Get("DividerHeight")) 'need to scale the value
	PressedColor = xui.PaintOrColorToColor(Props.Get("PressedColor"))
	AnimationDuration = Props.GetDefault("InsertAnimationDuration", AnimationDuration)
	ScrollBarsVisible = Props.GetDefault("ShowScrollBar", True)
	If ScrollBarsVisible = False Then
		#if B4J
		Dim nsv As ScrollPane = sv
		nsv.SetHScrollVisibility("NEVER")
		nsv.SetVScrollVisibility("NEVER")
		#else if B4A
		Dim jsv As JavaObject = sv
		If horizontal Then
			jsv.RunMethod("setHorizontalScrollBarEnabled", Array(False))
		Else
			jsv.RunMethod("setVerticalScrollBarEnabled", Array(False))
		End If
		#else if B4i
		Dim no As NativeObject = sv
		no.RunMethod("setShowsHorizontalScrollIndicator:", Array(False))
		no.RunMethod("setShowsVerticalScrollIndicator:", Array(False))
		#End If
	End If
	DefaultTextColor = xui.PaintOrColorToColor(Lbl.TextColor)
	DefaultTextBackgroundColor = mBase.Color

	DesignerLabel = Lbl
	Base_Resize(mBase.Width, mBase.Height)
End Sub

Public Sub Base_Resize (Width As Double, Height As Double)
	sv.SetLayoutAnimated(0, 0, 0, Width, Height)
	Dim scrollbar As Int
	If xui.IsB4J And ScrollBarsVisible Then scrollbar = 20
	If horizontal Then
		sv.ScrollViewContentHeight = Height - scrollbar
		For Each it As CLVItem In items
			it.Panel.Height = sv.ScrollViewContentHeight
			it.Panel.GetView(0).Height = it.Panel.Height
		Next
	Else
		sv.ScrollViewContentWidth = Width - scrollbar
		For Each it As CLVItem In items
			it.Panel.Width = sv.ScrollViewContentWidth
			it.Panel.GetView(0).Width = it.Panel.Width
			If it.TextItem Then
				Dim lbl As B4XView = it.Panel.GetView(0).GetView(0)
				lbl.SetLayoutAnimated(0, lbl.Left, lbl.Top, it.Panel.Width - lbl.Left, lbl.Height)
			End If
		Next
	End If
	If items.Size > 0 Then UpdateVisibleRange
End Sub

Public Sub AsView As B4XView
	Return mBase
End Sub

'Clears all items.
Public Sub Clear
	items.Clear
	sv.ScrollViewInnerPanel.RemoveAllViews
	SetScrollViewContentSize(0)
	ResetVisibles
End Sub

Public Sub GetBase As B4XView
	Return mBase
End Sub

'Returns the number of items.
Public Sub getSize As Int
	Return items.Size
End Sub

'Returns the CLVItem. Should not be used in most cases.
Public Sub GetRawListItem(Index As Int) As CLVItem
	Return items.Get(Index)
End Sub

'Returns the Panel stored at the specified index.
Public Sub GetPanel(Index As Int) As B4XView
	Return GetRawListItem(Index).Panel.GetView(0)
End Sub

'Returns the value stored at the specified index.
Public Sub GetValue(Index As Int) As Object
	Return GetRawListItem(Index).Value
End Sub

'Removes the item at the specified index.
Public Sub RemoveAt(Index As Int)
	If getSize <= 1 Then
		Clear
		Return
	End If
	Dim RemoveItem As CLVItem = items.Get(Index)
	Dim p As B4XView
	For i = Index + 1 To items.Size - 1
		Dim item As CLVItem = items.Get(i)
		p = item.Panel
		p.Tag = i - 1
		Dim NewOffset As Int = item.Offset - RemoveItem.Size - mDividerSize
		SetItemOffset(item, NewOffset)
	Next
	SetScrollViewContentSize(GetScrollViewContentSize - RemoveItem.Size - mDividerSize)
	items.RemoveAt(Index)
	RemoveItem.Panel.RemoveViewFromParent
End Sub


'Adds a text item. The item height will be adjusted based on the text.
Public Sub AddTextItem(Text As Object, Value As Object)
	InsertAtTextItem(items.Size, Text, Value)
End Sub

'Inserts a text item at the specified index.
Public Sub InsertAtTextItem(Index As Int, Text As Object, Value As Object)
	If horizontal Then
		Log("AddTextItem is only supported in vertical orientation.")
		Return
	End If
	Dim pnl As B4XView = CreatePanel("")
	Dim lbl As B4XView = CreateLabel(Text)
	lbl.Height = Max(50dip, lbl.Height)
	pnl.AddView(lbl, 5dip, 2dip, sv.ScrollViewContentWidth - 10dip, lbl.Height)
	lbl.TextColor = DefaultTextColor
	pnl.Color = DefaultTextBackgroundColor
	pnl.Height = lbl.Height + 2dip
	InsertAt(Index, pnl, Value)
	Dim item As CLVItem = GetRawListItem(Index)
	item.TextItem = True
End Sub

'Adds a custom item at the specified index.
Public Sub InsertAt(Index As Int, pnl As B4XView, Value As Object)
	Dim size As Float
	If horizontal Then
		size = pnl.Width
	Else
		size = pnl.Height
	End If
	InsertAtImpl(Index, pnl, size, Value, 0)
End Sub

	
Private Sub InsertAtImpl(Index As Int, Pnl As B4XView, ItemSize As Int, Value As Object, InitialSize As Int)
	'create another panel to handle the click event
	Dim p As B4XView = CreatePanel("Panel")
	p.Color = Pnl.Color
	Pnl.Color = xui.Color_Transparent
	If horizontal Then
		p.AddView(Pnl, 0, 0, ItemSize, sv.ScrollViewContentHeight)
	Else
		p.AddView(Pnl, 0, 0, sv.ScrollViewContentWidth, ItemSize)
	End If
	p.Tag = Index
	Dim IncludeDividierHeight As Int
	If InitialSize = 0 Then IncludeDividierHeight = mDividerSize Else IncludeDividierHeight = 0
	Dim NewItem As CLVItem
	NewItem.Panel = p
	NewItem.Size = ItemSize
	NewItem.Value = Value
	NewItem.Color = p.Color
	If Index = items.Size And InitialSize = 0 Then
		items.Add(NewItem)
		Dim offset As Int
		If Index = 0 Then 
			offset = mDividerSize 
		Else
			offset = GetScrollViewContentSize
		End If
		NewItem.Offset = offset
		If horizontal Then
			sv.ScrollViewInnerPanel.AddView(p, offset, 0, ItemSize, sv.Height)
		Else
			sv.ScrollViewInnerPanel.AddView(p, 0, offset, sv.Width, ItemSize)
		End If
	Else
		Dim offset As Int
		If Index = 0 Then
			offset = mDividerSize
		Else
			Dim PrevItem As CLVItem = items.Get(Index - 1)
			offset = PrevItem.Offset + PrevItem.Size + mDividerSize
		End If
		For i = Index To items.Size - 1
			Dim It As CLVItem = items.Get(i)
			Dim NewOffset As Int = It.Offset + ItemSize - InitialSize + IncludeDividierHeight
			If Min(NewOffset, It.Offset) - GetScrollViewOffset < GetScrollViewVisibleSize Then
				It.Offset = NewOffset
				If horizontal Then
					It.Panel.SetLayoutAnimated(AnimationDuration, NewOffset, 0, It.Size, It.Panel.Height)
				Else
					It.Panel.SetLayoutAnimated(AnimationDuration, 0, NewOffset, It.Panel.Width, It.Size)
				End If
			Else
				SetItemOffset(It, NewOffset)
			End If
			It.Panel.Tag = i + 1
		Next
		items.InsertAt(Index, NewItem)
		NewItem.Offset = offset
		If horizontal Then
			sv.ScrollViewInnerPanel.AddView(p, offset, 0, InitialSize, sv.Height)
			p.SetLayoutAnimated(AnimationDuration, offset, 0, ItemSize, p.Height)
		Else
			sv.ScrollViewInnerPanel.AddView(p, 0, offset, sv.Width, InitialSize)
			p.SetLayoutAnimated(AnimationDuration, 0, offset, p.Width, ItemSize)
		End If
	End If
	SetScrollViewContentSize(GetScrollViewContentSize + ItemSize - InitialSize + IncludeDividierHeight)
	If items.Size = 1 Then SetScrollViewContentSize(GetScrollViewContentSize + IncludeDividierHeight)
	If Index < mLastVisibleIndex Or GetRawListItem(mLastVisibleIndex).Offset + _
			GetRawListItem(mLastVisibleIndex).Size + mDividerSize < GetScrollViewVisibleSize Then
		UpdateVisibleRange
	End If
End Sub

Private Sub UpdateVisibleRange
	If MonitorVisibleRange = False Or getSize = 0 Then Return
	Dim first As Int = getFirstVisibleIndex
	Dim last As Int = getLastVisibleIndex
	If first <> mFirstVisibleIndex Or last <> mLastVisibleIndex Then
		mFirstVisibleIndex = first
		mLastVisibleIndex = last
		CallSubDelayed3(CallBack, EventName & "_VisibleRangeChanged", mFirstVisibleIndex, mLastVisibleIndex)
	End If
End Sub

Private Sub GetScrollViewVisibleSize As Float
	If horizontal Then
		Return sv.Width
	Else
		Return sv.Height
	End If
End Sub

Private Sub GetScrollViewOffset As Float
	If horizontal Then
		Return sv.ScrollViewOffsetX
	Else
		Return sv.ScrollViewOffsetY
	End If
End Sub

Private Sub SetScrollViewOffset(offset As Float)
	If horizontal Then
		sv.ScrollViewOffsetX = offset
	Else
		sv.ScrollViewOffsetY = offset
	End If
End Sub

Private Sub GetScrollViewContentSize As Float
	If horizontal Then 
		Return sv.ScrollViewContentWidth
	Else
		Return sv.ScrollViewContentHeight
	End If
End Sub

Private Sub SetScrollViewContentSize(f As Float)
	If horizontal Then
		sv.ScrollViewContentWidth = f
	Else
		sv.ScrollViewContentHeight = f
	End If
End Sub

Private Sub SetItemOffset (item As CLVItem, offset As Float)
	item.Offset = offset
	If horizontal Then
		item.Panel.Left = offset
	Else
		item.Panel.Top = offset
	End If
End Sub

'Changes the height of an existing item.
Public Sub ResizeItem(Index As Int, ItemHeight As Int)
	Dim p As B4XView = GetPanel(Index)
	Dim value As Object = GetValue(Index)
	Dim parent As B4XView = p.Parent
	p.Color = parent.Color
	p.RemoveViewFromParent
	ReplaceAt(Index, p, ItemHeight, value)
End Sub


'Replaces the item at the specified index with a new item.
Public Sub ReplaceAt(Index As Int, pnl As B4XView, ItemHeight As Int, Value As Object)
	Dim RemoveItem As CLVItem = items.Get(Index)
	items.RemoveAt(Index)
	RemoveItem.Panel.RemoveViewFromParent
	InsertAtImpl(Index, pnl, ItemHeight, Value, RemoveItem.Size)
End Sub



'Adds a custom item.
Public Sub Add(Pnl As B4XView, Value As Object)
	InsertAt(items.Size, Pnl, Value)
End Sub

'Scrolls the list to the specified item (without animating the scroll).
Public Sub JumpToItem(Index As Int)
	SetScrollViewOffset(Min(GetMaxScrollOffset, FindItemOffset(Index)))
End Sub

Private Sub GetMaxScrollOffset As Float
	Return GetScrollViewContentSize - GetScrollViewVisibleSize
End Sub

'Smoothly scrolls the list to the specified item.
Public Sub ScrollToItem(Index As Int)
	Dim offset As Float = Min(GetMaxScrollOffset, FindItemOffset(Index)) 'ignore
	#if B4i
	Dim nsv As ScrollView = sv
	If horizontal Then
		nsv.ScrollTo(offset, 0, True)
	Else
		nsv.ScrollTo(0, offset, True)
	End If
	#else if B4J 
	JumpToItem(Index)
	#Else If B4A
	
	If horizontal Then
		Dim hv As HorizontalScrollView = sv
		hv.ScrollPosition = offset 'smooth scroll
	Else
		Dim nsv As ScrollView = sv
		nsv.ScrollPosition = offset 
	End If
	#End If
End Sub

Private Sub FindItemOffset(Index As Int) As Int
	Return GetRawListItem(Index).Offset
End Sub

'Finds the index of the item (+ divider) based on the offset
Public Sub FindIndexFromOffset(Offset As Int) As Int
	'the next divider is added to the current item
	Dim Position As Int = items.Size / 2
	Dim StepSize As Int = Ceil(Position / 2)
	Do While True
	Dim CurrentItem As CLVItem = items.Get(Position)
		Dim NextOffset As Int
		If Position < items.Size - 1 Then
			NextOffset = GetRawListItem(Position + 1).Offset - 1
		Else
			NextOffset = 0x7FFFFFFF
		End If
		Dim PrevOffset As Int
		If Position = 0 Then
			PrevOffset = 0x80000000
		Else
			PrevOffset = CurrentItem.Offset
		End If
		If Offset > NextOffset Then
			Position = Min(Position + StepSize, items.Size - 1)
		Else if Offset < PrevOffset Then
			Position = Max(Position - StepSize, 0)
		Else
			Return Position
		End If
		StepSize = Ceil(StepSize / 2)
	Loop
	Return -1
End Sub

'Gets the index of the first visible item.
Public Sub getFirstVisibleIndex As Int
	Return FindIndexFromOffset(GetScrollViewOffset + mDividerSize)
End Sub

'Gets the index of the last visible item.
Public Sub getLastVisibleIndex As Int
	Return FindIndexFromOffset(GetScrollViewOffset + GetScrollViewVisibleSize)
End Sub

Private Sub PanelClickHandler(SenderPanel As B4XView)
	Dim clr As Int = GetRawListItem(SenderPanel.Tag).Color
	SenderPanel.SetColorAnimated(50, clr, PressedColor)
	If xui.SubExists(CallBack, EventName & "_ItemClick", 2) Then
		CallSub3(CallBack, EventName & "_ItemClick", SenderPanel.Tag, GetRawListItem(SenderPanel.Tag).Value)
	End If
	Sleep(200)
	SenderPanel.SetColorAnimated(200, PressedColor, clr)
End Sub

'Returns the index of the item that holds the given view.
Public Sub GetItemFromView(v As B4XView) As Int
	If items.Size=0 Then
		Return
	End If
	Dim parent = v As Object, current As B4XView
	Do While sv.ScrollViewInnerPanel <> parent
		current = parent
		parent = current.Parent
	Loop
	v = current
	Return v.Tag
End Sub

Private Sub ScrollHandler
	If items.Size = 0 Then Return
	Dim position As Int = GetScrollViewOffset
	If position + GetScrollViewVisibleSize >= GetScrollViewContentSize - 5dip And DateTime.Now > LastReachEndEvent + 100 Then
		If xui.SubExists(CallBack, EventName & "_ReachEnd", 0) Then
			LastReachEndEvent = DateTime.Now
			CallSubDelayed(CallBack, EventName & "_ReachEnd")
		Else
			LastReachEndEvent = DateTime.Now + 1000 * DateTime.TicksPerDay 'disable
		End If
	End If
	UpdateVisibleRange
	If FireScrollChanged Then
		CallSub2(CallBack, EventName & "_ScrollChanged", position)
	End If
End Sub

Private Sub CreatePanel (PanelEventName As String) As B4XView
	Return xui.CreatePanel(PanelEventName)
End Sub

Public Sub getDividerSize As Float
	Return mDividerSize
End Sub


'******************************* platform specific ***************************************************

#If B4A

Private Sub CreateScrollView As B4XView
	If horizontal Then
		Dim hv As HorizontalScrollView
		hv.Initialize(0, "sv")
		Return hv
	Else
		Dim nsv As ScrollView
		nsv.Initialize2(0, "sv")
		Return nsv
	End If
End Sub

Private Sub Panel_Click
	PanelClickHandler(Sender)
End Sub

Private Sub sv_ScrollChanged(Position As Int)
	ScrollHandler
End Sub

Private Sub CreateLabel(txt As Object) As B4XView
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Gravity = DesignerLabel.Gravity
	lbl.TextSize = DesignerLabel.TextSize
	lbl.SingleLine = False
	lbl.Text = txt
	lbl.Width = sv.ScrollViewContentWidth - 10dip
	lbl.Height = su.MeasureMultilineTextHeight(lbl, txt)
	Return lbl
End Sub

#else If B4i

Private Sub CreateScrollView As B4XView
	Dim nsv As ScrollView
	nsv.Initialize("sv", 0, 0)
	Return nsv
End Sub

Private Sub Panel_Click
	PanelClickHandler(Sender)
End Sub

Sub sv_ScrollChanged (OffsetX As Int, OffsetY As Int)
	ScrollHandler
End Sub

Private Sub CreateLabel(txt As Object) As B4XView
	Dim lbl As Label
	lbl.Initialize("")
	lbl.TextAlignment = DesignerLabel.TextAlignment
	lbl.Font = DesignerLabel.Font
	lbl.Multiline = True
	If txt Is AttributedString Then
		lbl.AttributedText = txt
	Else
		lbl.Text = txt
	End If
	lbl.Width = sv.ScrollViewContentWidth - 10dip
	lbl.SizeToFit
	Return lbl
End Sub

#else If B4J
Private Sub CreateScrollView As B4XView
	Dim nsv As ScrollPane
	nsv.Initialize("sv")
	If horizontal Then
		nsv.SetVScrollVisibility("NEVER")
	Else
		nsv.SetHScrollVisibility("NEVER")
	End If
	Return nsv
End Sub

Private Sub Panel_MouseClicked (EventData As MouseEvent)
	PanelClickHandler(Sender)
End Sub

Private Sub sv_VScrollChanged (Position As Double)
	ScrollHandler
End Sub

Private Sub sv_HScrollChanged (Position As Double)
	ScrollHandler
End Sub


Private Sub CreateLabel(txt As String) As B4XView
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Alignment = DesignerLabel.Alignment
	lbl.Style = DesignerLabel.Style
	lbl.Font = DesignerLabel.Font
	lbl.WrapText = True
	lbl.Text = txt
	Dim jo As JavaObject = Me
	Dim width As Double = sv.ScrollViewContentWidth - 10dip
	lbl.PrefHeight = 20dip + jo.RunMethod("MeasureMultilineTextHeight", Array(lbl.Font, txt, width))
	Return lbl
End Sub


#if Java

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import javafx.scene.text.Font;
import javafx.scene.text.TextBoundsType;
public double MeasureMultilineTextHeight(Font f, String text, double width) throws Exception {
		Method m = Class.forName("com.sun.javafx.scene.control.skin.Utils").getDeclaredMethod("computeTextHeight",
				Font.class, String.class, double.class, TextBoundsType.class);
		m.setAccessible(true);
		return (Double)m.invoke(null, f, text, width, TextBoundsType.LOGICAL);
	}
#End If

#End If