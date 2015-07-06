{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

Label     = null
Container = null
Input     = null

module.exports =
  config: settings.config

  activate: ->
    {Label, Container} = require './label'
    Input = require './input'
    @input = new Input()
    @input.initialize(this)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'smalls:start': => @start()

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  start: ->
    @markersByEditorID = {}
    @containers        = []
    @labels            = []
    @input.focus()

  search: (text) ->
    pattern = ///#{_.escapeRegExp(text)}///ig
    for editor in @getVisibleEditors()
      @clearDecorations editor
      if text isnt ''
        @decorate editor, pattern

  clearDecorations: (editor) ->
    if markers = @markersByEditorID[editor.id]
      for marker in markers
        marker.destroy()

  decorate: (editor, pattern) ->
    @markersByEditorID[editor.id] = markers = []
    @scan editor, pattern, (range) ->
      marker = editor.markScreenRange range,
        invalidate: 'never'
        persistent: false

      editor.decorateMarker marker,
        type: 'highlight'
        class: 'smalls-candidate'

      markers.push marker

  scan: (editor, pattern, callback) ->
    [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
    for row in [firstVisibleRow..lastVisibleRow]
      # Skip folded line.
      continue if editor.isFoldedAtScreenRow(row)

      lineText = editor.lineTextForScreenRow row
      while match = pattern.exec lineText
        start = [row, match.index]
        end   = [row, match.index + match[0].length]
        callback [start, end]

  showLabel: ->
    @labels = []
    for editor in @getVisibleEditors()
      container = new Container()
      container.initialize editor
      @containers.push container
      editorView = atom.views.getView editor
      markers = @markersByEditorID[editor.id]
      for marker in markers
        label = new Label()
        label.initialize {editorView, marker}
        container.appendChild label
        @labels.push label

    @setLabel @labels

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
      _labelChars = []
      _.times n, ->
        _labelChars = _labelChars.concat(labelChars)
      labelChars = _labelChars

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
    for label in @labels
      label.destroy()
    @labels = []

  clear: ->
    @clearLabels()
    for container in @containers
      container.destroy()
    @labels = []
    @containers = []

  getVisibleEditors: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

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
