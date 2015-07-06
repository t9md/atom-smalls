{CompositeDisposable} = require 'atom'
settings = require './settings'

class Input extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
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

    atom.commands.add @editorView,
      'core:confirm': => @jump()
      'core:cancel':  => @cancel()
      'blur':         => @cancel()

    @handleInput()
    this

  focus: ->
    @hideOtherBottomPanels()
    @panel.show()
    @setMode 'search'
    @labelChar = ''
    @editorView.focus()

  cancel: (e) ->
    @main.clear()
    @editor.setText ''
    @panel.hide()
    @showOtherBottomPanels()
    atom.workspace.getActivePane().activate()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable
    subs.add @editor.onWillInsertText ({text, cancel}) =>
      if @getMode() is 'jump'
        cancel()
        @labelChar += text
        if target = @main.getTarget @labelChar
          target.jump()
          @labelChar = ''

    subs.add @editor.onDidChange =>
      if @getMode() is 'jump'
        labelChar = ''
        @main.clearLabels()
        @setMode 'search'
      text = @editor.getText()
      @main.search text
      jumpTriggerInputLength = settings.get 'jumpTriggerInputLength'
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @jump()

    subs.add @editor.onDidDestroy =>
      subs.dispose()

  jump: ->
    return if @editor.isEmpty()
    @setMode 'jump'
    @main.showLabel()

  # mode should be one of 'search' or 'jump'.
  setMode: (mode) ->
    if @mode?
      @editorView.classList.remove @mode
    @mode = mode
    @editorView.classList.add @mode

  getMode: ->
    @mode

  hideOtherBottomPanels: ->
    @hiddenPanels = []
    for panel in atom.workspace.getBottomPanels()
      if panel.isVisible()
        panel.hide()
        @hiddenPanels.push panel

  showOtherBottomPanels: ->
    panel.show() for panel in @hiddenPanels
    @hiddenPanels = []

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'smalls-input',
  extends: 'div'
  prototype: Input.prototype
