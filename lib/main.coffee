{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'
{getView, getVisibleEditors, decorateRanges, getRangesForText} = require './utils'

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
      editorElement = getView(editor)
      for marker in markers ? []
        label = new Label().initialize({editorElement, marker})
        label.show()
        labels.push(label)

    @setLabel(@labels = labels)

  setLabel: (labels) ->
    labelChars = @getLabelChars(1)
    if labels.length > labelChars.length
      labelChars = @getLabelChars(2)

    if labels.length <= labelChars.length
      for label in labels
        label.setLabelText labelChars.shift()
        label.setFinal()
    else
      n = Math.ceil(labels.length / labelChars.length)
      _labelChars = labelChars.slice()
      labelChar = []
      _.times n, ->
        labelChars = labelChars.concat(_labelChars)

      usedCount = {}
      for label in labels
        labelText = labelChars.shift()
        label.setLabelText labelText
        usedCount[labelText] ?= 0
        usedCount[labelText] += 1

      for label in labels when usedCount[label.getLabelText()] is 1
        label.setFinal()

  getTarget: (labelChar) ->
    labelChar = labelChar.toUpperCase()
    pattern = ///^#{_.escapeRegExp(labelChar)}///
    matched = _.filter @labels, (label) ->
      label.match(pattern)

    unless matched.length
      @input.cancel()
      return

    # Since all label char lenth is same, if there is one full matched label,
    # can assume all labels are full matched.
    if _.detect(matched, (label) -> label.isFullMatch())
      if matched.length is 1
        return matched.shift()
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

  # Return array of label.
  # Label char is one char(e.g. 'A'), or two char(e.g. 'AA').
  getLabelChars: (num=1) ->
    labelChars = settings.get('labelChars').split('')
    if num is 1
      labelChars
    else if num is 2
      _labelChars = []
      for labelCharA in labelChars
        for labelCharB in labelChars
          _labelChars.push labelCharA + labelCharB
      _labelChars
