moment = require 'moment'
parser = require './todo-parser'
textConsts = require './todo-text-consts'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  subscriptions: null

  # Activate method gets called the first time the command is called.
  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    #register the command.
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:parse todo': => @parseTodoMarkdown()
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:destroy markers': => @destroyMarkers()

    # registers a listener, only after this package has been activated though.
    # this should probably go in subscriptions so we can throw it way
    # when it gets shut down.

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        title = editor.getTitle()
        #TODO: Make this work with .todo.md files
        if title.split('.').pop() == 'md'
          @parseTodoMarkdown()

  deactivate: ->
    @subscriptions.dispose()

  #TODO: I think I don't need this
  serialize: ->

  makeTodoTree: ->
    editor = atom.workspace.getActiveTextEditor()

    # Pass each editor line to the parser and get the resulting model
    parser.reset()
    for i in [0..editor.getLastBufferRow()]
      rowText = editor.lineTextForBufferRow(i)
      parser.parseLine(i, rowText)

    parser.todoModel

  # TODO: All this needs to get broken down into functions.
  # it's getting messy.
  # This should go in a renderer class
  decorateTree: (editor, tree) ->
    weekIndex = 0
    todayString = moment().format('dd')
    for week in tree
      marker = @createMarker(editor, week.textRange)
      editor.decorateMarker(marker, type: 'highlight', class: "my-line-class")

      for section in week.children
        console.log section.estimateTotalDuration
        console.log section.estimateDoneDuration

        marker = @createMarker(editor, section.textRange)
        # Create message element
        estElement = document.createElement('div')
        estElement.classList.add('section-estimate')

        totalHours = section.estimateTotalDuration.asHours()
        completedHours = section.estimateDoneDuration.asHours()

        estElement.textContent = "#{completedHours} / #{totalHours} hours completed."
        editor.decorateMarker(marker, type: 'overlay', item: estElement)

        for item in section.children
          if item.estimate?
            marker = @createMarker(editor, item.estimate.range)
            editor.decorateMarker(marker, type: 'highlight', class: "estimate-badge")

          if item.isDone
            marker = @createMarker(editor, item.doneBadgeRange)
            editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
            lineMarker = @createMarker(editor, item.lineRange)
            editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
          else if (weekIndex == 0) and (item.day == todayString)
            lineMarker = @createMarker(editor, item.lineRange)
            editor.decorateMarker(lineMarker, type: 'line', class: "item-today")
      weekIndex++

  # Renderer method
  destroyMarkers: ->
    console.log "--destroyMarkers--"
    editor = atom.workspace.getActiveTextEditor()
    markerList = editor.findMarkers(mdtodo: true)
    console.log markerList.length
    for marker in markerList
      console.log marker
      marker.destroy()

  # renderer method
  createMarker: (editor, range) ->
    marker = editor.markBufferRange(range, mdtodo: true)
    marker

  # entry function.
  parseTodoMarkdown: ->
    # console.log weekStart.format('MM DD YY')
    console.log "--parseMarkdown--"
    @destroyMarkers()
    editor = atom.workspace.getActiveTextEditor()
    todoTree = @makeTodoTree()
    @decorateTree(editor, todoTree)
