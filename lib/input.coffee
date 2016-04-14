{Emitter, CompositeDisposable} = require 'atom'
{ElementBuilder} = require './utils'

class Input extends HTMLElement
  ElementBuilder.includeInto(this)
  mode: null
  emitter: null
  editor: null
  editorElement: null
  editorContainer: null
  panel: null
  subscriptions: null
  labelChar: ''

  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidChooseLabel: (fn) -> @emitter.on 'did-choose-label', fn
  onDidSetMode: (fn) -> @emitter.on 'did-set-mode', fn

  createdCallback: ->
    @className = 'smalls-input'
    @emitter = new Emitter
    @buildElements()
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @initialize()

  buildElements: ->
    @appendChild(
      @editorContainer = @div
        classList: ['editor-container']
    ).appendChild(
      @editorElement = @atomTextEditor
        classList: ['editor', 'smalls']
        attribute: {mini: ''}
    )

  subscribe: (disposable) ->
    @subscriptions.add(disposable)

  initialize: ->
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor.smalls.search',
      'smalls:jump': => @jump()
      'core:confirm': => @jump()

    @subscribe atom.commands.add @editorElement,
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

  cancel: ->
    @editor.setText('')
    @panel.hide()
    atom.workspace.getActivePane().activate()

  handleInput: ->
    @subscribe @editor.onWillInsertText ({text, cancel}) =>
      if @mode is 'jump'
        cancel()
        @labelChar += text
        @emitter.emit 'did-choose-label', {@labelChar}

    @subscribe @editor.onDidChange =>
      @setMode('search') if @mode is 'jump'
      @emitter.emit 'did-change', @editor.getText()

    @subscribe @editor.onDidDestroy ->
      subs.dispose()

  jump: ->
    return if @editor.isEmpty()
    @setMode('jump')

  # mode should be one of 'search' or 'jump'.
  setMode: (mode) ->
    return if mode is @mode
    @editorElement.classList.remove(@mode)
    @mode = mode
    @editorElement.classList.add(@mode)
    @emitter.emit 'did-set-mode', @mode

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'smalls-input',
  extends: 'div'
  prototype: Input.prototype
