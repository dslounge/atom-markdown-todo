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

  describe "parseH2Line", ->
    rowIndex = week = null

    describe "with valid input", ->

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
