parser = require '../lib/todo-parser'

describe "TodoParser", ->

  h1_valid =   '# Document Title'
  h2_valid =   '## Oct 8th 2015'
  h3_valid =   '### Some Project'
  item_valid = ['- T   2h  DONE  A task for Tuesday',
                ' - T   2h  DONE  A task for Tuesday',
                '     - T   2h  DONE  A task for Tuesday']

  beforeEach ->
    parser.reset()

  it "it resets", ->
    parser.currentH2 = "monkeys"
    parser.currentH3 = "blah"
    parser.todoModel = ["weee"]
    parser.reset()
    expect(parser.currentH2).toBeNull()
    expect(parser.currentH3).toBeNull()
    expect(parser.todoModel).toEqual([])

  describe "parseLine()", ->

    it 'has no return value', ->
      testReturn = parser.parseLine(1, "Hello")
      expect(testReturn).toBeUndefined()

    it 'calls parseH2Line on a valid H2 row', ->
      spyOn(parser, 'parseH2Line')
      parser.parseLine(1, h2_valid)
      expect(parser.parseH2Line).toHaveBeenCalled()

    it 'calls parseH3Line on a valid H3 row and existing H2', ->
      console.log "-- test parseH3Line-- "
      spyOn(parser, 'parseH3Line')
      parser.parseLine(1, h2_valid)
      parser.parseLine(2, h3_valid)
      expect(parser.parseH3Line).toHaveBeenCalled()

    it 'calls ignoreLine on a valid H3 and no existing H2', ->
      console.log "-- test parseH3Line-- "
      spyOn(parser, 'parseH3Line')
      spyOn(parser, 'ignoreLine')
      parser.parseLine(2, h3_valid)
      expect(parser.ignoreLine).toHaveBeenCalled()
      expect(parser.parseH3Line).not.toHaveBeenCalled()

    it 'calls parseTodoLine on a valid list row and existing H2 and H3', ->
      spyOn(parser, 'parseTodoLine')
      parser.parseLine(1, h2_valid)
      parser.parseLine(2, h3_valid)
      parser.parseLine(3, item_valid[0])
      expect(parser.parseTodoLine).toHaveBeenCalled()

    it 'calls ignoreLine on a valid list row and no existing parents', ->
      spyOn(parser, 'parseTodoLine')
      spyOn(parser, 'ignoreLine')
      parser.parseLine(3, item_valid[0])
      expect(parser.ignoreLine).toHaveBeenCalled()
      expect(parser.parseTodoLine).not.toHaveBeenCalled()

    it 'calls ignoreLine on an item it does not understand', ->
      spyOn(parser, 'ignoreLine')
      parser.parseLine(4, h1_valid)
      expect(parser.ignoreLine).toHaveBeenCalled()

  describe 'parseH2Line', ->
    rowIndex = week = null

    describe 'with valid input', ->

      beforeEach ->
        rowIndex = 1
        testH2 = '## Oct 8th 2015'
        week = parser.parseH2Line(rowIndex, testH2)

      it 'returns a week object', ->
        expect(week).not.toBeNull()

      it 'returns a week object with a valid bufferRowIndex', ->
        expect(week.bufferRowIndex).toBe(rowIndex)

      it 'returns a week object with a valid startDate', ->
        expect(week.startDate).not.toBeNull()
        expect(week.startDate.format('YYYY MM DD')).toEqual('2015 10 08')

      it 'returns a week object with a valid textRange', ->
        expect(week.textRange).not.toBeNull()
        expect(week.textRange).toEqual([[1, 3], [1, 15]])

      it 'returns a week object with an empty children list', ->
        expect(week.children).toEqual([])

  describe 'parseH3Line', ->

    describe 'with valid input', ->
      sectionItem = rowIndex = null
      beforeEach ->
        rowIndex = 2
        testH3 = '### Some Project'
        sectionItem = parser.parseH3Line(rowIndex, testH3)

      it 'returns a section object', ->
        expect(sectionItem).not.toBeNull()

      it 'returns a section object with valid bufferRowIndex', ->
        expect(sectionItem.bufferRowIndex).toBe(2)

      it 'returns a section object with valid title', ->
        expect(sectionItem.title).toBe('Some Project')

      it 'returns a section object with valid textRange', ->
        expect(sectionItem.textRange).toEqual([[2, 4], [2, 16]])

      it 'returns a section object with valid children', ->
        expect(sectionItem.children).toEqual([])

      it 'returns a section object with valid estimateTotalDuration', ->
        # moment durations don't have a isA boolean flag for testing.
        expect(sectionItem.estimateTotalDuration._milliseconds).not.toBeNull()

      it 'returns a section object with valid estimateDoneDuration', ->
        # moment durations don't have a isA boolean flag for testing.
        expect(sectionItem.estimateDoneDuration._milliseconds).not.toBeNull()

      it 'returns a section object with valid addTodoItem', ->
        expect(typeof sectionItem.addTodoItem).toBe('function')

  describe 'parseTodoLine', ->
    output = testLine = null

    describe 'basic validity', ->

      beforeEach ->
        testLine = '- T   2h  DONE  A task for Tuesday'
        output = parser.parseTodoLine(1, testLine)

      it 'returns something', ->
        expect(output).not.toBeNull()

      it 'returns a todo item with a valid lineRange', ->
        expect(output.lineRange).toEqual([[1, 0],[1, testLine.length]])

      it 'returns a todo item with a valid bufferRowIndex', ->
        expect(output.bufferRowIndex).toEqual(1)

    describe 'todoItem.isDone', ->

      describe 'when todo line contains DONE', ->
        beforeEach ->
          testLine = '- T   2h  DONE  A task for Tuesday'
          output = parser.parseTodoLine(1, testLine)

        it 'is marked as done', ->
          expect(output.isDone).toBe(true)

        it 'doneBadgeRange is a valid range if DONE is found', ->
          expect(output.doneBadgeRange).toEqual([[1,10],[1, 14]])

      describe 'when todo line does not contain DONE', ->
        beforeEach ->
          testLine = '- T   2h  A task for Tuesday'
          output = parser.parseTodoLine(1, testLine)

        it 'is not marked as done', ->
          expect(output.isDone).toBeFalsy()

        it 'doneBadgeRange is null', ->
          expect(output.doneBadgeRange).toBeNull()


    describe 'days', ->
      it 'interprets correctly all days of the week'

      #TODO: What happens if a line doesn't have a day?

    describe 'estimate', ->
      it 'has an estimate duration if it finds a valid duration string', ->
      it 'has a null duration if it does not find a valid duration string', ->

  describe 'dateFromHeader', ->
    testOutput = null

    beforeEach ->
      testHeader = '## Oct 8th 2015'
      testOutput = parser.dateFromHeader(testHeader)

    it 'returns a moment.js object', ->
      expect(testOutput._isAMomentObject).toBe(true)

    it 'parses a date in MMM-Do-YYYY format correctly', ->
      expect(testOutput.format('YYYY MM DD')).toEqual('2015 10 08')

  describe 'parseDate', ->
    testOutput = null

    beforeEach ->
      testDate = 'Oct 8th 2015'
      testOutput = parser.parseDate(testDate)

    it 'returns a moment.js object', ->
      expect(testOutput._isAMomentObject).toBe(true)

    it 'parses a date in MMM-Do-YYYY format correctly', ->
      expect(testOutput.format('YYYY MM DD')).toEqual('2015 10 08')

  describe 'inlineTextRange', ->

    it 'returns a 2-dimensional array', ->
      output = parser.inlineTextRange(1, 3, 15)
      expect(output).toEqual([[1, 3], [1, 15]])
