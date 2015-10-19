moment = require 'moment'
textConsts = require './todo-text-consts'
## TODO: This is really messy and needs cleanup and testing.
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

    #TODO: Is there a less dumb way to do this without jquery?
    overlayElement = document.createElement('div')
    overlayElement.classList.add('same-line-overlay')

    completedElement = document.createElement('div')
    completedElement.classList.add('section-estimate')

    daysElement = document.createElement('div')
    daysElement.classList.add('hours-summary')

    overlayElement.appendChild(completedElement)
    overlayElement.appendChild(daysElement)

    # Make hours summary
    completedHours = week.getDoneDuration().asHours()
    totalHours = week.getTotalDuration().asHours()
    hourSummary = "#{completedHours}h / #{totalHours}h"

    # Make per day summary
    daySummaries = []
    perDay = week.getEstimatesPerDay()
    for day in textConsts.days
      hours = perDay[day].asHours()
      daySummaries.push "#{day}:#{hours}h"
    daySummaryString = daySummaries.join(", ")

    completedElement.textContent = hourSummary
    daysElement.textContent = daySummaryString
    editor.decorateMarker(marker, type: 'overlay', item: overlayElement)

  decorateSection: (editor, section) ->
    marker = @createMarker(editor, section.textRange)
    # Create message element
    overlay = document.createElement('div')
    overlay.classList.add('same-line-overlay')

    estElement = document.createElement('div')
    estElement.classList.add('section-estimate')
    overlay.appendChild(estElement)

    totalHours = section.estimateTotalDuration.asHours()
    completedHours = section.estimateDoneDuration.asHours()

    estElement.textContent = "#{completedHours} / #{totalHours} hours completed."
    editor.decorateMarker(marker, type: 'overlay', item: overlay)

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
