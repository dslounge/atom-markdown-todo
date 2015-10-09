MarkdownAtomTodoView = require './markdown-atom-todo-view'
{CompositeDisposable} = require 'atom'

module.exports = MarkdownAtomTodo =
  markdownAtomTodoView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @markdownAtomTodoView = new MarkdownAtomTodoView(state.markdownAtomTodoViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @markdownAtomTodoView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-atom-todo:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @markdownAtomTodoView.destroy()

  serialize: ->
    markdownAtomTodoViewState: @markdownAtomTodoView.serialize()

  toggle: ->
    console.log 'MarkdownAtomTodo was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
