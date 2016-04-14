{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'
{getVisibleEditors, decorateRanges, getRangesForText} = require './utils'

Label = null
Input = null

module.exports =
  activate: ->
    Label = require './label'
    Input = require './input'
    @input = new Input().initialize(this)

    @markersByEditor = new Map
    @labels = []

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'smalls:start': => @input.focus()

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  clearAllMarkers: ->
    @markersByEditor.forEach (markers) ->
      marker.destroy() for marker in markers
    @markersByEditor.clear()

  search: (text) ->
    @clearAllMarkers()
    return unless text
    for editor in getVisibleEditors()
      ranges = getRangesForText(editor, text)
      if (markers = decorateRanges(editor, ranges)).length
        @markersByEditor.set(editor, markers)

  showLabel: ->
    labels = []
    @markersByEditor.forEach (markers, editor) ->
      for marker in markers ? []
        label = new Label().initialize({editor, marker})
        label.show()
        labels.push(label)
    @setLabelChar(labels)

  # Return enough amount of label chars to show specified amount of label.
  # Label char is one char(e.g. 'A'), or two char(e.g. 'AA').
  getLabelChars: (amount) ->
    labelChars = settings.get('labelChars').split('')
    if amount <= labelChars.length # one char label
      labelChars[0...amount]
    else # two char label
      _labels = []
      for a in labelChars
        for b in labelChars
          _labels.push(a + b)
      layers = Math.ceil(amount / _labels.length)
      _.flatten([1..layers].map -> _labels)[0...amount]

  setLabelChar: (@labels) ->
    labelChars = @getLabelChars(@labels.length)
    usedCount = _.countBy(labelChars.slice(), (text) -> text)
    for label in @labels
      text = labelChars.shift()
      label.setLabelText(text, usedCount[text])

  findLabel: (labelChar) ->
    [matched, unMatched] = _.partition @labels, (label) ->
      label.getText().startsWith(labelChar)

    label.destroy() for label in unMatched

    fullMatched = []
    for label in matched
      labelText = label.getText()
      if labelChar.length < labelText.length
        label.char1.className = 'decided'
      else
        fullMatched.push(label)

    if fullMatched.length > 0
      if fullMatched.length is 1
        return fullMatched.shift()
      else
        @input.reset()
        @setLabelChar(fullMatched)
    null

  clearLabels: ->
    label.destroy() for label in @labels
    @labels = []

  clear: ->
    @clearLabels()
    @clearAllMarkers()
