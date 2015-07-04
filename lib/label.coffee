_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  initialize: ({@editorView, label, @marker}) ->
    @classList.add 'smalls', 'label'
    @classList.add 'inline-block', 'highlight-info'
    @textContent = label
    @editor      = @editorView.getModel()
    labelPosition = _.capitalize settings.get('labelPosition')
    @position = @marker["get#{labelPosition}BufferPosition"]()
    this

  flash: ->
    decoration = @editor.decorateMarker @marker.copy(),
      type: 'highlight'
      class: "smalls-flash"

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  jump: ->
    atom.workspace.paneForItem(@editor).activate()
    if (@editor.getSelections().length is 1) and (not @editor.getLastSelection().isEmpty())
      @editor.selectToScreenPosition @position
    else
      @editor.setCursorScreenPosition @position

    if settings.get('flashOnLand')
      @flash()

  attachedCallback: ->
    px = @editorView.pixelPositionForScreenPosition @position
    scrollLeft = @editor.getScrollLeft()
    scrollTop  = @editor.getScrollTop()
    @style.left  = "#{px.left - scrollLeft}px"
    @style.top   = "#{px.top - scrollTop}px"

  destroy: ->
    @marker.destroy()
    @remove()

class Container extends HTMLElement
  initialize: (editor) ->
    @classList.add "smalls", "smalls-label-container"
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
