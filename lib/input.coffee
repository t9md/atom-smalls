{CompositeDisposable} = require 'atom'
settings = require './settings'

class Input extends HTMLElement
  createdCallback: ->
    @classList.add 'smalls-input'
    @container = document.createElement 'div'
    @container.className = 'editor-container'
    @appendChild @container

  initialize: (@main) ->
    @mode = null
    @editorView = document.createElement 'atom-text-editor'
    @editorView.classList.add 'editor', 'smalls'
    @editorView.getModel().setMini true
    @editorView.setAttribute 'mini', ''
    @container.appendChild @editorView
    @editor = @editorView.getModel()
    @panel = atom.workspace.addBottomPanel item: this, visible: false

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.smalls.search',
      'smalls:jump':  => @jump()
      'core:confirm': => @jump()

    @subscriptions.add atom.commands.add @editorView,
      'core:cancel': => @cancel()
      'blur':        => @cancel()
      'click':       => @cancel()

    @handleInput()
    this

  focus: ->
    @panel.show()
    @setMode 'search'
    @editorView.focus()

  reset: ->
    @labelChar = ''

  cancel: (e) ->
    @main.clear()
    @editor.setText ''
    @panel.hide()
    atom.workspace.getActivePane().activate()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable
    subs.add @editor.onWillInsertText ({text, cancel}) =>
      if @getMode() is 'jump'
        cancel()
        @labelChar += text
        if target = @main.getTarget @labelChar
          target.jump()

    subs.add @editor.onDidChange =>
      if @getMode() is 'jump'
        @setMode 'search'
      text = @editor.getText()
      @main.search text
      jumpTriggerInputLength = settings.get 'jumpTriggerInputLength'
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @jump()

    subs.add @editor.onDidDestroy ->
      subs.dispose()

  jump: ->
    return if @editor.isEmpty()
    @setMode 'jump'

  # mode should be one of 'search' or 'jump'.
  setMode: (mode) ->
    return if mode is @mode
    if @mode?
      @editorView.classList.remove @mode
    @mode = mode
    @editorView.classList.add @mode

    switch @mode
      when 'search'
        @main.clearLabels()
        @reset()
      when 'jump'
        @main.showLabel()

  getMode: ->
    @mode

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'smalls-input',
  extends: 'div'
  prototype: Input.prototype
