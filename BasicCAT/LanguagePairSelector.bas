B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private result As Map
	Private sourceComboBox As ComboBox
	Private targetComboBox As ComboBox
	Private langcodes As Map
	Private LanguageNames As Map
	Private sourceSearchView As LangCodeSearchView
	Private targetSearchView As LangCodeSearchView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",500,300)
	frm.RootPane.LoadLayout("LangaugePairSelector")
	result.Initialize
	LanguageNames.Initialize
	langcodes=Utils.readLanguageCode(File.Combine(File.DirData("BasicCAT"),"langcodes.txt"))
	fillLanguages
End Sub

Sub fillLanguages
	Dim languages As List
	languages.Initialize
	For Each key As String In langcodes.Keys
		Dim codesMap As Map
		codesMap=langcodes.Get(key)
		LanguageNames.Put(codesMap.Get("language name"),key)
		languages.Add(codesMap.Get("language name"))
		sourceComboBox.Items.Add(codesMap.Get("language name"))
		targetComboBox.Items.Add(codesMap.Get("language name"))
	Next
	sourceSearchView.SetItems(languages)
	targetSearchView.SetItems(languages)
	sourceSearchView.LangCodesMap=LanguageNames
	targetSearchView.LangCodesMap=LanguageNames
End Sub

Public Sub ShowAndWait(sourceLang As String,targetLang As String) As Map
	CallSubDelayed3(Me,"fillLang",sourceLang,targetLang)
	frm.ShowAndWait
	Return result
End Sub

Public Sub fillLang(sourceLang As String,targetLang As String)
	Log(sourceLang)
	Log(targetLang)
	sourceSearchView.Text=sourceLang
	targetSearchView.Text=targetLang
End Sub

Sub close
	frm.Close
End Sub

Sub targetComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	If Index<>-1 Then
		targetSearchView.Text=""
		targetSearchView.Text=LanguageNames.Get(Value)
	End If
End Sub

Sub sourceComboBox_SelectedIndexChanged(Index As Int, Value As Object)
	If Index<>-1 Then
		sourceSearchView.Text=""
		sourceSearchView.Text=LanguageNames.Get(Value)
	End If
End Sub

Sub OkButton_MouseClicked (EventData As MouseEvent)
	If sourceSearchView.Text="" Or targetSearchView.Text="" Then
		fx.Msgbox(frm,"Please choose language pair.","")
		Return
	End If
	result.put("source",sourceSearchView.Text)
	result.put("target",targetSearchView.Text)
	close
End Sub

Sub targetSearchView_ItemClick (Value As String,Name As String)
	targetComboBox.SelectedIndex=targetComboBox.Items.IndexOf(Name)
End Sub

Sub sourceSearchView_ItemClick (Value As String,Name As String)
	sourceComboBox.SelectedIndex=sourceComboBox.Items.IndexOf(Name)
End Sub
