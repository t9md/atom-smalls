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

  # Return enough amount of label chars to show amount
  # Label char is one char(e.g. 'A'), or two char(e.g. 'AA').
  getLabelChars: (amount) ->
    labelChars = settings.get('labelChars').split('')
    if amount <= labelChars.length
      # one char label
      labelChars
    else
      # two char label
      _labels = []
      for a in labelChars
        for b in labelChars
          _labels.push(a + b)
      layers = Math.ceil(amount / _labels.length)
      _.flatten([1..layers].map -> _labels)

  setLabelChar: (@labels) ->
    labelChars = @getLabelChars(@labels.length)
    usedCount = {}
    for label in @labels
      labelText = labelChars.shift()
      label.setLabelText(labelText)
      usedCount[labelText] ?= 0
      usedCount[labelText] += 1

    for label in labels when usedCount[label.getLabelText()] is 1
      label.setFinal()

  getTargetLabel: (labelChar) ->
    labelChar = labelChar.toUpperCase()
    pattern = ///^#{_.escapeRegExp(labelChar)}///
    matched = _.filter @labels, (label) ->
      label.match(pattern)

    unless matched.length
      @input.cancel()
      return

    if _.detect(matched, (label) -> label.isFullMatch())
      if matched.length is 1
        return(matched.shift())
      else
        @input.reset()
        @setLabel(@labels = matched)
    null

  clearLabels: ->
    label.destroy() for label in @labels
    @labels = []

  clear: ->
    @clearLabels()
    @clearAllMarkers()
