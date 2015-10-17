moment = require 'moment'
module.exports = todoDecorator =

  createMarker: (editor, range) ->
    editor.markBufferRange(range, mdtodo: true)

  destroyMarkers: ->
    editor = atom.workspace.getActiveTextEditor()
    markerList = editor.findMarkers(mdtodo: true)
    for marker in markerList
      marker.destroy()

  decorateWeek: (editor, week) ->
    marker = @createMarker(editor, week.textRange)
    editor.decorateMarker(marker, type: 'highlight', class: "my-line-class")

  decorateSection: (editor, section) ->
    marker = @createMarker(editor, section.textRange)
    # Create message element
    estElement = document.createElement('div')
    estElement.classList.add('section-estimate')

    totalHours = section.estimateTotalDuration.asHours()
    completedHours = section.estimateDoneDuration.asHours()

    estElement.textContent = "#{completedHours} / #{totalHours} hours completed."
    editor.decorateMarker(marker, type: 'overlay', item: estElement)

  decorateItem: (editor, item, isFirstWeek, todayString) ->
    #-- Decorate item
    if item.estimate?
      marker = @createMarker(editor, item.estimate.range)
      editor.decorateMarker(marker, type: 'highlight', class: "estimate-badge")

    if item.isDone
      marker = @createMarker(editor, item.doneBadgeRange)
      editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
    else if isFirstWeek and (item.day == todayString)
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")


  decorateTodo: (editor, tree) ->
    todayString = moment().format('dd')
    isFirstWeek = false
    for week, weekIndex in tree
      isFirstWeek = (weekIndex == 0)
      @decorateWeek(editor, week)
      for section in week.children
        @decorateSection(editor, section)
        for item in section.children
          @decorateItem(editor, item, isFirstWeek, todayString)
