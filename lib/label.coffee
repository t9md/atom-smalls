_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  editor: null
  editorElement: null
  marker: null
  overlayMarker: null
  fullMatch: false
  char1: null
  char2: null

  initialize: ({@editor, @marker}) ->
    @className = 'smalls-label'
    @editorElement = atom.views.getView(@editor)
    @overlayMarker = null

    @appendChild(@char1 = document.createElement 'span')
    @appendChild(@char2 = document.createElement 'span')
    this

  isFullMatch: ->
    @fullMatch

  match: (pattern) ->
    labelText = @getLabelText()
    if match = pattern.exec(labelText)
      if match[0].length < labelText.length
        @char1.className = 'decided'
      else if match[0].length is labelText.length
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
    @classList.add('final')

  show: ->
    point = @marker.getBufferRange()[settings.get('labelPosition')]
    @overlayMarker = @createOverlay(point)

  createOverlay: (point) ->
    marker = @editor.markBufferPosition(point, {invalidate: "never", persistent: false})
    @editor.decorateMarker(marker, {type: 'overlay', item: this})
    marker

  land: ->
    atom.workspace.paneForItem(@editor).activate()
    point = @marker.getStartBufferPosition()
    if (@editor.getSelections().length is 1) and (not @editor.getLastSelection().isEmpty())
      @editor.selectToBufferPosition(point)
    else
      @editor.setCursorBufferPosition(point)
    if settings.get('flashOnLand')
      @flash()

  flash: ->
    marker = @marker.copy()
    if settings.get('flashType') is 'word'
      range = @editor.getLastCursor().getCurrentWordBufferRange()
      marker.setBufferRange(range)

    @editor.decorateMarker(marker, {type: 'highlight', class: 'smalls-flash'})
    setTimeout  ->
      marker.destroy()
    , 150

  destroy: ->
    @marker.destroy()
    @overlayMarker?.destroy()

    #   @editor, @editorElement, @marker, @overlayMarker, @fullMatch
    #   @char1, @char2
    # } = {}
    @remove()

module.exports = document.registerElement 'smalls-label',
  prototype: Label.prototype
  extends:   'div'
