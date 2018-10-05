B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private findTextField As TextField
	Private replaceTextField As TextField
	Private resultListView As ListView
	Private regexCheckBox As CheckBox
	Private searchSourceCheckBox As CheckBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("searchandreplace")
End Sub

Public Sub show
    frm.Show	
End Sub

Sub resultListView_SelectedIndexChanged(Index As Int)
	
End Sub

Sub findButton_Click
	resultListView.Items.Clear
    If regexCheckBox.Checked Then
		showRegexResult
	Else
		showResult
    End If
End Sub

Sub showRegexResult
	Try
		Regex.Matcher(findTextField.Text,"").Find
	Catch
		fx.Msgbox(frm,"Invalid expression","")
		Return
		Log(LastException)
	End Try
	Dim index As Int=-1
	For Each bitext As List In Main.currentProject.segments
		index=index+1
		Dim tf As TextFlow
		tf.Initialize
		Dim source,target,pattern,sourceLeft,targetLeft As String
		source=bitext.Get(0)
		target=bitext.Get(1)
		sourceLeft=source
		targetLeft=target
		pattern=findTextField.Text
		'Log(pattern)
		Dim textSegments As List
		textSegments.Initialize
		Dim sourceMatcher,targetMatcher As Matcher
		sourceMatcher=Regex.Matcher(pattern,source)
		targetMatcher=Regex.Matcher(pattern,target)
		Dim inSource,inTarget As Boolean
		inSource=Regex.Matcher(pattern,source).Find
		inTarget=Regex.Matcher(pattern,target).Find
		
		Dim shouldShow As Boolean=False
		
		If searchSourceCheckBox.Checked Then
			If inSource Or inTarget Then
				shouldShow=True
			End If
		Else
			If inTarget Then
				shouldShow=True
			End If
		End If
		
		tf.AddText("Source: ")
		If shouldShow Then

			If searchSourceCheckBox.Checked Then
				If inSource Then
					Do While sourceMatcher.Find
						Log("Found: " & sourceMatcher.Match)
						Dim textBefore As String
						textBefore=sourceLeft.SubString2(0,sourceLeft.IndexOf(sourceMatcher.Match))
						If textBefore<>"" Then
							tf.AddText(textBefore)
							textSegments.Add(textBefore)
						End If
						tf.AddText(sourceMatcher.Match).SetColor(fx.Colors.Blue).SetUnderline(True)
						sourceLeft=sourceLeft.SubString2(sourceLeft.IndexOf(sourceMatcher.Match)+sourceMatcher.Match.Length,sourceLeft.Length)
					Loop
					tf.AddText(sourceLeft)
				Else
					tf.AddText(source)
				End If
			Else
				tf.AddText(source)
			End If
			tf.AddText(CRLF&"Target: ")

			If inTarget Then
			    Do While targetMatcher.Find
					Dim find As String
			        find=targetMatcher.Match
					Dim textBefore As String
					textBefore=targetLeft.SubString2(0,targetLeft.IndexOf(find))
					If textBefore<>"" Then
						tf.AddText(textBefore)
						textSegments.Add(textBefore)
					End If
					tf.AddText(find).SetColor(fx.Colors.Blue).SetUnderline(True)
					textSegments.Add(find)
					targetLeft=targetLeft.SubString2(targetLeft.IndexOf(find)+find.Length,targetLeft.Length)
				Loop
				tf.AddText(targetLeft)
				textSegments.Add(targetLeft)
				tf.AddText(CRLF&"After: ")

				For Each text As String In textSegments
					Log("text"&text)
					If Regex.IsMatch(pattern,text) Then
						Dim replace As String
						replace=Regex.Replace(pattern,text,replaceTextField.Text)
						Log("replace"&replace)
						If replace="" Then
							tf.AddTextWithStrikethrough(text,"").SetColor(fx.Colors.Red)
						Else
							tf.AddText(replace).SetColor(fx.Colors.Green).SetUnderline(True)
						End If
					Else
						tf.AddText(text)
					End If
				Next
				
			Else
				tf.AddText(target)
				tf.AddText(CRLF&"After: ")
				tf.AddText(target)
			End If
			Dim tagList As List
			tagList.Initialize
			tagList.Add(index)
			tagList.Add(tf.getText)
			Dim pane As Pane = tf.CreateTextFlow
			pane.Tag=tagList
			pane.SetSize(resultListView.Width,utils.MeasureMultilineTextHeight(fx.DefaultFont(15),resultListView.Width,tagList.Get(1)))
			resultListView.Items.Add(pane)
		End If

	Next
End Sub

Sub showResult
	Dim index As Int=-1
	For Each bitext As List In Main.currentProject.segments
		index=index+1
		Dim source,target,find,sourceLeft,targetLeft As String
		source=bitext.Get(0)
		target=bitext.Get(1)
		find=findTextField.Text
		targetLeft=target
		sourceLeft=source
		Dim tf As TextFlow
		tf.Initialize
		Dim textSegments As List
		textSegments.Initialize
		
		Dim shouldShow As Boolean=False
		If searchSourceCheckBox.Checked Then
			If source.Contains(find) Or target.Contains(find) Then
				shouldShow=True
			End If
		Else
			If target.Contains(find) Then
				shouldShow=True
			End If
		End If
		
		
		If shouldShow Then
			tf.AddText("Source: ")
			If searchSourceCheckBox.Checked Then
				If source.Contains(find) Then
					addText(tf,source,find,textSegments,False)
				Else
					tf.AddText(source)
				End If
			Else
				tf.AddText(source)
			End If

			tf.AddText(CRLF&"Target: ")
			If target.Contains(find) Then
				addText(tf,target,find,textSegments,True)
				tf.AddText(CRLF&"After: ")

				For Each text As String In textSegments
					If text=find Then
						If replaceTextField.Text="" Then
							tf.AddTextWithStrikethrough(find,"").SetColor(fx.Colors.Red)
						Else
							tf.AddText(replaceTextField.Text).SetColor(fx.Colors.Green).SetUnderline(True)
						End If
						
					Else
						tf.AddText(text)
					End If
				Next
			Else
				tf.AddText(target)
				tf.AddText(CRLF&"After: ")
				tf.AddText(target)
			End If
			
			Dim tagList As List
			tagList.Initialize
			tagList.Add(index)
			tagList.Add(tf.getText)
			Dim pane As Pane = tf.CreateTextFlow
			pane.Tag=tagList
			pane.SetSize(resultListView.Width,Utils.MeasureMultilineTextHeight(fx.DefaultFont(15),resultListView.Width,tagList.Get(1)))
			resultListView.Items.Add(pane)
		End If
	Next
End Sub

Sub addText(tf As TextFlow,target As String,find As String,textSegments As List,isInTarget As Boolean)
	Dim targetLeft As String
	targetLeft=target
	Dim currentSegment As String
	Dim length As Int
	length=target.Length-find.Length
	Log(length)
	For i=0 To length
		Log(i)
		Dim endIndex As Int
		endIndex=i+find.Length
		currentSegment=target.SubString2(i,endIndex)
		Log(currentSegment)
		If currentSegment=find Then
			Log(True)
			Dim textBefore As String
            Log(targetLeft)
			textBefore=targetLeft.SubString2(0,targetLeft.IndexOf(find))
			If textBefore<>"" Then
				tf.AddText(textBefore)
				textSegments.Add(textBefore)
			End If
			tf.AddText(find).SetColor(fx.Colors.Blue).SetUnderline(True)
			textSegments.Add(find)
			Log("tb"&textBefore)
			Log("find"&find)
			targetLeft=targetLeft.SubString2(targetLeft.IndexOf(find)+find.Length,targetLeft.Length)
			Log("left"&targetLeft)
			Log(targetLeft.IndexOf(find))
		End If
	Next
	tf.AddText(targetLeft)
	textSegments.Add(targetLeft)
	If isInTarget=False Then
		textSegments.Clear
	End If
End Sub

Sub CountMatches(str As String,substr As String) As Int
    Dim times As Int=0
	Dim currentSegment As String
	For i=0 To str.Length-substr.Length
		currentSegment=str.SubString2(i,i+substr.Length)
		If currentSegment=substr Then
			times=times+1
		End If
	Next
	Return times
End Sub

Sub resultListView_Resize (Width As Double, Height As Double)
	For Each p As Pane In resultListView.Items
		Dim tagList As List
		tagList=p.Tag
		p.SetSize(Width,utils.MeasureMultilineTextHeight(fx.DefaultFont(15),Width,tagList.Get(1)))
	Next
End Sub

Sub replaceSelectedButton_MouseClicked (EventData As MouseEvent)
	If resultListView.SelectedItem<>Null Then
		Dim p As Pane
		p=resultListView.SelectedItem
		Dim tagList As List
		tagList=p.Tag
		Dim target,after As String
		Log(Regex.Split(CRLF,tagList.Get(1)))
		target=Regex.Split(CRLF,tagList.Get(1))(1)
		target=target.SubString2("Target: ".Length,target.Length)
		after=Regex.Split(CRLF,tagList.Get(1))(2)
		after=after.SubString2("After: ".Length,after.Length)
		Dim bitext As List
		bitext=Main.currentProject.segments.Get(tagList.Get(0))
		If bitext.Get(1)=target Then
			bitext.Set(1,after)
		End If
		Main.currentProject.segments.Set(tagList.Get(0),bitext)
		Main.currentProject.fillVisibleTargetTextArea
		resultListView.Items.RemoveAt(resultListView.SelectedIndex)
	End If
End Sub

Sub replaceAllButton_MouseClicked (EventData As MouseEvent)
	
	If resultListView.Items.Size>0 Then
		Dim count As Int=0
		Dim tempList As List
		tempList.Initialize
		tempList.AddAll(resultListView.Items)
		For Each p As Pane In tempList
			Dim tagList As List
			tagList=p.Tag
			Dim target,after As String
			Log(Regex.Split(CRLF,tagList.Get(1)))
			target=Regex.Split(CRLF,tagList.Get(1))(1)
			target=target.SubString2("Target: ".Length,target.Length)
			after=Regex.Split(CRLF,tagList.Get(1))(2)
			after=after.SubString2("After: ".Length,after.Length)
			Dim bitext As List
			bitext=Main.currentProject.segments.Get(tagList.Get(0))
			If bitext.Get(1)=target Then
				bitext.Set(1,after)
			End If
			Main.currentProject.segments.Set(tagList.Get(0),bitext)
			Main.currentProject.fillVisibleTargetTextArea
			resultListView.Items.RemoveAt(resultListView.Items.IndexOf(p))
			count=count+1
		Next
        fx.Msgbox(frm,count&" matches are replaced.","")
	End If
	

End Sub

Sub resultListView_Action
	Dim p As Pane
	p=resultListView.Items.Get(resultListView.SelectedIndex)
	Dim taglist As List
	taglist=p.Tag
	Main.editorLV.JumpToItem(taglist.get(0))
	Main.MainForm.AlwaysOnTop=True
	Main.MainForm.AlwaysOnTop=False
End Sub





