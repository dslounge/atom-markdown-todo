moment = require 'moment'
$ = require 'jquery'
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

  #TODO There might be a bug here since .hours() returns max 23
  getDurationString: (momentDuration) ->
    hours = Math.round(momentDuration.asHours() * 100) / 100
    "#{hours}h"

  createWeekOverlayElement: (hourSummary, daySummaryString, percentage) ->
    template = """
    <div class="same-line-overlay">
      <div class="section-estimate">
        #{hourSummary}
        <progress class='estimate-progress' max='1' value='#{percentage}' />
      </div>
      <div class="hours-summary">
        #{daySummaryString}
      </div>

    </div>
    """
    $('<div/>').html(template).contents()[0]

  createSectionOverlayElement: (text, percentage) ->
    template = """
    <div class="same-line-overlay">
      <div class="section-estimate">
        #{text}
        <progress class='estimate-progress' max='1' value='#{percentage}' />
      </div>
    """
    $('<div/>').html(template).contents()[0]

  decorateWeek: (editor, week) ->
    marker = @createMarker(editor, week.textRange)
    #TODO: find a better class name.
    editor.decorateMarker(marker, type: 'highlight', class: "my-line-class")

    # Make hours summary
    completedHours = @getDurationString(week.getDoneDuration())
    totalHours = @getDurationString(week.getTotalDuration())
    hourSummary = "#{completedHours} / #{totalHours}"

    percentage = week.getDoneDuration().asSeconds() / week.getTotalDuration().asSeconds()

    # Make per day summary
    daySummaries = []
    perDay = week.getEstimatesPerDay()
    for day in textConsts.days
      durationString = @getDurationString(perDay[day])
      daySummaries.push "#{day}:#{durationString}"
    daySummaryString = daySummaries.join(", ")

    # build the overlay and decorate.
    overlayElement = @createWeekOverlayElement(hourSummary, daySummaryString, percentage)
    editor.decorateMarker(marker, type: 'overlay', item: overlayElement)

  decorateSection: (editor, section) ->
    marker = @createMarker(editor, section.textRange)

    totalHours = @getDurationString(section.estimateTotalDuration)
    completedHours = @getDurationString(section.estimateDoneDuration)
    content = "#{completedHours} / #{totalHours}"

    percentage = section.estimateDoneDuration.asSeconds() / section.estimateTotalDuration.asSeconds()
    console.log("PERCENTAGE: #{percentage}")
    console.log(section.estimateTotalDuration)
    console.log(section.estimateDoneDuration)
    overlay = @createSectionOverlayElement(content, percentage)
    editor.decorateMarker(marker, type: 'overlay', item: overlay)

  decorateItem: (editor, item, isFirstWeek, todayString, highlightedDay) ->
    console.log("--decorateItem--: #{highlightedDay}")
    #-- Decorate item
    if item.estimate?
      marker = @createMarker(editor, item.estimate.range)
      editor.decorateMarker(marker, type: 'highlight', class: "estimate-badge")

    if item.isDone
      marker = @createMarker(editor, item.doneBadgeRange)
      editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
    else if isFirstWeek and (item.dayString == highlightedDay)
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")
    else if isFirstWeek and (item.day == todayString) and !highlightedDay?
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")


  decorateTodo: (editor, tree, highlightedDay) ->
    console.log("decorateTodo: #{highlightedDay}")
    @highlightedDay = highlightedDay
    todayString = moment().format('dd')
    isFirstWeek = false
    for week, weekIndex in tree
      isFirstWeek = (weekIndex == 0)
      @decorateWeek(editor, week)
      for section in week.children
        @decorateSection(editor, section)
        for item in section.children
          @decorateItem(editor, item, isFirstWeek, todayString, highlightedDay)
