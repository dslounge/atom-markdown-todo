MarkdownAtomTodoView = require './markdown-atom-todo-view'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  markdownAtomTodoView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    console.log "Activate method gets called the first time the command is called, not on reload"

    @markdownAtomTodoView = new MarkdownAtomTodoView(state.markdownAtomTodoViewState)
    # Create a hidden modal panel.
    @modalPanel = atom.workspace.addModalPanel(item: @markdownAtomTodoView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:toggle': => @toggle()

    # registers a listener, only after this package has been activated though.
    # this should probably go in subscriptions so we can throw it way
    # when it gets shut down.
    atom.workspace.observeTextEditors (editor) ->
      editor.onDidSave ->
        console.log "Saved! #{editor.getPath()}"

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @markdownAtomTodoView.destroy()

  serialize: ->
    markdownAtomTodoViewState: @markdownAtomTodoView.serialize()

  toggle: ->
    console.log 'MarkdownAtomTodo was toggled!'

    #get the editor
    editor = atom.workspace.getActiveTextEditor()
    # get the number of words
    words = editor.getText().split(/\s+/).length
    console.log(words)

    @markdownAtomTodoView.setCount(words)    

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
