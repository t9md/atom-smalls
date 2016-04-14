_ = require 'underscore-plus'
settings = require './settings'

class Label extends HTMLElement
  editor: null
  editorElement: null
  marker: null
  char1: null
  char2: null

  initialize: ({@editor, @marker}) ->
    @className = 'smalls-label'
    @editorElement = atom.views.getView(@editor)

    @appendChild(@char1 = document.createElement('span'))
    @appendChild(@char2 = document.createElement('span'))
    this

  setLabelText: (label, usedCount) ->
    @classList.toggle('not-final', usedCount > 1)
    @char1.className = ''
    [@char1.textContent, @char2.textContent] = label.split('')

  getText: ->
    @textContent

  show: ->
    point = @marker.getBufferRange()[settings.get('labelPosition')]
    @editor.decorateMarker(@marker, {type: 'overlay', position: 'tail', item: this})

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
    @remove()

module.exports = document.registerElement 'smalls-label',
  prototype: Label.prototype
  extends:   'div'
