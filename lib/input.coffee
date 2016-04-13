{CompositeDisposable} = require 'atom'
{ElementBuilder} = require './utils'
settings = require './settings'

class Input extends HTMLElement
  ElementBuilder.includeInto(this)

  createdCallback: ->
    @className = 'smalls-input'
    @appendChild(
      @container = @div
        classList: ['editor-container']
    ).appendChild(
      @editorElement = @atomTextEditor
        classList: ['editor', 'smalls']
        attribute: {mini: ''}
    )
    @editor = @editorElement.getModel()
    @editor.setMini(true)

  initialize: (@main) ->
    @mode = null
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.smalls.search',
      'smalls:jump': => @jump()
      'core:confirm': => @jump()

    @subscriptions.add atom.commands.add @editorElement,
      'core:cancel': => @cancel()
      'blur': => @cancel()
      'click': => @cancel()

    @handleInput()
    this

  focus: ->
    @panel.show()
    @setMode('search')
    @editorElement.focus()

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
        if label = @main.getTargetLabel(@labelChar)
          label.land()

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
      @editorElement.classList.remove @mode
    @mode = mode
    @editorElement.classList.add @mode

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
