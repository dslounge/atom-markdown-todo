moment = require 'moment'
parser = require './todo-parser'
decorator = require './todo-decorator'
textConsts = require './todo-text-consts'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  subscriptions: null
  todoMode: false
  highlightedDay: null

  # Activate method gets called the first time the command is called.
  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    #register the command.
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Sunday": => @highlightDay('U')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Monday": => @highlightDay('M')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Tuesday": => @highlightDay('T')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Wednesday": => @highlightDay('W')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Thursday": => @highlightDay('R')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Friday": => @highlightDay('F')
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:highlight Saturday": => @highlightDay('S')

    # add ability to remove highlight
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:clear highlight": => @highlightDay(null)

    # registers a listener, only after this package has been activated though.
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        extension = editor.getTitle().split('.').pop()
        #TODO: Make this work with .todo.md files
        if @todoMode and (extension == 'md')
          @showTodo()

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

  highlightDay: (dayKey) ->
    console.log "highlight #{dayKey}"
    @highlightedDay = dayKey
    @showTodo()

  showTodo: ->
    editor = atom.workspace.getActiveTextEditor()
    decorator.destroyMarkers(editor)

    # Pass each editor line to the parser and get the resulting model
    parser.reset()
    for i in [0..editor.getLastBufferRow()]
      rowText = editor.lineTextForBufferRow(i)
      parser.parseLine(i, rowText)

    decorator.decorateTodo(editor, parser.todoModel, @highlightedDay)

  hideTodo: ->
    editor = atom.workspace.getActiveTextEditor()
    decorator.destroyMarkers(editor)
