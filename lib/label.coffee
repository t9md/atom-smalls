_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  initialize: ({@editorView, @marker}) ->
    @classList.add 'smalls-label'
    @editor       = @editorView.getModel()
    labelPosition = _.capitalize settings.get('labelPosition')
    @position     = @marker["get#{labelPosition}BufferPosition"]()
    this

  setLabelText: (label) ->
    @textContent = label

  getLabelText: ->
    @textContent

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

  jump: ->
    atom.workspace.paneForItem(@editor).activate()
    if (@editor.getSelections().length is 1) and (not @editor.getLastSelection().isEmpty())
      @editor.selectToBufferPosition @position
    else
      @editor.setCursorBufferPosition @position
    @flash() if settings.get 'flashOnLand'

  attachedCallback: ->
    px          = @editorView.pixelPositionForBufferPosition @position
    top         = px.top - @editor.getScrollTop()
    left        = px.left - @editor.getScrollLeft()
    @style.top  = top + 'px'
    @style.left = left + 'px'

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
