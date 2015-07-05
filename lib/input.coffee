{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

class Input extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
    @classList.add 'smalls-input'
    @container = document.createElement('div')
    @container.className = 'editor-container'
    @appendChild @container

  initialize: (@main) ->
    @mode = null
    @editorView = document.createElement 'atom-text-editor'
    @editorView.classList.add('editor', 'smalls')
    @editorView.getModel().setMini(true)
    @editorView.setAttribute('mini', '')
    @container.appendChild @editorView
    @editor = @editorView.getModel()

    @panel = atom.workspace.addBottomPanel item: this, visible: false
    atom.commands.add @editorView, 'core:confirm', @startJumpMode.bind(this)
    atom.commands.add @editorView, 'core:cancel' , @cancel.bind(this)
    atom.commands.add @editorView, 'blur'        , @cancel.bind(this)
    @handleInput()
    this

  focus: ->
    @hideOtherBottomPanels()
    @panel.show()
    @editorView.focus()
    @setMode 'search'

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
    @remove()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable

    subs.add @editor.onWillInsertText ({text, cancel}) =>
      if @getMode() is 'jump'
        cancel()
        @main.getTarget text

    subs.add @editor.onDidChange =>
      text = @editor.getText()
      @main.search text
      jumpTriggerInputLength = settings.get 'jumpTriggerInputLength'
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @startJumpMode()

    subs.add @editor.onDidDestroy =>
      @subscriptions.dispose()

  startJumpMode: ->
    return if @editor.isEmpty()
    @setMode 'jump'
    @main.showLabel()

  cancel: (e) ->
    @main.clear()
    @editor.setText ''
    @showOtherBottomPanels()
    atom.workspace.getActivePane().activate()
    @panel.hide()

module.exports =
document.registerElement 'smalls-input',
  extends: 'div'
  prototype: Input.prototype
