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

  # Creates an html string with a percentage bar
  makeProgressBlock: (text, percentage) ->
    template = """
      <div class="progress-block">
        #{text}
        <progress class='estimate-progress' max='1' value='#{percentage}' />
      </div>
    """

  makeDaysProgress: (perDayBreakdown) ->
    template = ""
    for day in perDayBreakdown
      innerText = """
      <span class="daySummary">
        <span class="day">#{day.day}</span><span class="hours">#{day.durationString}</span>
      <span>
      """
      template = template.concat(@makeProgressBlock(innerText, day.percentage))
    template


  createWeekOverlayElement: (hourSummary, perDayBreakdown, percentage) ->
    testBlock = @makeProgressBlock("hello", .7)
    template = """
    <div class="same-line-overlay">
      <div class="section-estimate">
        #{hourSummary}
        <progress class='estimate-progress' max='1' value='#{percentage}' />
      </div>
      <div class="hours-summary">
        #{@makeDaysProgress(perDayBreakdown)}
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
    perDayBreakdown = []
    perDay = week.getEstimatesPerDay()
    perDayDone = week.getDoneDurationsPerDay()
    for day in textConsts.days
      breakdown =
        day: day
        durationString: @getDurationString(perDay[day])
        percentage: perDayDone[day].asSeconds() / perDay[day].asSeconds()
      perDayBreakdown.push(breakdown)

    # build the overlay and decorate.
    overlayElement = @createWeekOverlayElement(hourSummary, perDayBreakdown, percentage)
    editor.decorateMarker(marker, type: 'overlay', item: overlayElement)

  decorateSection: (editor, section) ->
    marker = @createMarker(editor, section.textRange)

    totalHours = @getDurationString(section.estimateTotalDuration)
    completedHours = @getDurationString(section.estimateDoneDuration)
    content = "#{completedHours} / #{totalHours}"

    percentage = section.estimateDoneDuration.asSeconds() / section.estimateTotalDuration.asSeconds()
    overlay = @createSectionOverlayElement(content, percentage)
    editor.decorateMarker(marker, type: 'overlay', item: overlay)

  decorateItem: (editor, item, isFirstWeek, todayString, highlightedDay) ->
    #-- Decorate item
    if item.estimate?
      marker = @createMarker(editor, item.estimate.range)
      editor.decorateMarker(marker, type: 'highlight', class: "badge-estimate")

    if item.points?
      marker = @createMarker(editor, item.points.range)
      editor.decorateMarker(marker, type: 'highlight', class: "badge-points")

    if item.calories?
      marker = @createMarker(editor, item.calories.range)
      editor.decorateMarker(marker, type: 'highlight', class: "badge-calories")

    if item.isDone
      marker = @createMarker(editor, item.doneBadgeRange)
      editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
    else if isFirstWeek and (item.dayString == highlightedDay)
      # TODO: Don't like this if statement. Highlighted days should have their own class.
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")
    else if isFirstWeek and (item.day == todayString) and !highlightedDay?
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")


  decorateTodo: (editor, tree, highlightedDay) ->
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
