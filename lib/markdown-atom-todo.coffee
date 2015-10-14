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
    h3: /^###\s/
    item: /^\s*-\s/
    doneBadge: /DONE/
    day: /\s[MTWRSFU]\s/
  dateformat: 'MMM-Do-YYYY'

  dayKeys:
    M: 'Mo'
    T: 'Tu'
    W: 'We'
    R: 'Th'
    F: 'Fr'
    S: 'Sa'
    U: 'Su'

  activate: (state) ->

    # Activate method gets called the first time the command is called, not on reload

    @markdownAtomTodoView = new MarkdownAtomTodoView(state.markdownAtomTodoViewState)
    # Create a hidden modal panel.
    @modalPanel = atom.workspace.addModalPanel(item: @markdownAtomTodoView.getElement(), visible: false)

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

  inlineTextRange: (row, start, end) ->
    return [[row, start], [row, end]]

  createH2Item: (rowIndex, text) ->
    dateIndexStart = 3
    dateLength =　text.substring(3).length
    bufferRowIndex: rowIndex
    startDate: @dateFromHeader(text)
    textRange: @inlineTextRange(rowIndex, dateIndexStart, dateIndexStart + dateLength)
    children: []

  createH3Item: (rowIndex, text) ->
    bufferRowIndex: rowIndex
    title: text.substring(3)
    children: []

  #TODO: parse day, done tag, item
  createTodoItem: (rowIndex, text) ->
    doneIndex = text.search(@regex.doneBadge)
    day = text.match(@regex.day)?[0].trim()
    isDone: (doneIndex != -1)
    day: @dayKeys[day]
    doneBadgeRange: @inlineTextRange(rowIndex, doneIndex, doneIndex + 4)
    lineRange: @inlineTextRange(rowIndex, 0, text.length)
    bufferRowIndex: rowIndex


  # TODO: Eventually this should be more generalized.
  # The header types shouldn't be hardcoded.
  # But for right now it's so that it fits my todo system.
  makeTodoTree: ->
    editor = atom.workspace.getActiveTextEditor()
    todoTree = []
    currentH2 = currentH3 = null

    for i in [0..editor.getLastBufferRow()]
      rowText = editor.lineTextForBufferRow(i)
      if @regex.h2.test(rowText)
        currentH3 = null
        currentH2 = h2Item = @createH2Item(i, rowText)
        todoTree.push h2Item

      else if @regex.h3.test(rowText) and currentH2?
        #ignore H3 that aren't under H2
        currentH3 = h3Item = @createH3Item(i, rowText)
        currentH2.children.push h3Item

      else if @regex.item.test(rowText) and currentH3?
        #ignore items that aren't under H3
        item = @createTodoItem(i, rowText)
        currentH3.children.push item
      else if currentH2?
        console.log "ignored: #{i}: #{rowText}"
    todoTree

  decorateTree: (editor, tree) ->
    weekIndex = 0
    todayString = moment().format('dd')
    for week in tree
      marker = @createMarker(editor, week.textRange)
      editor.decorateMarker(marker, type: 'highlight', class: "my-line-class")

      for section in week.children
        for item in section.children
          if item.isDone
            marker = @createMarker(editor, item.doneBadgeRange)
            editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
            lineMarker = @createMarker(editor, item.lineRange)
            editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
          else if (weekIndex == 0) and (item.day == todayString)
            lineMarker = @createMarker(editor, item.lineRange)
            editor.decorateMarker(lineMarker, type: 'line', class: "item-today")
      weekIndex++

  destroyMarkers: () ->
    console.log "--destroyMarkers--"
    editor = atom.workspace.getActiveTextEditor()
    markerList = editor.findMarkers(mdtodo:true)
    console.log markerList.length
    for marker in markerList
      console.log marker
      marker.destroy()

  createMarker: (editor, range) ->
    marker = editor.markBufferRange(range, mdtodo: true)
    marker

  parseTodoMarkdown: ->
    # console.log weekStart.format('MM DD YY')
    console.log "--parseMarkdown--"
    @destroyMarkers()
    editor = atom.workspace.getActiveTextEditor()
    todoTree = @makeTodoTree()
    @decorateTree(editor, todoTree)
