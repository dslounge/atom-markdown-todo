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

  parseH2Line: (index, text) ->
    console.log "--parseH2Line--: #{index}, #{text}"
    dateStartIndex = 3
    dateLength =　text.substring(dateStartIndex).length
    bufferRowIndex: index
    startDate: @dateFromHeader(text)
    textRange: @inlineTextRange(index, dateStartIndex, dateStartIndex + dateLength)
    children: []

  parseH3Line: (index, text) ->
    console.log "--parseH3Line--: #{index}, #{text}"
    title = text.substring(4)
    bufferRowIndex: index
    title: title
    textRange: @inlineTextRange(index, 4, 4 + title.length)
    children: []
    estimateTotalDuration: moment.duration()
    estimateDoneDuration: moment.duration()
    addTodoItem: (item) ->
      @children.push item
      if item?.estimate?
        @estimateTotalDuration.add(item.estimate.duration)
        if item.isDone
          @estimateDoneDuration.add(item.estimate.duration)

  parseTodoLine: (rowIndex, text) ->
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

  ignoreLine: (rowIndex, text) ->

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
    console.log "parseLine: #{index}, #{text}"
    if textConsts.regex.h2.test(text)
      @currentH3 = null
      @currentH2 = h2Item = @parseH2Line(index, text)
      console.log "push h2: #{@currentH2}"
      @todoModel.push h2Item
    else if textConsts.regex.h3.test(text) and @currentH2?
      #ignore H3 that aren't under H2
      @currentH3 = h3Item = @parseH3Line(index, text)
      @currentH2.children.push h3Item

    else if textConsts.regex.item.test(text) and @currentH3?
      #ignore items that aren't under H3
      item = @parseTodoLine(index, text)
      @currentH3.addTodoItem(item)
    else
      @ignoreLine(index, text)
