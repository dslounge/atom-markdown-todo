module.exports =
class MarkdownAtomTodoView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('markdown-atom-todo')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The MarkdownAtomTodo package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  setCount: (words) ->
    @element.textContent = "The word count is " + words
