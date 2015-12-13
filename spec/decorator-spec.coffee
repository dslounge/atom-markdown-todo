decorator = require '../lib/todo-decorator'

describe 'TodoDecorator', ->

  #TODO
  describe 'destroyMarkers', ->

  #TODO
  describe 'createMarker', ->

  #TODO
  describe 'decorateTodo', ->
    mockTree = moment = null

    beforeEach ->
      mockTree = [
        children: [
          children: [1]
        ]
      ]

      spyOn(decorator, 'decorateWeek')
      spyOn(decorator, 'decorateSection')
      spyOn(decorator, 'decorateItem')
      oldDate = Date
      spyOn(window, 'Date').andCallFake( ->
        testDate = new oldDate(1995, 12, 17) #This is a wednesday
      )

    it 'keeps highlightedDay parameter', ->
      decorator.decorateTodo(null, mockTree, 'highlightDay', null)
      expect(decorator.highlightedDay).toEqual('highlightDay')

    it 'keeps selectedUnit parameter', ->
      decorator.decorateTodo(null, mockTree, null, 'selectedUnit')
      expect(decorator.selectedUnit).toEqual('selectedUnit')

    it 'calls @decorateItem with todayString', ->
      decorator.decorateTodo(null, mockTree, null, null)
      expect(decorator.decorateItem).toHaveBeenCalledWith(null, 1, true, "We", null)

    it 'calls @decorateWeek with params editor and week params', ->
    it 'calls @decorateSection with editor and section params', ->
