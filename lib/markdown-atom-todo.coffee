moment = require 'moment'
$ = require 'jquery'
MarkdownAtomTodoView = require './markdown-atom-todo-view'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  markdownAtomTodoView: null
  modalPanel: null
  subscriptions: null
  regex:
    h2: /^##\s/
  dateformat: 'MMM-Do-YYYY'

  activate: (state) ->

    # Activate method gets called the first time the command is called, not on reload

    @markdownAtomTodoView = new MarkdownAtomTodoView(state.markdownAtomTodoViewState)
    # Create a hidden modal panel.
    @modalPanel = atom.workspace.addModalPanel(item: @markdownAtomTodoView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    #register the command.
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:parse todo': => @parseTodoMarkdown()

    # registers a listener, only after this package has been activated though.
    # this should probably go in subscriptions so we can throw it way
    # when it gets shut down.

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        title = editor.getTitle()
        if title.split('.').pop() == 'md'
          @parseTodoMarkdown()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @markdownAtomTodoView.destroy()

  serialize: ->
    markdownAtomTodoViewState: @markdownAtomTodoView.serialize()

  parseDate: (dateString) ->
    moment(dateString, @dateformat)

  getActiveEditorView: ->
    textEditor = atom.workspace.getActiveTextEditor()
    atom.views.getView(textEditor)

  dateFromHeader: (header) ->
    datePart = header.substring(3)
    @parseDate(datePart)

  getH2Headers: ->
    editor = atom.workspace.getActiveTextEditor()
    weekHeaders = []
    for i in [0..editor.getLastBufferRow()]
      rowText = editor.lineTextForBufferRow(i)
      if @regex.h2.test(rowText)
        headerItem =
          bufferLine: i
          screenLine: editor.screenPositionForBufferPosition(i)
          startDate: @dateFromHeader(rowText)
          textRange: [[3,i], [6, i]]
        weekHeaders.push headerItem
    weekHeaders


  parseTodoMarkdown: ->
    console.log "--parseMarkdown-- lines"
    editor = atom.workspace.getActiveTextEditor()
    weekHeaders = @getH2Headers()
    console.log weekHeaders
    # console.log weekStart.format('MM DD YY')

    firstWeek = weekHeaders[0]
    console.log firstWeek
    marker = editor.markBufferRange(firstWeek.textRange)

    editor.decorateMarker(marker, type: 'highlight', class: "my-line-class")    

    testRange = editor.getSelectedBufferRange()
    testMark = editor.markBufferRange(testRange)
    editor.decorateMarker(testMark, type: 'highlight', class: "my-line-class")

    console.log testRange



    # Maybe I don't need the view at all if I use markers
    #editorView = @getActiveEditorView()
    #shadowRoot = editorView.shadowRoot
    #viewLine = $(shadowRoot).find("[data-screen-row='15']")
