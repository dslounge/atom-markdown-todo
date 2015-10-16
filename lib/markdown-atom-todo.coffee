moment = require 'moment'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  subscriptions: null

  # text utils
  regex:
    h2: /^##\s/
    h3: /^###\s/
    item: /^\s*-\s/
    doneBadge: /DONE/
    day: /\s[MTWRSFU]\s/
    duration: /\d+[mhd]/g

  # text utils
  dateformat: 'MMM-Do-YYYY'

  # text utils
  dayKeys:
    M: 'Mo'
    T: 'Tu'
    W: 'We'
    R: 'Th'
    F: 'Fr'
    S: 'Sa'
    U: 'Su'

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

  #text utils
  parseDate: (dateString) ->
    moment(dateString, @dateformat)

  #text utils
  dateFromHeader: (header) ->
    datePart = header.substring(3)
    @parseDate(datePart)

  #model function
  inlineTextRange: (row, start, end) ->
    return [[row, start], [row, end]]

  #model function
  createH2Item: (rowIndex, text) ->
    dateIndexStart = 3
    dateLength =　text.substring(3).length
    bufferRowIndex: rowIndex
    startDate: @dateFromHeader(text)
    textRange: @inlineTextRange(rowIndex, dateIndexStart, dateIndexStart + dateLength)
    children: []

  #model function
  createH3Item: (rowIndex, text) ->
    title = text.substring(4)
    bufferRowIndex: rowIndex
    title: title
    textRange: @inlineTextRange(rowIndex, 4, 4 + title.length)
    children: []
    estimateTotalDuration: moment.duration()
    estimateDoneDuration: moment.duration()
    addTodoItem: (item) ->
      @children.push item
      if item.estimate?
        @estimateTotalDuration.add(item.estimate.duration)
        if item.isDone
          @estimateDoneDuration.add(item.estimate.duration)

  #model function
  createDurationItem: (rowIndex, regResult) ->
    if regResult?
      text = regResult[0]
      number = parseInt(text.slice(0, -1))
      unit = text.slice(-1)

      duration =
        text: text
        range: @inlineTextRange(rowIndex, regResult.index, regResult.index + text.length)
        duration: moment.duration(number, unit)
    else
      null

  #TODO: estimates
  # model function
  createTodoItem: (rowIndex, text) ->
    doneIndex = text.search(@regex.doneBadge)
    day = text.match(@regex.day)?[0].trim()

    # because I'm using the /g flag exec isn't idempotent
    # reset the lastIndex property from previous run
    @regex.duration.lastIndex = 0
    # get the first duration (estimate)
    estimate = @createDurationItem(rowIndex, @regex.duration.exec(text))
    #get the second duration (actual)
    actual = @createDurationItem(rowIndex, @regex.duration.exec(text))

    isDone: (doneIndex != -1)
    day: @dayKeys[day]
    doneBadgeRange: @inlineTextRange(rowIndex, doneIndex, doneIndex + 4)
    lineRange: @inlineTextRange(rowIndex, 0, text.length)
    bufferRowIndex: rowIndex
    estimate: estimate
    actual: actual


  # TODO: Eventually this should be more generalized.
  # The header types shouldn't be hardcoded.
  # But for right now it's so that it fits my todo system.
  makeTodoTree: ->
    editor = atom.workspace.getActiveTextEditor()
    todoTree = []
    currentH2 = currentH3 = null

    # model parsing function
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
        currentH3.addTodoItem(item)

    todoTree

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
  destroyMarkers: () ->
    console.log "--destroyMarkers--"
    editor = atom.workspace.getActiveTextEditor()
    markerList = editor.findMarkers(mdtodo:true)
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
