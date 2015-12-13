decorator = require '../lib/todo-decorator'

describe 'TodoDecorator', ->
  mockEditor = mockSection = mockWeek = null

  beforeEach ->
    mockEditor =
      decorateMarker: ->

    mockSection =
      textRange: [[0, 1], [0,10]]
      getTotalAmount: ->
      getCompletedAmount: ->

    mockWeek =
      textRange: [[0, 1], [0,10]]
      getTotalAmount: ->
      getCompletedAmount: ->

    spyOn(mockEditor, 'decorateMarker')

  #TODO
  describe 'destroyMarkers', ->

  #TODO
  describe 'createMarker', ->

  describe 'week decoration', ->

    beforeEach ->
      spyOn(decorator, 'createMarker')
      spyOn(decorator, 'createWeekOverlayElement')

    describe 'decorateWeek', ->
      beforeEach ->
        spyOn(decorator, 'createWeekHoursOverlay').andReturn({})
        spyOn(decorator, 'createWeekUnitOverlay')

      it 'does not decorate week when selected unit is null', ->
        decorator.decorateWeek(mockEditor, mockWeek, null)
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'does not decorate week if no overlay element is created', ->
        # createWeekUnitOverlay spy returns nothing which is what we're testing
        decorator.decorateWeek(mockEditor, mockWeek, 'pants')
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'decorates week if overlay element is created', ->
        # createWeekHoursOverlay spy returns something which is what we're testing
        decorator.decorateWeek(mockEditor, mockWeek, 'time')
        expect(decorator.createMarker).toHaveBeenCalled()
        expect(mockEditor.decorateMarker).toHaveBeenCalled()

      it 'calls createWeekHoursOverlay if selected unit is time', ->
        decorator.decorateWeek(mockEditor, mockSection, 'time')
        expect(decorator.createWeekHoursOverlay).toHaveBeenCalled()
        expect(decorator.createWeekUnitOverlay).not.toHaveBeenCalled()

      it 'calls createWeekUnitOverlay if selected unit is anything else', ->
        decorator.decorateWeek(mockEditor, mockSection, 'pt')
        expect(decorator.createWeekUnitOverlay).toHaveBeenCalled()
        expect(decorator.createWeekHoursOverlay).not.toHaveBeenCalled()

    describe 'createWeekHoursOverlay', ->

    describe 'createWeekUnitOverlay', ->
      it 'calls week.getTotalAmount and section.getCompletedAmount', ->
        spyOn(mockWeek, 'getTotalAmount')
        spyOn(mockWeek, 'getCompletedAmount')
        decorator.createWeekUnitOverlay(mockWeek, 'cal')
        expect(mockWeek.getTotalAmount).toHaveBeenCalledWith('cal')
        expect(mockWeek.getCompletedAmount).toHaveBeenCalledWith('cal')

      it 'creates an overlayElement if the section has amount of requested unit', ->
        spyOn(mockWeek, 'getTotalAmount').andReturn(2)
        spyOn(mockWeek, 'getCompletedAmount').andReturn(1)
        decorator.createWeekUnitOverlay(mockWeek, 'cal')
        expect(decorator.createWeekOverlayElement).toHaveBeenCalled()

      it 'does not create an overlayElement if the section has no amount of requested unit', ->
        spyOn(mockWeek, 'getTotalAmount').andReturn(0)
        spyOn(mockWeek, 'getCompletedAmount').andReturn(0)
        decorator.createWeekUnitOverlay(mockWeek, 'cal')
        expect(decorator.createWeekOverlayElement).not.toHaveBeenCalled()

  describe 'section decoration', ->

    beforeEach ->
      spyOn(decorator, 'createMarker')
      spyOn(decorator, 'createSectionOverlayElement')

    describe 'decorateSection', ->
      beforeEach ->
        spyOn(decorator, 'createSectionHoursOverlay').andReturn({})
        spyOn(decorator, 'createSectionUnitsOverlay')

      it 'does not decorate when selected unit is null', ->
        decorator.decorateSection(mockEditor, mockSection, null)
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'does not decorate if no overlay element is created', ->
        # spy createSectionUnitsOverlay returns nothing, which is what we want to test here
        decorator.decorateSection(mockEditor, mockSection, 'pt')
        expect(decorator.createMarker).not.toHaveBeenCalled()
        expect(mockEditor.decorateMarker).not.toHaveBeenCalled()

      it 'decorates section if overlay element is created', ->
        # spy createSectionHoursOverlay returns something, which is what we want to test here
        decorator.decorateSection(mockEditor, mockSection, 'time')
        expect(decorator.createMarker).toHaveBeenCalled()
        expect(mockEditor.decorateMarker).toHaveBeenCalled()

      it 'calls createSectionHoursOverlay when selected unit is time', ->
        decorator.decorateSection(mockEditor, mockSection, 'time')
        expect(decorator.createSectionHoursOverlay).toHaveBeenCalled()
        expect(decorator.createSectionUnitsOverlay).not.toHaveBeenCalled()

      it 'calls createSectionUnitsOverlay when selected unit is something else', ->
        decorator.decorateSection(mockEditor, mockSection, 'pt')
        expect(decorator.createSectionUnitsOverlay).toHaveBeenCalled()
        expect(decorator.createSectionHoursOverlay).not.toHaveBeenCalled()

    describe 'createSectionHoursOverlay', ->

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
