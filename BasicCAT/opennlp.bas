B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private lemmatizer As JavaObject
	Private tokenizer As JavaObject
	Private POSTagger As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(lang As String)
	Dim tokenizerIS As InputStream
	tokenizerIS=File.OpenInput(File.Combine(File.DirApp,"model"),"en-token.bin")
	Dim tokenizerModel As JavaObject
	tokenizerModel.InitializeNewInstance("opennlp.tools.tokenize.TokenizerModel",Array(tokenizerIS))
	tokenizer.InitializeNewInstance("opennlp.tools.tokenize.TokenizerME",Array(tokenizerModel))
	
	Dim postaggerIS As InputStream
	postaggerIS=File.OpenInput(File.Combine(File.DirApp,"model"),"en-pos-maxent.bin")
	Dim posmodel As JavaObject
	posmodel.InitializeNewInstance("opennlp.tools.postag.POSModel",Array(postaggerIS))
	POSTagger.InitializeNewInstance("opennlp.tools.postag.POSTaggerME",Array(posmodel))
	
	Dim dictIS As InputStream
	dictIS=File.OpenInput(File.Combine(File.DirApp,"model"),"en-lemmatizer.dict")
	lemmatizer.InitializeNewInstance("opennlp.tools.lemmatizer.DictionaryLemmatizer",Array(dictIS))
End Sub

Public Sub tokenize(sentence As String) As String()
	Return tokenizer.RunMethod("tokenize",Array(sentence))
End Sub

Public Sub posTag(tokens() As String) As String()
	Return POSTagger.RunMethod("tag",Array(tokens))
End Sub

Public Sub lemmatize(tags() As String,tokens() As String) As String()
	Return lemmatizer.RunMethod("lemmatize",Array(tokens,tags))
End Sub

Public Sub lemmatizedSentence(sentence As String) As String
	Dim tokens(),tags(),lemmas() As String
	tokens=tokenize(sentence)
	tags=posTag(tokens)
	lemmas=lemmatize(tags,tokens)
	Dim result As String
	For i=0 To lemmas.Length-1
		If lemmas(i)<>"O" Then
			result=result&" "&lemmas(i)
		Else
			result=result&" "&tokens(i)
		End If
	Next
	result=result.Trim
	Log(result)
	Return result
End Sub
