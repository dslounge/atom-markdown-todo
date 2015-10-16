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

    it "has no return value", ->
      testReturn = parser.parseLine(1, "Hello")
      expect(testReturn).toBeUndefined()

    it "calls createH2Item on a valid H2 row", ->
      spyOn(parser, 'createH2Item')
      parser.parseLine(1, h2_valid)
      expect(parser.createH2Item).toHaveBeenCalled()

    it "calls createH3Item on a valid H3 row and existing H2", ->
      console.log "-- test createH3Item-- "
      spyOn(parser, 'createH3Item')
      parser.parseLine(1, h2_valid)
      parser.parseLine(2, h3_valid)
      expect(parser.createH3Item).toHaveBeenCalled()

    it "calls ignoreLine on a valid H3 and no existing H2", ->
      console.log "-- test createH3Item-- "
      spyOn(parser, 'createH3Item')
      spyOn(parser, 'ignoreLine')
      parser.parseLine(2, h3_valid)
      expect(parser.ignoreLine).toHaveBeenCalled()
      expect(parser.createH3Item).not.toHaveBeenCalled()

    it "calls createTodoItem on a valid list row and existing H2 and H3", ->
      spyOn(parser, 'createTodoItem')
      parser.parseLine(1, h2_valid)
      parser.parseLine(2, h3_valid)
      parser.parseLine(3, item_valid[0])
      expect(parser.createTodoItem).toHaveBeenCalled()

    it "calls ignoreLine on a valid list row and no existing parents", ->
      spyOn(parser, 'createTodoItem')
      spyOn(parser, 'ignoreLine')
      parser.parseLine(3, item_valid[0])
      expect(parser.ignoreLine).toHaveBeenCalled()
      expect(parser.createTodoItem).not.toHaveBeenCalled()

    it "calls ignoreLine on an item it doesn't understand", ->
      spyOn(parser, 'ignoreLine')
      parser.parseLine(4, h1_valid)
      expect(parser.ignoreLine).toHaveBeenCalled()
