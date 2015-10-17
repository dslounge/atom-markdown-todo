moment = require 'moment'
parser = require './todo-parser'
decorator = require './todo-decorator'
textConsts = require './todo-text-consts'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  subscriptions: null
  todoMode: false

  # Activate method gets called the first time the command is called.
  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    #register the command.
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:toggle': => @toggle()

    # registers a listener, only after this package has been activated though.
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        extension = editor.getTitle().split('.').pop()
        #TODO: Make this work with .todo.md files
        if @todoMode and (extension == 'md')
          @parseTodoMarkdown()

  deactivate: ->
    @subscriptions.dispose()

  #TODO: I think I don't need this
  serialize: ->

  #TODO: Eventually this should be tracked for each editor.
  toggle: ->
    console.log "toggle #{@todoMode}"
    @todoMode = !@todoMode
    if @todoMode
      @showTodo()
    else
      @hideTodo()

  showTodo: ->
    editor = atom.workspace.getActiveTextEditor()
    decorator.destroyMarkers(editor)

    # Pass each editor line to the parser and get the resulting model
    parser.reset()
    for i in [0..editor.getLastBufferRow()]
      rowText = editor.lineTextForBufferRow(i)
      parser.parseLine(i, rowText)

    decorator.decorateTodo(editor, parser.todoModel)

  hideTodo: ->
    editor = atom.workspace.getActiveTextEditor()
    decorator.destroyMarkers(editor)
