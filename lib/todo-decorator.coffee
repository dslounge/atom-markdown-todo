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
        <span class="day">#{day.day}</span><span class="hours">#{day.amountString}</span>
      <span>
      """
      template = template.concat(@makeProgressBlock(innerText, day.percentage))
    template


  createWeekOverlayElement: (hourSummary, perDayBreakdown, percentage) ->
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

  decorateWeek: (editor, week, selectedUnit) ->
    console.log("--decorateWeek--: " + selectedUnit)
    if selectedUnit == 'time'
      overlayElement = @createWeekHoursOverlay(week)
    else
      overlayElement = @createWeekUnitOverlay(week, selectedUnit)

    if overlayElement?
      marker = @createMarker(editor, week.textRange)
      editor.decorateMarker(marker, type: 'overlay', item: overlayElement)

  createWeekHoursOverlay: (week) ->
    # aggregate summary
    completedHours = @getDurationString(week.getDoneDuration())
    totalHours = @getDurationString(week.getTotalDuration())
    hourSummary = "#{completedHours} / #{totalHours}"
    percentage = week.getDoneDuration().asSeconds() / week.getTotalDuration().asSeconds()

    # Daily summary
    perDayBreakdown = []
    perDay = week.getEstimatesPerDay()
    perDayDone = week.getDoneDurationsPerDay()
    for day in textConsts.days
      breakdown =
        day: day
        amountString: @getDurationString(perDay[day])
        percentage: perDayDone[day].asSeconds() / perDay[day].asSeconds()
      perDayBreakdown.push(breakdown)

    # build the overlay
    overlayElement = @createWeekOverlayElement(hourSummary, perDayBreakdown, percentage)

  createWeekUnitOverlay: (week, unit) ->
    total = week.getTotalAmount(unit)
    completed = week.getCompletedAmount(unit)
    if !(total == 0 && completed == 0)
      weekSummary = "#{completed}#{unit} / #{total}#{unit}"
      percentage = total / completed
      # build daily summary
      totalPerDay = week.getTotalAmountPerDay(unit)
      completedPerDay = week.getCompletedAmountPerDay(unit)
      perDayBreakdown = @createUnitDailyBreakdown(totalPerDay, completedPerDay, unit)

      overlayElement = @createWeekOverlayElement(weekSummary, perDayBreakdown, percentage)

  createUnitDailyBreakdown: (totalPerDay, completedPerDay, unit) ->
    perDayBreakdown = []
    for day, index in textConsts.days
      breakdown =
        day: day
        amountString: "#{completedPerDay[index]}#{unit}"
        percentage: completedPerDay[index] / totalPerDay[index]
      perDayBreakdown.push(breakdown)
    perDayBreakdown

  decorateSection: (editor, section, selectedUnit) ->
    if selectedUnit == 'time'
      overlay = @createSectionHoursOverlay(section)
    else
      overlay = @createSectionUnitsOverlay(section, selectedUnit)

    if overlay?
      marker = @createMarker(editor, section.textRange)
      editor.decorateMarker(marker, type: 'overlay', item: overlay)

  createSectionHoursOverlay: (section) ->
    totalHours = @getDurationString(section.estimateTotalDuration)
    completedHours = @getDurationString(section.estimateDoneDuration)
    content = "#{completedHours} / #{totalHours}"
    percentage = section.estimateDoneDuration.asSeconds() / section.estimateTotalDuration.asSeconds()
    overlay = @createSectionOverlayElement(content, percentage)

  createSectionUnitsOverlay: (section, unit) ->
    total = section.getTotalAmount(unit)
    completed = section.getCompletedAmount(unit)
    if !(total == 0 && completed == 0)
      content = "#{completed}#{unit} / #{total}#{unit}"
      percentage = total / completed
      overlay = @createSectionOverlayElement(content, percentage)

  decorateItem: (editor, item, isFirstWeek, todayString, highlightedDay) ->

    # TODO: This can be cleaner.
    isLate = (todayString != null) && !item.isDone &&
      (textConsts.dayKeysOrder.indexOf(todayString) > textConsts.dayKeysOrder.indexOf(item.day))

    #-- Decorate item
    if item.estimate?
      marker = @createMarker(editor, item.estimate.range)
      editor.decorateMarker(marker, type: 'highlight', class: "badge-estimate")

    if item.points?
      marker = @createMarker(editor, item.points.range)

      hclass = "badge-points-a"
      if item.points.amount >= 8
        hclass = "badge-points-e"
      else if item.points.amount >= 5
        hclass = "badge-points-d"
      else if item.points.amount >= 3
        hclass = "badge-points-c"
      else if item.points.amount >= 2
        hclass = "badge-points-b"
      editor.decorateMarker(marker, type: 'highlight', class: hclass)

    if item.calories?
      marker = @createMarker(editor, item.calories.range)
      editor.decorateMarker(marker, type: 'highlight', class: "badge-calories")

    if isFirstWeek and (item.dayString == highlightedDay)
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-highlight")

    if item.isDone
      marker = @createMarker(editor, item.doneBadgeRange)
      editor.decorateMarker(marker, type: 'highlight', class: "done-badge")
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-done")
    else if isFirstWeek and isLate
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-late")
    else if isFirstWeek and (item.day == todayString)
      lineMarker = @createMarker(editor, item.lineRange)
      editor.decorateMarker(lineMarker, type: 'line', class: "item-today")


  decorateTodo: (editor, tree, highlightedDay, selectedUnit) ->
    @highlightedDay = highlightedDay
    @selectedUnit = selectedUnit
    todayString = moment().format('dd')
    isFirstWeek = false
    #TODO: This probably double calculates collective amounts.
    for week, weekIndex in tree
      isFirstWeek = (weekIndex == 0)
      @decorateWeek(editor, week, selectedUnit)
      for section in week.children
        @decorateSection(editor, section, selectedUnit)
        for item in section.children
          @decorateItem(editor, item, isFirstWeek, todayString, highlightedDay)
