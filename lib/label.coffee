_ = require 'underscore-plus'

class Label extends HTMLElement
  editor: null
  editorElement: null
  marker: null
  char1: null
  char2: null

  initialize: ({@editor, @marker}) ->
    @className = 'smalls-label'
    @editorElement = @editor.element

    @appendChild(@char1 = document.createElement('span'))
    @appendChild(@char2 = document.createElement('span'))
    this

  setLabelText: (label, {usedCount, labelPosition}) ->
    @classList.toggle('not-final', usedCount > 1)
    @char1.className = ''
    [@char1.textContent, @char2.textContent] = label.split('')

    unless @displayed
      point = @marker.getBufferRange()[labelPosition]
      @editor.decorateMarker(@marker, {type: 'overlay', position: 'tail', item: this})
      @displayed = true

  getText: ->
    @textContent # is @char1.textContent + @char2.textContent

  getPosition: ->
    @marker.getStartBufferPosition()

  flash: (type) ->
    marker = @marker.copy()
    if type is 'word'
      range = @editor.getLastCursor().getCurrentWordBufferRange()
      marker.setBufferRange(range)

    @editor.decorateMarker(marker, type: 'highlight', class: 'smalls-flash')
    setTimeout  ->
      marker.destroy()
    , 150

  destroy: ->
    @marker.destroy()
    @remove()

module.exports = document.registerElement 'smalls-label',
  prototype: Label.prototype
  extends: 'div'
