{Range} = require 'atom'
_ = require 'underscore-plus'

getVisibleEditorRange = (editor) ->
  [startRow, endRow] = editor.element.getVisibleRowRange()
  return null unless (startRow? and endRow?)
  startRow = editor.bufferRowForScreenRow(startRow)
  endRow = Math.max(0, endRow - 10)
  endRow = editor.bufferRowForScreenRow(endRow)
  new Range([startRow, 0], [endRow, Infinity])

getRangesForText = (editor, text) ->
  getRangesForRegExp(editor, ///#{_.escapeRegExp(text)}///ig)

getRangesForRegExp = (editor, pattern) ->
  ranges = []
  scanRange = getVisibleEditorRange(editor)
  console.log scanRange.toString()
  editor.scanInBufferRange pattern, scanRange, ({range}) ->
    ranges.push(range)
  ranges

decorateRanges = (editor, ranges) ->
  markers = []
  decorationOptions = {type: 'highlight', class: 'smalls-candidate'}
  for range in ranges ? []
    marker = editor.markBufferRange(range)
    markers.push(marker)
    editor.decorateMarker(marker, decorationOptions)
  markers

getVisibleEditors = ->
  atom.workspace.getPanes()
    .map (pane) -> pane.getActiveEditor()
    .filter (editor) -> editor?

ElementBuilder =
  includeInto: (target) ->
    for name, value of this when name isnt "includeInto"
      target::[name] = value.bind(this)

  div: (params) ->
    @createElement 'div', params

  span: (params) ->
    @createElement 'span', params

  atomTextEditor: (params) ->
    @createElement 'atom-text-editor', params

  createElement: (element, {classList, textContent, id, attribute}) ->
    element = document.createElement(element)

    element.id = id if id?
    element.classList.add classList... if classList?
    element.textContent = textContent if textContent?
    for name, value of attribute ? {}
      element.setAttribute(name, value)
    element

# Return enough amount of label chars to show specified amount of label.
# Label char is one char(e.g. 'A'), or two char(e.g. 'AA').
getLabelChars = ({amount, chars}) ->
  labels = chars.split('')
  if amount <= labels.length # one char label
    labels[0...amount]
  else # two char label
    _labels = []
    for a in labels
      for b in labels
        _labels.push(a + b)
    repeatCount = Math.ceil(amount / _labels.length)
    _.flatten([1..repeatCount].map -> _labels)[0...amount]

module.exports = {
  getRangesForText
  getRangesForRegExp
  decorateRanges
  ElementBuilder
  getVisibleEditorRange
  getVisibleEditors
  getLabelChars
}
