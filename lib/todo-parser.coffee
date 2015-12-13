moment = require 'moment'
textConsts = require './todo-text-consts'

module.exports =
  todoModel: []
  currentH2: null #how do I make state private?
  currentH3: null
  ## Resets the state. Might be better to make this a class
  ## and create an instance.
  reset: ->
    @todoModel = []
    @currentH2 = null
    @currentH3 = null

  parseDate: (dateString) ->
    moment(dateString, textConsts.formats.dateformat)

  dateFromHeader: (header) ->
    datePart = header.substring(3)
    @parseDate(datePart)

  inlineTextRange: (row, start, end) ->
    return [[row, start], [row, end]]

  createDayDurations: ->
    dict = {}
    for day in textConsts.days
      dict[day] = moment.duration()
    dict

  parseH2Line: (index, text) ->
    # console.log "--parseH2Line--: #{index}, #{text}"
    dateStartIndex = 3
    dateLength =　text.substring(dateStartIndex).length
    bufferRowIndex: index
    startDate: @dateFromHeader(text)
    dayDurations: @createDayDurations()
    dayCompletedDurations: @createDayDurations()
    textRange: @inlineTextRange(index, dateStartIndex, dateStartIndex + dateLength)
    children: []
    getEstimatesPerDay: ->
      #TODO: It's dumb to have to track @dayDurations. We should be able to make one on the fly.
      for section in @children
        sectionEstimates = section.getEstimatesPerDay()
        for day in textConsts.days
          @dayDurations[day].add(sectionEstimates[day])
      @dayDurations
    # TODO: Needs to be completed
    getDoneDurationsPerDay: ->
      #TODO: It's dumb to have to track @dayCompletedDurations. We should be able to make one on the fly.
      for section in @children
        sectionEstimates = section.getDoneDurationsPerDay()
        for day in textConsts.days
          @dayCompletedDurations[day].add(sectionEstimates[day])
      @dayCompletedDurations
    getTotalDuration: ->
      duration = moment.duration()
      for section in @children
        duration.add(section.getTotalDuration())
      duration

    getDoneDuration: ->
      duration = moment.duration()
      for section in @children
        duration.add(section.getDoneDuration())
      duration

    getTotalAmount: (unit) ->
      (section.getTotalAmount(unit) for section in @children).reduce( (p, c) -> p + c)
    getCompletedAmount: (unit) ->
      (section.getCompletedAmount(unit) for section in @children).reduce( (p, c) -> p + c)

  parseH3Line: (index, text) ->
    title = text.substring(4)
    bufferRowIndex: index
    title: title
    textRange: @inlineTextRange(index, 4, 4 + title.length)
    children: []
    dayDurations: @createDayDurations()
    dayCompletedDurations: @createDayDurations()
    estimateTotalDuration: moment.duration()
    estimateDoneDuration: moment.duration()
    getTotalDuration: ->
      @estimateTotalDuration
    getDoneDuration: ->
      @estimateDoneDuration
    addTodoItem: (item) ->
      @children.push item
      # TODO I don't think this needs to be precomputed
      if item?.estimate?
        @estimateTotalDuration.add(item.estimate.duration)
        if item.isDone
          @estimateDoneDuration.add(item.estimate.duration)
    getEstimatesPerDay: ->
      #TODO: It's dumb to have to track @dayDurations. We should be able to make one on the fly.
      for item, i in @children
        if item.dayString? and item.estimate?
          @dayDurations[item.dayString].add(item.estimate.duration)
      @dayDurations
    getDoneDurationsPerDay: ->
      #TODO: It's dumb to have to track @dayCompletedDurations. We should be able to make one on the fly.
      for item, i in @children
        if item.dayString? and item.isDone and item.estimate?
          @dayCompletedDurations[item.dayString].add(item.estimate.duration)
      @dayCompletedDurations
    getTotalAmount: (unit) ->
      (item.getAmount(unit) for item in @children).reduce( (p, c) -> p + c)
    getCompletedAmount: (unit) ->
      (item.getCompletedAmount(unit) for item in @children).reduce( (p, c) -> p + c)

  parseTodoLine: (rowIndex, text) ->
    doneIndex = text.search(textConsts.regex.doneBadge)
    day = text.match(textConsts.regex.day)?[0].trim()

    # because I'm using the /g flag exec isn't idempotent
    # reset the lastIndex property from previous run
    textConsts.regex.duration.lastIndex = 0
    # get the first duration (estimate)
    estimate = @createDurationItem(rowIndex, textConsts.regex.duration.exec(text))
    #get the second duration (actual)
    actual = @createDurationItem(rowIndex, textConsts.regex.duration.exec(text))

    points = @createPointsItem(rowIndex, text)
    calories = @createCaloriesItem(rowIndex, text)

    isDone = (doneIndex != -1)

    isDone: isDone
    dayString: day
    day: textConsts.formats.dayKeys[day]
    doneBadgeRange: if isDone then @inlineTextRange(rowIndex, doneIndex, doneIndex + 4) else null
    lineRange: @inlineTextRange(rowIndex, 0, text.length)
    bufferRowIndex: rowIndex
    estimate: estimate
    actual: actual #TODO might drop support for this
    points: points
    calories: calories
    getAmount: (unit) ->
      #TODO: This should be generalized
      switch unit
        when 'cal' then @calories?.amount || 0
        when 'pt' then @points?.amount || 0
        else 0
    getCompletedAmount: (unit) ->
      if @isDone
        @getAmount(unit)
      else 0

  ignoreLine: (rowIndex, text) ->

  createPointsItem: (rowIndex, text) ->
    regResult = textConsts.regex.points.exec(text)
    if regResult?
      text = regResult[0]
      number = parseInt(text.slice(0, -2)) #pt is 2 chars
      points =
        amount: number
        range: @inlineTextRange(rowIndex, regResult.index, regResult.index + text.length)
    else
      null

  createCaloriesItem: (rowIndex, text) ->
    regResult = textConsts.regex.calories.exec(text)
    if regResult?
      text = regResult[0]
      number = parseInt(text.slice(0, -3)) #cal is 3 chars
      calories =
        amount: number
        range: @inlineTextRange(rowIndex, regResult.index, regResult.index + text.length)
    else
      null

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

  parseLine: (index, text) ->
    # console.log "parseLine: #{index}, #{text}"
    if textConsts.regex.h2.test(text)
      @currentH3 = null
      @currentH2 = h2Item = @parseH2Line(index, text)
      # console.log "push h2: #{@currentH2}"
      @todoModel.push h2Item
    else if textConsts.regex.h3.test(text) and @currentH2?
      #ignore H3 that aren't under H2
      @currentH3 = h3Item = @parseH3Line(index, text)
      @currentH2.children.push h3Item

    else if textConsts.regex.item.test(text) and textConsts.regex.day.test(text) and @currentH3?
      #ignore items that aren't under H3
      item = @parseTodoLine(index, text)
      @currentH3.addTodoItem(item)
    else
      @ignoreLine(index, text)
