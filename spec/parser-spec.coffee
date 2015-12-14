parser = require '../lib/todo-parser'

describe "TodoParser", ->

  h1_valid =   '# Document Title'
  h2_valid =   '## Oct 8th 2015'
  h3_valid =   '### Some Project'
  item_valid = ['- T   2h  DONE  A task for Tuesday',
                ' - T   2h  DONE  A task for Tuesday',
                '     - T   2h  DONE  A task for Tuesday']
  days = ['M', 'T', 'W', 'R', 'F', 'S', 'U']

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
      spyOn(parser, 'parseH3Line')
      parser.parseLine(1, h2_valid)
      parser.parseLine(2, h3_valid)
      expect(parser.parseH3Line).toHaveBeenCalled()

    it 'calls ignoreLine on a valid H3 and no existing H2', ->
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

      it 'returns a week object with a getEstimatesPerDay function', ->
        expect(typeof week.getEstimatesPerDay).toBe('function')

      it 'returns a week object with a getDoneDurationsPerDay function', ->
        expect(typeof week.getDoneDurationsPerDay).toBe('function')

      describe 'getEstimatesPerDay', ->

        it 'returns an object with empty day values when it has no items', ->
          testObj = week.getEstimatesPerDay()
          for day in days
            expect(testObj[day]._milliseconds).not.toBeNull()

        it 'adds up the time estimates correctly', ->
          for i in [1..3]
            sectionItem = parser.parseH3Line(rowIndex, "### project #{i} ")
            for day, i in days
              testLine = "- #{day}   #{i}h  A quick brown fox"
              lineItem = parser.parseTodoLine(i, testLine)
              sectionItem.addTodoItem(lineItem)
            week.children.push(sectionItem)

          testObj = week.getEstimatesPerDay()
          for day, i in days
            expect(testObj[day].asHours()).toEqual(i * 3)

      describe 'getDoneDurationsPerDay', ->

        it 'returns an object with empty day values when it has no items', ->
          testObj = week.getDoneDurationsPerDay()
          for day in days
            expect(testObj[day]._milliseconds).not.toBeNull()

        it 'adds up the time estimates correctly', ->
          for i in [1..3]
            sectionItem = parser.parseH3Line(rowIndex, "### project #{i} ")
            for day, i in days
              testLine = "- #{day} #{i}h  DONE   A quick brown fox"
              lineItem = parser.parseTodoLine(i, testLine)
              sectionItem.addTodoItem(lineItem)
            week.children.push(sectionItem)
          testObj = week.getDoneDurationsPerDay()
          for day, i in days
            expect(testObj[day].asHours()).toEqual(i * 3)

      describe 'getTotalDuration', ->

      describe 'getDoneDuration', ->

      describe 'amount functions', ->

        week = section1 = section2 = null

        beforeEach ->
          week = parser.parseH2Line(rowIndex, h2_valid)
          section1 = parser.parseH3Line(rowIndex, "### project 1 ")
          section2 = parser.parseH3Line(rowIndex, "### project 2 ")
          week.children.push(section1)
          week.children.push(section2)
          spyOn(section1, 'getTotalAmount').andReturn(10)
          spyOn(section1, 'getCompletedAmount').andReturn(3)

          spyOn(section2, 'getTotalAmount').andReturn(20)
          spyOn(section2, 'getCompletedAmount').andReturn(10)

        describe 'getTotalAmount', ->
          it 'calls getTotalAmount for each section', ->
            week.getTotalAmount('pants')
            expect(section1.getTotalAmount).toHaveBeenCalledWith('pants')
            expect(section2.getTotalAmount).toHaveBeenCalledWith('pants')

          it 'adds up the total amounts for its sections', ->
            testAmount = week.getTotalAmount('pants')
            expect(testAmount).toEqual(30)

        describe 'getCompletedAmount', ->
          it 'calls getCompletedAmount for each section', ->
            week.getCompletedAmount('pants')
            expect(section1.getCompletedAmount).toHaveBeenCalledWith('pants')
            expect(section2.getCompletedAmount).toHaveBeenCalledWith('pants')

          it 'adds up the completed amounts for its sections', ->
            testCompleted = week.getCompletedAmount('pants')
            expect(testCompleted).toEqual(13)

      describe 'per day amount functions', ->
        week = section1 = section2 = null
        beforeEach ->
          week = parser.parseH2Line(rowIndex, h2_valid)
          section1 = parser.parseH3Line(rowIndex, "### project 1 ")
          section2 = parser.parseH3Line(rowIndex, "### project 2 ")
          week.children.push(section1)
          week.children.push(section2)
          spyOn(section1, 'getTotalAmountPerDay').andReturn([10, 20, 30, 40, 50, 60, 70])
          spyOn(section1, 'getCompletedAmountPerDay').andReturn([1, 2, 3, 4, 5, 6, 7])

          spyOn(section2, 'getTotalAmountPerDay').andReturn([90, 80, 70, 60, 50, 40, 30])
          spyOn(section2, 'getCompletedAmountPerDay').andReturn([9, 8, 7, 6, 5, 4, 3])

        describe 'getTotalAmountsPerDay', ->
          it 'calls section functions with the right unit', ->
            week.getTotalAmountPerDay('pants')
            expect(section1.getTotalAmountPerDay).toHaveBeenCalledWith('pants')
            expect(section2.getTotalAmountPerDay).toHaveBeenCalledWith('pants')
          it 'adds amounts correctly', ->
            testResult = week.getTotalAmountPerDay('pants')
            expect(testResult).toEqual([100, 100, 100, 100, 100, 100, 100])

        describe 'getCompletedAmountPerDay', ->
          it 'calls section functions with the right unit', ->
            week.getCompletedAmountPerDay('pants')
            expect(section1.getCompletedAmountPerDay).toHaveBeenCalledWith('pants')
            expect(section2.getCompletedAmountPerDay).toHaveBeenCalledWith('pants')
          it 'adds amounts correctly', ->
            testResult = week.getCompletedAmountPerDay('pants')
            expect(testResult).toEqual([10, 10, 10, 10, 10, 10, 10])

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

      it 'returns a section object with an addTodoItem function', ->
        expect(typeof sectionItem.addTodoItem).toBe('function')

      it 'returns a section object with a getEstimatesPerDay function', ->
        expect(typeof sectionItem.getEstimatesPerDay).toBe('function')

      it 'returns a section object with a getDoneDurationsPerDay function', ->
        expect(typeof sectionItem.getDoneDurationsPerDay).toBe('function')

      describe 'getEstimatesPerDay', ->

        it 'returns an object with empty day values when it has no items', ->
          testObj = sectionItem.getEstimatesPerDay()
          for day in days
            expect(testObj[day]._milliseconds).not.toBeNull()

        it 'returns an object with correct day values for each day', ->
          for day, i in days
            testLine = "- #{day}   #{i}h  A quick brown fox"
            lineItem = parser.parseTodoLine(i, testLine)
            sectionItem.addTodoItem(lineItem)
          testObj = sectionItem.getEstimatesPerDay()
          for day, i in days
            expect(testObj[day].hours()).toEqual(i)

        it 'adds up estimate durations for all tasks in a day', ->
          for i in [1..10]
            testLine = "- F  #{i}h  A quick brown fox"
            lineItem = parser.parseTodoLine(i, testLine)
            sectionItem.addTodoItem(lineItem)
          testObj = sectionItem.getEstimatesPerDay()
          expect(testObj['F'].asHours()).toEqual((10 * 11) / 2)

      describe 'getDoneDurationsPerDay', ->

        it 'returns an object with empty day values when it has no items', ->
          testObj = sectionItem.getDoneDurationsPerDay()
          for day in days
            expect(testObj[day]._milliseconds).not.toBeNull()

        it 'returns an object with correct day values for each day', ->
          for day, i in days
            testLine = "- #{day} #{i}h  DONE  A quick brown fox"
            lineItem = parser.parseTodoLine(i, testLine)
            sectionItem.addTodoItem(lineItem)
          testObj = sectionItem.getDoneDurationsPerDay()
          for day, i in days
            expect(testObj[day].hours()).toEqual(i)

        it 'adds up estimate durations for all tasks in a day', ->
          for i in [1..10]
            testLine = "- F  #{i}h  DONE  A quick brown fox"
            lineItem = parser.parseTodoLine(i, testLine)
            sectionItem.addTodoItem(lineItem)
          testObj = sectionItem.getDoneDurationsPerDay()
          expect(testObj['F'].asHours()).toEqual((10 * 11) / 2)

      describe 'Aggregate Amount Functions', ->
        section = null

        beforeEach ->
          testTodoItems = [
            "- M  70cal  A quick brown fox"
            "- T  30cal  A quick brown fox"
            "- F  50cal  DONE  A quick brown fox"
            "- F  150cal  DONE  A quick brown fox"
          ]

          section = parser.parseH3Line(0, '### Section title')
          for text, index in testTodoItems
            todoItem = parser.parseTodoLine(index, text)
            section.addTodoItem(todoItem)

        it 'getTotalAmount sums childrens amount for a unit', ->
          expect(section.getTotalAmount('cal')).toEqual(300)

        it 'getCompletedAmount sums childrens completed amount for a unit', ->
          expect(section.getCompletedAmount('cal')).toEqual(200)

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

      it 'keeps the day string in the dayString field', ->
        for day, i in days
          testLine = "- #{day}   2h  A task for Tuesday"
          output = parser.parseTodoLine(1, testLine)
          expect(output.dayString).toEqual(days[i])

      it 'interprets correctly all days of the week', ->
        expectedDays = ['Mo','Tu','We','Th','Fr','Sa','Su']
        for day, i in days
          testLine = "- #{day}   2h  A task for Tuesday"
          output = parser.parseTodoLine(1, testLine)
          expect(output.day).toEqual(expectedDays[i])

      #TODO: What happens if a line doesn't have a day?

    describe 'estimate', ->

      describe 'with duration string found', ->
        beforeEach ->
          testLine = '- T   2h  A task for Tuesday'
          output = parser.parseTodoLine(1, testLine)

        it 'has an estimate if it finds a valid duration string', ->
          expect(output.estimate).not.toBeNull()

        it 'has a moment duration in the estimate', ->
          expect(output.estimate.duration._milliseconds).not.toBeNull()

        it 'has text in the estimate', ->
          expect(output.estimate.text).toEqual('2h')

        it 'has a range in the estimate', ->
          expect(output.estimate.range).toEqual([[1,6],[1,8]])

      describe 'with duration string not found', ->

        it 'has a null estimate if it does not find a valid duration string', ->
          testLine = '- T   A task for Tuesday'
          output = parser.parseTodoLine(1, testLine)
          expect(output.estimate).toBeNull()

    describe 'amount functions', ->
      describe 'getAmount', ->
        describe 'pts', ->
          it 'returns pts amount if item has pts', ->
            todoItem = parser.parseTodoLine(0, '- T  3pt  A task for Tuesday')
            testAmount = todoItem.getAmount('pt')
            expect(testAmount).toEqual(3)

          it 'returns 0 if item does not have pts', ->
            todoItem = parser.parseTodoLine(0, '- T  A task for Tuesday')
            testAmount = todoItem.getAmount('pt')
            expect(testAmount).toEqual(0)

        describe 'cal', ->
          it 'returns cal amount if item has cal', ->
            todoItem = parser.parseTodoLine(0, '- T  3cal  A task for Tuesday')
            testAmount = todoItem.getAmount('cal')
            expect(testAmount).toEqual(3)

          it 'returns 0 if item does not have cal', ->
            todoItem = parser.parseTodoLine(0, '- T  A task for Tuesday')
            testAmount = todoItem.getAmount('cal')
            expect(testAmount).toEqual(0)

      describe 'getCompletedAmount', ->
        it 'calls @getAmount if item is done', ->
          todoItem = parser.parseTodoLine(0, '- T  DONE A task for Tuesday')
          spyOn(todoItem, 'getAmount')
          testAmount = todoItem.getCompletedAmount('pants')
          expect(todoItem.getAmount).toHaveBeenCalledWith('pants')

        it 'does not call @getAmount and returns 0 if item is not done', ->
          todoItem = parser.parseTodoLine(0, '- T   A task for Tuesday')
          spyOn(todoItem, 'getAmount')
          testAmount = todoItem.getCompletedAmount('pants')
          expect(todoItem.getAmount).not.toHaveBeenCalled()
          expect(testAmount).toEqual(0)

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

  describe 'createDayDurations', ->

    it 'returns a dict of moment objects for each day', ->
      days = ['U', 'M', 'T', 'W', 'R', 'F', 'S']
      testObj = parser.createDayDurations()
      for day in days
        expect(testObj[day]._milliseconds).not.toBeNull()

  #TODO: Add tests for createDurationItem
  describe 'createDurationItem', ->

  describe 'createPointsItem', ->
    it 'returns null when there is not a points token', ->
      testLine = '- T   A task for Tuesday'
      testObj = parser.createPointsItem(1, testLine)
      expect(testObj).toBeNull()

    describe 'when there is a points token', ->
      testLine = '- T 8pt A task for Tuesday'

      it 'returns a points item with the correct amount', ->
        testObj = parser.createPointsItem(1, testLine)
        expect(testObj.amount).toEqual(8)

      it 'returns a points item with the correct range', ->
        testObj = parser.createPointsItem(9, testLine)
        targetRange = parser.inlineTextRange(9, 4, 7)
        expect(testObj.range).toEqual(targetRange)

  describe 'createCaloriesItem', ->
    it 'returns null when there is not a calories token', ->
      testLine = '- T   Food'
      testObj = parser.createPointsItem(1, testLine)
      expect(testObj).toBeNull()

    describe 'when there is a points token', ->
      testLine = '- T 30cal Food'

      it 'returns a points item with the correct amount', ->
        testObj = parser.createCaloriesItem(1, testLine)
        expect(testObj.amount).toEqual(30)

      it 'returns a points item with the correct range', ->
        testObj = parser.createCaloriesItem(9, testLine)
        targetRange = parser.inlineTextRange(9, 4, 9)
        expect(testObj.range).toEqual(targetRange)
