decorator = require '../lib/todo-decorator'

describe 'TodoDecorator', ->
  mockEditor = mockSection = null

  beforeEach ->
    mockEditor =
      decorateMarker: ->
    mockSection =
      textRange: [[0, 1], [0,10]]
      getTotalCalories: ->
      getCompletedCalories: ->

    spyOn(mockEditor, 'decorateMarker')

  #TODO
  describe 'destroyMarkers', ->

  #TODO
  describe 'createMarker', ->

  describe 'section overlays', ->

    beforeEach ->
      spyOn(decorator, 'createMarker')
      spyOn(decorator, 'createSectionOverlayElement')

    describe 'decorateSection', ->
      beforeEach ->
        spyOn(decorator, 'createSectionHoursOverlay')
        spyOn(decorator, 'createSectionPointsOverlay')
        spyOn(decorator, 'createSectionCaloriesOverlay')

      it 'does not create or decorate a marker when selected unit is null', ->
        decorator.decorateSection(mockEditor, mockSection, null)
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'calls createSectionHoursOverlay when selected unit is time', ->
        decorator.decorateSection(mockEditor, mockSection, 'time')
        expect(decorator.createSectionHoursOverlay).toHaveBeenCalled()

      it 'calls createSectionPointsOverlay when selected unit is pts', ->
        decorator.decorateSection(mockEditor, mockSection, 'pts')
        expect(decorator.createSectionPointsOverlay).toHaveBeenCalled()

      it 'calls createSectionCaloriesOverlay when selected unit is cal', ->
        decorator.decorateSection(mockEditor, mockSection, 'cal')
        expect(decorator.createSectionCaloriesOverlay).toHaveBeenCalled()

    describe 'createSectionHoursOverlay', ->
    describe 'createSectionPointsOverlay', ->

    describe 'createSectionCaloriesOverlay', ->
      it 'calls section.getTotalCalories and section.getCompletedCalories', ->
        spyOn(mockSection, 'getTotalCalories')
        spyOn(mockSection, 'getCompletedCalories')
        decorator.createSectionCaloriesOverlay(mockSection)
        expect(mockSection.getTotalCalories).toHaveBeenCalled()
        expect(mockSection.getCompletedCalories).toHaveBeenCalled()

      it 'creates an overlayElement if the section has calories', ->
        spyOn(mockSection, 'getTotalCalories').andReturn(2)
        spyOn(mockSection, 'getCompletedCalories').andReturn(1)
        decorator.createSectionCaloriesOverlay(mockSection)
        expect(decorator.createSectionOverlayElement).toHaveBeenCalled()

      it 'does not create an overlayElement if the section has no calories', ->
        spyOn(mockSection, 'getTotalCalories').andReturn(0)
        spyOn(mockSection, 'getCompletedCalories').andReturn(0)
        decorator.createSectionCaloriesOverlay(mockSection)
        expect(decorator.createSectionOverlayElement).not.toHaveBeenCalled()


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
