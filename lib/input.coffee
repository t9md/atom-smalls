{CompositeDisposable} = require 'atom'
settings = require './settings'
class Input extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
    @classList.add 'smalls-input'
    @editorContainer = document.createElement('div')
    @editorContainer.className = 'editor-container'
    @appendChild @editorContainer

  initialize: (@main) ->
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.getModel().setMini(true)
    @editorElement.setAttribute('mini', '')
    @editorContainer.appendChild @editorElement
    @editor = @editorElement.getModel()

    @defaultText = ''
    @hideOtherBottomPanels()
    @panel = atom.workspace.addBottomPanel item: this
    @editorElement.focus()
    atom.commands.add @editorElement, 'core:confirm', @confirm.bind(this)
    atom.commands.add @editorElement, 'core:cancel' , @cancel.bind(this)
    atom.commands.add @editorElement, 'blur'        , @cancel.bind(this)
    @handleJump()
    this

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
    @remove()

  handleJump: ->
    @jumpMode = false
    @subscriptions = new CompositeDisposable

    @subscriptions.add @editor.onWillInsertText ({text, cancel}) =>
      if @jumpMode
        cancel()
        if target = @main.label2target[text.toUpperCase()]
          target.jump()
          @main.clear()
      else
        if text is ';'
          cancel()
          @confirm()

    @subscriptions.add @editor.onDidChange ({newText}) =>
      @main.highlight @editor.getText()
      if @editor.getText().length >= settings.get('maxInput')
        @jumpMode = true

    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

  confirm: ->
    @jumpMode = true
    @main.showLabel()

  cancel: (e) ->
    @main.clear()
    @showOtherBottomPanels()
    @removePanel()

  removePanel: ->
    atom.workspace.getActivePane().activate()
    @panel.destroy()

module.exports =
document.registerElement 'smalls-input',
  extends: 'div'
  prototype: Input.prototype
