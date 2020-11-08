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
	Private sourceTextField As TextField
	Private MatchBothCheckBox As CheckBox
	Private ComboBox1 As ComboBox
	Private ExtendSearchCheckBox As CheckBox
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,300)
	frm.RootPane.LoadLayout("searchandreplace")
	ComboBox1.Items.Add("id")
	ComboBox1.Items.Add("note")
	ComboBox1.Items.Add("filename")
	ComboBox1.SelectedIndex=0
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

Sub CheckShouldShowBasedonExtendedItem(find As String,regexMode As Boolean,segment As List,default As Boolean) As Boolean
	If ExtendSearchCheckBox.Checked Then
		Dim extra As Map
		extra=segment.Get(4)
		Dim result As Boolean
		Select ComboBox1.Items.Get(ComboBox1.SelectedIndex)
			Case "filename"
				Dim innerFilename As String=segment.Get(3)
				result=HasMatch(regexMode,find,innerFilename)
			Case "id"
				Dim id As String=extra.GetDefault("id","")
				result=HasMatch(regexMode,find,id)
			Case "note"
				Dim note As String=extra.GetDefault("note","")
				result=HasMatch(regexMode,find,note)
		End Select
		Return result
	Else
		Return default
	End If
End Sub

Sub HasMatch(regexMode As Boolean,find As String,text As String) As Boolean
	If regexMode Then
		Return Regex.Matcher(find,text).Find
	Else
		Return text.Contains(find)
	End If
End Sub

Sub showRegexResult
	Try
		Regex.Matcher(findTextField.Text,"").Find
		Regex.Replace(findTextField.Text,"",replaceTextField.Text)
	Catch
		fx.Msgbox(frm,"Invalid expression","")
		Return
		Log(LastException)
	End Try
	Try
		Dim index As Int=-1
		For Each bitext As List In Main.currentProject.segments
			index=index+1
			Dim tf As TextFlow
			tf.Initialize
			Dim source,target,sourcePattern,pattern,sourceLeft,targetLeft As String
			source=bitext.Get(0)
			target=bitext.Get(1)
			sourceLeft=source
			targetLeft=target
			pattern=findTextField.Text
			sourcePattern=sourceTextField.Text
			'Log(pattern)
			Dim textSegments As List
			textSegments.Initialize
			Dim sourceMatcher,targetMatcher As Matcher
			sourceMatcher=Regex.Matcher(sourcePattern,source)
			targetMatcher=Regex.Matcher(pattern,target)
			Dim inSource,inTarget As Boolean
			If sourcePattern<>"" Then
				inSource=Regex.Matcher(sourcePattern,source).Find
			Else
				inSource=False
			End If
			If pattern<>"" Then
				inTarget=Regex.Matcher(pattern,target).Find
			Else
				inTarget=False
			End If
			
		
			Dim shouldShow As Boolean=False
		
			If searchSourceCheckBox.Checked Then
				If MatchBothCheckBox.Checked Then
					If inSource And inTarget Then
						shouldShow=True
					End If
				Else
					If inSource Or inTarget Then
						shouldShow=True
					End If
				End If
			Else
				If inTarget Then
					shouldShow=True
				End If		
				If pattern="" And target="" Then
					shouldShow=True
				End If
			End If

			
			shouldShow=CheckShouldShowBasedonExtendedItem(pattern,True,bitext,shouldShow)
			
			tf.AddText("- Source: ")
			If shouldShow Then

				If searchSourceCheckBox.Checked Then
					If inSource Then
						Do While sourceMatcher.Find
							Log("Found: " & sourceMatcher.Match)
							Dim textBefore As String
							textBefore=sourceLeft.SubString2(0,sourceLeft.IndexOf(sourceMatcher.Match))
							If textBefore<>"" Then
								tf.AddText(textBefore)
								'textSegments.Add(textBefore)
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
				tf.AddText(CRLF&"- Target: ")

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
					tf.AddText(CRLF&"- After: ")

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
					tf.AddText(CRLF&"- After: ")
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
	Catch
		Log(LastException)
		fx.Msgbox(frm,"Invalid expression","")
		Return
	End Try
End Sub

Sub showResult
	Dim index As Int=-1
	For Each bitext As List In Main.currentProject.segments
		index=index+1
		Dim source,target,find,sourceFind,sourceLeft,targetLeft As String
		source=bitext.Get(0)
		target=bitext.Get(1)
		find=findTextField.Text
		sourceFind=sourceTextField.Text
		targetLeft=target
		sourceLeft=source
		Dim tf As TextFlow
		tf.Initialize
		Dim textSegments As List
		textSegments.Initialize
		
		Dim shouldShow As Boolean=False
		Dim inSource,inTarget As Boolean
		If sourceFind<>"" Then
			inSource=source.Contains(sourceFind)
		Else
			inSource=False
		End If
		If find<>"" Then
			inTarget=target.Contains(find)
		Else
			inTarget=False
		End If
		
		If searchSourceCheckBox.Checked Then
			If MatchBothCheckBox.Checked Then
				If inSource And inTarget Then
					shouldShow=True
				End If
			Else
				If inSource Or inTarget Then
					shouldShow=True
				End If
			End If
		Else
			If inTarget Then
				shouldShow=True
			End If
			If find="" And target="" Then
				shouldShow=True
			End If
		End If
		
		shouldShow=CheckShouldShowBasedonExtendedItem(find,False,bitext,shouldShow)
		
		If shouldShow Then
			tf.AddText("- Source: ")
			If searchSourceCheckBox.Checked Then
				If inSource Then
					addText(tf,source,sourceFind,textSegments,False)
				Else
					tf.AddText(source)
				End If
			Else
				tf.AddText(source)
			End If
            
			tf.AddText(CRLF&"- Target: ")
			If inTarget Then
				addText(tf,target,find,textSegments,True)
				tf.AddText(CRLF&"- After: ")

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
				tf.AddText(CRLF&"- After: ")
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
    Utils.splitByFind(target,find,textSegments)
	For Each segment As String In textSegments
		If segment=find Then
			tf.AddText(find).SetColor(fx.Colors.Blue).SetUnderline(True)
		Else
			tf.AddText(segment)
		End If
	Next
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
		p.SetSize(Width,Utils.MeasureMultilineTextHeight(fx.DefaultFont(15),Width,tagList.Get(1)))
	Next
End Sub

Sub replaceSelectedButton_MouseClicked (EventData As MouseEvent)
	If resultListView.SelectedItem<>Null Then
		Dim p As Pane
		p=resultListView.SelectedItem
		Dim tagList As List
		tagList=p.Tag
		Dim target,after As String
		Log(Regex.Split(CRLF&"- ",tagList.Get(1)))
		target=Regex.Split(CRLF&"- ",tagList.Get(1))(1)
		target=target.SubString2("Target: ".Length,target.Length)
		after=Regex.Split(CRLF&"- ",tagList.Get(1))(2)
		after=after.SubString2("After: ".Length,after.Length)
		Dim bitext As List
		bitext=Main.currentProject.segments.Get(tagList.Get(0))
		If bitext.Get(1)=target Then
			'bitext.Set(1,after)
			Main.currentProject.setTranslation(tagList.Get(0),after,False,"")
		End If
		'Main.currentProject.setSegment(tagList.Get(0),bitext)
		Main.currentProject.fillVisibleTargetTextArea
		resultListView.Items.RemoveAt(resultListView.SelectedIndex)
		Main.currentProject.contentIsChanged
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
			Log(Regex.Split(CRLF&"- ",tagList.Get(1)))
			target=Regex.Split(CRLF&"- ",tagList.Get(1))(1)
			target=target.SubString2("Target: ".Length,target.Length)
			after=Regex.Split(CRLF&"- ",tagList.Get(1))(2)
			after=after.SubString2("After: ".Length,after.Length)
			Dim bitext As List
			bitext=Main.currentProject.segments.Get(tagList.Get(0))
			If bitext.Get(1)=target Then
				'bitext.Set(1,after)
				Main.currentProject.setTranslation(tagList.Get(0),after,False,"")
			End If
			'Main.currentProject.setSegment(tagList.Get(0),bitext)
			Main.currentProject.fillVisibleTargetTextArea
			resultListView.Items.RemoveAt(resultListView.Items.IndexOf(p))
			count=count+1
		Next
        fx.Msgbox(frm,count&" matches are replaced.","")
		Main.currentProject.contentIsChanged
	End If
	

End Sub

Sub resultListView_Action
	Dim p As Pane
	p=resultListView.Items.Get(resultListView.SelectedIndex)
	Dim taglist As List
	taglist=p.Tag
	Main.editorLV.ScrollTo(taglist.get(0))
	Main.MainForm.AlwaysOnTop=True
	Main.MainForm.AlwaysOnTop=False
End Sub

Sub searchSourceCheckBox_CheckedChange(Checked As Boolean)
	sourceTextField.Visible=Checked
	MatchBothCheckBox.Visible=Checked
End Sub

Sub sourceTextField_TextChanged (Old As String, New As String)
	
End Sub

Sub replaceTextField_TextChanged (Old As String, New As String)
	resultListView.Items.Clear
End Sub

Sub findTextField_TextChanged (Old As String, New As String)
	resultListView.Items.Clear
End Sub
