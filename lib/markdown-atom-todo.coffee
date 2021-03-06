moment = require 'moment'
parser = require './todo-parser'
decorator = require './todo-decorator'
textConsts = require './todo-text-consts'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  subscriptions: null
  todoMode: false
  highlightedDay: null
  selectedUnit: 'time'

  # Activate method gets called the first time the command is called.
  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    #register the command.
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:cycle day": => @cycleDayHighlight()
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:cycle units": => @cycleUnitDisplay()

    # add ability to remove highlight
    @subscriptions.add atom.commands.add 'atom-workspace', "markdown-atom-todo:clear highlight": => @highlightDay(null)

    # registers a listener, only after this package has been activated though.
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        if @todoMode
          @showTodo()

  isTodoDoc: ->
    editor = atom.workspace.getActiveTextEditor()
    title = editor.getTitle()
    suffix = 'todo.md'
    return (title.indexOf(suffix, title.length - suffix.length) != -1)

  deactivate: ->
    @subscriptions.dispose()

  #TODO: I think I don't need this
  serialize: ->

  #TODO: Eventually this should be tracked for each editor.
  toggle: ->
    @todoMode = !@todoMode
    if @todoMode
      @showTodo()
    else
      @hideTodo()

  highlightDay: (dayKey) ->
    @highlightedDay = dayKey
    @showTodo()

  displayUnit: (selectedUnit) ->
    @selectedUnit = selectedUnit
    @showTodo()

  cycleDayHighlight: ->
    if @todoMode?
      options = [null, 'U', 'M', 'T', 'W', 'R', 'F', 'S']
      index = options.indexOf(@highlightedDay)
      nextIndex = (index + 1) % options.length
      @highlightDay(options[nextIndex])

  cycleUnitDisplay: ->
    if @todoMode?
      options = [null, 'time', 'pt', 'cal']
      index = options.indexOf(@selectedUnit)
      nextIndex = (index + 1) % options.length
      @displayUnit(options[nextIndex])

  showTodo: ->
    if @isTodoDoc()
      editor = atom.workspace.getActiveTextEditor()
      decorator.destroyMarkers(editor)

      # Pass each editor line to the parser and get the resulting model
      parser.reset()
      for i in [0..editor.getLastBufferRow()]
        rowText = editor.lineTextForBufferRow(i)
        parser.parseLine(i, rowText)

      decorator.decorateTodo(editor, parser.todoModel, @highlightedDay, @selectedUnit)

  hideTodo: ->
    editor = atom.workspace.getActiveTextEditor()
    decorator.destroyMarkers(editor)
