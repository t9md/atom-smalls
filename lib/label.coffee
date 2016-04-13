_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  initialize: ({@editorElement, @marker}) ->
    @overlayMarker = null
    @className = 'smalls-label'
    @editor = @editorElement.getModel()

    @appendChild(@char1 = document.createElement 'span')
    @appendChild(@char2 = document.createElement 'span')
    this

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

  show: ->
    labelPosition = _.capitalize settings.get('labelPosition')
    @position = @marker["get#{labelPosition}BufferPosition"]()
    @overlayMarker = @createOverlay(@position)

  createOverlay: (point) ->
    editor = @editorElement.getModel()
    marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker marker,
      type: 'overlay'
      item: this
    marker

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
    @overlayMarker?.destroy()
    @remove()

module.exports = document.registerElement 'smalls-label',
  prototype: Label.prototype
  extends:   'div'
