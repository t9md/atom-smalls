_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  initialize: ({@editorView, @marker}) ->
    @classList.add 'smalls-label'
    @editor       = @editorView.getModel()
    labelPosition = _.capitalize settings.get('labelPosition')
    @position     = @marker["get#{labelPosition}BufferPosition"]()

    @appendChild (@char1 = document.createElement 'span')
    @appendChild (@char2 = document.createElement 'span')
    this

  attachedCallback: ->
    px          = @editorView.pixelPositionForBufferPosition @position
    top         = px.top - @editor.getScrollTop()
    left        = px.left - @editor.getScrollLeft()
    @style.top  = top + 'px'
    @style.left = left + 'px'

  isFullMatch: ->
    @fullMatch

  match: (pattern) ->
    labelText = @getLabelText()
    if m = pattern.exec labelText
      # Partial match
      if m[0].length < labelText.length
        @char1.className = 'decided'
      else if m[0].length is labelText.length
        @fullMatch = true
      true
    else
      @destroy()
      false

  setLabelText: (label) ->
    @fullMatch = false
    @char1.className = ''
    [@char1.textContent, @char2.textContent] = label.split('')

  getLabelText: ->
    @textContent

  setFinal: ->
    @classList.add 'final'

  jump: ->
    atom.workspace.paneForItem(@editor).activate()
    if (@editor.getSelections().length is 1) and (not @editor.getLastSelection().isEmpty())
      @editor.selectToBufferPosition @position
    else
      @editor.setCursorBufferPosition @position
    @flash() if settings.get 'flashOnLand'

  flash: ->
    marker = @marker.copy()
    if settings.get('flashType') is 'word'
      marker.setBufferRange @editor.getLastCursor().getCurrentWordBufferRange()

    decoration = @editor.decorateMarker marker,
      type: 'highlight'
      class: 'smalls-flash'

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  destroy: ->
    @marker.destroy()
    @remove()

class Container extends HTMLElement
  initialize: (editor) ->
    @classList.add 'smalls', 'label-container'
    editorView = atom.views.getView editor
    @overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    @overlayer.appendChild this
    this

  destroy: ->
    @remove()

module.exports =
  Label: document.registerElement 'smalls-label',
    prototype: Label.prototype
    extends:   'div'
  Container: document.registerElement 'smalls-label-container',
    prototype: Container.prototype
    extends:   'div'
