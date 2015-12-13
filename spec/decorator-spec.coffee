decorator = require '../lib/todo-decorator'

describe 'TodoDecorator', ->
  mockEditor = mockSection = null

  beforeEach ->
    mockEditor =
      decorateMarker: ->
    mockSection =
      textRange: [[0, 1], [0,10]]
      getTotalAmount: ->
      getCompletedAmount: ->

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
        spyOn(decorator, 'createSectionUnitsOverlay')

      it 'does not create or decorate a marker when selected unit is null', ->
        decorator.decorateSection(mockEditor, mockSection, null)
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'calls createSectionHoursOverlay when selected unit is time', ->
        decorator.decorateSection(mockEditor, mockSection, 'time')
        expect(decorator.createSectionHoursOverlay).toHaveBeenCalled()

      it 'calls createSectionUnitsOverlay when selected unit is pts', ->
        decorator.decorateSection(mockEditor, mockSection, 'pts')
        expect(decorator.createSectionUnitsOverlay).toHaveBeenCalled()

      it 'calls createSectionUnitsOverlay when selected unit is cal', ->
        decorator.decorateSection(mockEditor, mockSection, 'cal')
        expect(decorator.createSectionUnitsOverlay).toHaveBeenCalled()

    describe 'createSectionHoursOverlay', ->
    describe 'createSectionPointsOverlay', ->

    describe 'createSectionUnitsOverlay', ->
      it 'calls section.getTotalAmount and section.getCompletedAmount', ->
        spyOn(mockSection, 'getTotalAmount')
        spyOn(mockSection, 'getCompletedAmount')
        decorator.createSectionUnitsOverlay(mockSection, 'cal')
        expect(mockSection.getTotalAmount).toHaveBeenCalledWith('cal')
        expect(mockSection.getCompletedAmount).toHaveBeenCalledWith('cal')

      it 'creates an overlayElement if the section has amount of requested unit', ->
        spyOn(mockSection, 'getTotalAmount').andReturn(2)
        spyOn(mockSection, 'getCompletedAmount').andReturn(1)
        decorator.createSectionUnitsOverlay(mockSection, 'cal')
        expect(decorator.createSectionOverlayElement).toHaveBeenCalled()

      it 'does not create an overlayElement if the section has no amount of requested unit', ->
        spyOn(mockSection, 'getTotalAmount').andReturn(0)
        spyOn(mockSection, 'getCompletedAmount').andReturn(0)
        decorator.createSectionUnitsOverlay(mockSection)
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
