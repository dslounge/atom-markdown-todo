MarkdownAtomTodoView = require './markdown-atom-todo-view'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  markdownAtomTodoView: null
  modalPanel: null
  subscriptions: null

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

  parseTodoMarkdown: ->
    editor = atom.workspace.getActiveTextEditor()
    lines = editor.getLineCount()
    console.log "--parseMarkdown-- lines: #{ lines }"

    h2Regex = /^##\s/

    for i in [0..lines]
      testText = editor.lineTextForBufferRow(i)
      if h2Regex.test(testText)
        console.log "#{i}: #{testText}"
