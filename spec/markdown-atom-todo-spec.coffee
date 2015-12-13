MarkdownAtomTodo = require '../lib/markdown-atom-todo'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "MarkdownAtomTodo", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('markdown-atom-todo')
    MarkdownAtomTodo.todoMode = true

  describe "cycleDayHighlight", ->

    beforeEach ->
      spyOn(MarkdownAtomTodo, 'highlightDay')

    it 'does no work when not in todoMode', ->
      MarkdownAtomTodo.todoMode = false

    it 'works if in todoMode', ->
      MarkdownAtomTodo.cycleDayHighlight()
      expect(MarkdownAtomTodo.highlightDay).toHaveBeenCalled()

    it 'cycles through the days', ->
      days = [null, 'U', 'M', 'T', 'W', 'R', 'F', 'S']
      expectations = ['U', 'M', 'T', 'W', 'R', 'F', 'S', null]
      for day, index in days
        MarkdownAtomTodo.highlightedDay = day
        expected = expectations[index]
        MarkdownAtomTodo.cycleDayHighlight()
        expect(MarkdownAtomTodo.highlightDay).toHaveBeenCalledWith(expected)

  describe "cycleUnitDisplay", ->
    beforeEach ->
      spyOn(MarkdownAtomTodo, 'displayUnit')

    it 'does no work when not in todoMode', ->
      MarkdownAtomTodo.todoMode = false

    it 'works if in todoMode', ->
      MarkdownAtomTodo.displayUnit()
      expect(MarkdownAtomTodo.displayUnit).toHaveBeenCalled()

    it 'cycles through the units', ->
      units = [null, 'time', 'cal', 'pts']
      expectations = ['time', 'cal', 'pts', null]
      for unit, index in units
        MarkdownAtomTodo.selectedUnit = unit
        expected = expectations[index]
        MarkdownAtomTodo.cycleUnitDisplay()
        expect(MarkdownAtomTodo.displayUnit).toHaveBeenCalledWith(expected)

  describe "when the markdown-atom-todo:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # # Before the activation event the view is not on the DOM, and no panel
      # # has been created
      # expect(workspaceElement.querySelector('.markdown-atom-todo')).not.toExist()
      #
      # # This is an activation event, triggering it will cause the package to be
      # # activated.
      # atom.commands.dispatch workspaceElement, 'markdown-atom-todo:toggle'
      #
      # waitsForPromise ->
      #   activationPromise
      #
      # runs ->
      #   expect(workspaceElement.querySelector('.markdown-atom-todo')).toExist()
      #
      #   markdownAtomTodoElement = workspaceElement.querySelector('.markdown-atom-todo')
      #   expect(markdownAtomTodoElement).toExist()
      #
      #   markdownAtomTodoPanel = atom.workspace.panelForItem(markdownAtomTodoElement)
      #   expect(markdownAtomTodoPanel.isVisible()).toBe true
      #   atom.commands.dispatch workspaceElement, 'markdown-atom-todo:toggle'
      #   expect(markdownAtomTodoPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # # This test shows you an integration test testing at the view level.
      #
      # # Attaching the workspaceElement to the DOM is required to allow the
      # # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # # requires that the workspaceElement is on the DOM. Tests that attach the
      # # workspaceElement to the DOM are generally slower than those off DOM.
      # jasmine.attachToDOM(workspaceElement)
      #
      # expect(workspaceElement.querySelector('.markdown-atom-todo')).not.toExist()
      #
      # # This is an activation event, triggering it causes the package to be
      # # activated.
      # atom.commands.dispatch workspaceElement, 'markdown-atom-todo:toggle'
      #
      # waitsForPromise ->
      #   activationPromise
      #
      # runs ->
      #   # Now we can test for view visibility
      #   markdownAtomTodoElement = workspaceElement.querySelector('.markdown-atom-todo')
      #   expect(markdownAtomTodoElement).toBeVisible()
      #   atom.commands.dispatch workspaceElement, 'markdown-atom-todo:toggle'
      #   expect(markdownAtomTodoElement).not.toBeVisible()
