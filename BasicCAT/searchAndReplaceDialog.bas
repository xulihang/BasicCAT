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
	Private mFiles As List
	Private ExtendedSearchTextField As TextField
	Private GetTimestampButton As Button
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(files As List)
	frm.Initialize("frm",800,300)
	frm.RootPane.LoadLayout("searchandreplace")
	ComboBox1.Items.Add("id")
	ComboBox1.Items.Add("note")
	ComboBox1.Items.Add("filename")
	ComboBox1.Items.Add("creator")
	ComboBox1.Items.Add("createdTime")
	ComboBox1.SelectedIndex=0
	mFiles=files
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
		Dim key As String=ComboBox1.Items.Get(ComboBox1.SelectedIndex)
		If key="filename" Then
			Dim innerFilename As String=segment.Get(3)
			result=HasMatch(regexMode,find,innerFilename)
		Else if key="createdTime" Then
			Dim extra As Map=segment.Get(4)
			If extra.ContainsKey("createdTime") Then
				Try
					Dim upper,lower As Long
					lower=Regex.Split(",",find)(0)
					upper=Regex.Split(",",find)(1)
					result=InTimeRange(extra.Get("createdTime"),lower,upper)
				Catch
					Log(LastException)
				End Try
			End If
		Else
			Dim value As String=extra.GetDefault(key,"")
			result=HasMatch(regexMode,find,value)
		End If
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

Sub InTimeRange(createdTime As Long,time_lower As Long,time_upper As Long) As Boolean
	If createdTime>=time_lower And createdTime<=time_upper Then
		Return True
	Else
		Return False
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
		For Each filename As String In mFiles
			Dim segments As List
			segments.Initialize
			Main.currentProject.readWorkFile(filename,segments,False,Main.currentProject.path)
			Dim index As Int=-1
			For Each bitext As List In segments
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

				shouldShow=CheckShouldShowBasedonExtendedItem(ExtendedSearchTextField.Text,True,bitext,shouldShow)
			
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
					tf.AddText(CRLF&"- Info: "&filename&" "&index)
					
					Dim tagMap As Map
					tagMap.Initialize
					tagMap.Put("index",index)
					tagMap.Put("filename",filename)
					tagMap.Put("text",tf.getText)
					Dim pane As Pane = tf.CreateTextFlow
					pane.Tag=tagMap
					pane.SetSize(resultListView.Width,Utils.MeasureMultilineTextHeight(fx.DefaultFont(15),resultListView.Width,tagMap.Get("text")))
					resultListView.Items.Add(pane)
				End If
			Next
		Next
		
	Catch
		Log(LastException)
		fx.Msgbox(frm,"Invalid expression","")
		Return
	End Try
End Sub

Sub showResult
	For Each filename As String In mFiles
		Dim index As Int=-1
		Dim segments As List
		segments.Initialize
		Main.currentProject.readWorkFile(filename,segments,False,Main.currentProject.path)
		For Each bitext As List In segments
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
		
			shouldShow=CheckShouldShowBasedonExtendedItem(ExtendedSearchTextField.Text,False,bitext,shouldShow)
		
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
                tf.AddText(CRLF&"- Info: "&filename&" "&index)
				Dim tagMap As Map
				tagMap.Initialize
				tagMap.Put("index",index)
				tagMap.Put("filename",filename)
				tagMap.Put("text",tf.getText)
				Dim pane As Pane = tf.CreateTextFlow
				pane.Tag=tagMap
				pane.SetSize(resultListView.Width,Utils.MeasureMultilineTextHeight(fx.DefaultFont(15),resultListView.Width,tagMap.Get("text")))
				resultListView.Items.Add(pane)
			End If
		Next
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
		Dim tagMap As Map
		tagMap=p.Tag
		p.SetSize(Width,Utils.MeasureMultilineTextHeight(fx.DefaultFont(15),Width,tagMap.Get("text")))
	Next
End Sub

Sub replaceSelectedButton_MouseClicked (EventData As MouseEvent)
	If resultListView.SelectedItem<>Null Then
		Dim p As Pane
		p=resultListView.SelectedItem
		Dim tagMap As Map
		tagMap=p.Tag
		Dim target,after As String
		Log(Regex.Split(CRLF&"- ",tagMap.Get("text")))
		target=Regex.Split(CRLF&"- ",tagMap.Get("text"))(1)
		target=target.SubString2("Target: ".Length,target.Length)
		after=Regex.Split(CRLF&"- ",tagMap.Get("text"))(2)
		after=after.SubString2("After: ".Length,after.Length)
		
		Dim filename As String=tagMap.Get("filename")
		If Main.currentProject.currentFilename=filename Then
			Dim bitext As List
			bitext=Main.currentProject.segments.Get(tagMap.Get("index"))
			If bitext.Get(1)=target Then
				'bitext.Set(1,after)
				Main.currentProject.setTranslation(tagMap.Get("index"),after,False,"")
			End If
			Main.currentProject.fillVisibleTargetTextArea
			Main.currentProject.contentIsChanged
		Else
			Dim fileSegments As List
			fileSegments.Initialize
			Main.currentProject.readWorkFile(filename,fileSegments,False,Main.currentProject.path)
			Dim bitext As List
			bitext=fileSegments.Get(tagMap.Get("index"))
			If bitext.Get(1)=target Then
				bitext.Set(1,after)
			End If
			Main.currentProject.saveWorkFile(filename,fileSegments,Main.currentProject.path)
		End If
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
			Dim tagMap As Map
			tagMap=p.Tag
			Dim target,after As String
			Log(Regex.Split(CRLF&"- ",tagMap.Get("text")))
			target=Regex.Split(CRLF&"- ",tagMap.Get("text"))(1)
			target=target.SubString2("Target: ".Length,target.Length)
			after=Regex.Split(CRLF&"- ",tagMap.Get("text"))(2)
			after=after.SubString2("After: ".Length,after.Length)
			Dim filename As String=tagMap.Get("filename")
			If Main.currentProject.currentFilename=filename Then
				Dim bitext As List
				bitext=Main.currentProject.segments.Get(tagMap.Get("index"))
				If bitext.Get(1)=target Then
					'bitext.Set(1,after)
					Main.currentProject.setTranslation(tagMap.Get("index"),after,False,"")
				End If
				Main.currentProject.fillVisibleTargetTextArea
			Else
				Dim fileSegments As List
				fileSegments.Initialize
				Main.currentProject.readWorkFile(filename,fileSegments,False,Main.currentProject.path)
				Dim bitext As List
				bitext=fileSegments.Get(tagMap.Get("index"))
				If bitext.Get(1)=target Then
					bitext.Set(1,after)
				End If
				Main.currentProject.saveWorkFile(filename,fileSegments,Main.currentProject.path)
			End If
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
	Dim tagMap As Map
	tagMap=p.Tag
	Dim filename As String=tagMap.Get("filename")
	If filename<>Main.currentProject.currentFilename Then
		Main.currentProject.openFile(filename,False)
	End If
	Main.editorLV.ScrollTo(tagMap.get("index"))
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

Sub RestoreButton_MouseClicked (EventData As MouseEvent)
	Main.currentProject.showAllSegments
End Sub

Sub FilterButton_MouseClicked (EventData As MouseEvent)
	If mFiles.Size<>1 Then
		fx.Msgbox(frm,"Not in this mode","")
		Return
	End If
	If resultListView.Items.Size=0 Then
		Return
	End If
	Dim indexList As List
	indexList.Initialize
	For Each p As Pane In resultListView.Items
		Dim tagMap As Map
		tagMap=p.Tag
		indexList.Add(tagMap.get("index"))
	Next
	Main.currentProject.filterSegments(indexList)
End Sub

Sub ExtendedSearchTextField_TextChanged (Old As String, New As String)
	
End Sub


Sub GetTimestampButton_MouseClicked (EventData As MouseEvent)
	Dim ts As TimestampCalculator
	ts.Initialize
	ts.Show
End Sub

Sub ComboBox1_ValueChanged (Value As Object)
	If Value="createdTime" Then
		GetTimestampButton.Visible=True
		ExtendedSearchTextField.text="start timestamp,end timestamp"
		ExtendedSearchTextField.PromptText="start timestamp,end timestamp"
	Else
		GetTimestampButton.Visible=False
		ExtendedSearchTextField.PromptText=""
	End If
End Sub
