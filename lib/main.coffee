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

    @subscriptions.add atom.commands.add 'atom-text-editor.smalls.search',
      'smalls:jump': => @input.jump()

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  start: ->
    @markersByEditorID = {}
    @containers        = []
    @labelChar2target  = {}
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

    @labelChar2target = @assignLabelChar @labels
    @setLabel @labelChar2target

  # assignLabel: (targets) ->
  #   labelChars = @getLabelChars(1)
  #   if targets.length > labelChars.length
  #     labelChars = @getLabelChars(2)
  #   groups = {}
  #   for target in targets
  #     groups[labelChars.shift()] = target
  #   groups

  getLabelCharsForLabels: (labels) ->
    one = @getLabelChars(1)
    two = @getLabelChars(2)
    if labels.length <= one.length
      [L1, L2] = [one, one.slice()]
    else if labels.length <= (one.length * two.length)
      [L1, L2] = [one, two]
    else if labels.length <= (two.length * two.length)
      [L1, L2] = [two, two.slice()]
    else
      throw "need increase LabelChars"
    [L1, L2]

  assignLabelChar: (labels) ->
    [L1, L2] = @getLabelCharsForLabels(labels)
    groups = {}
    firstLabel = L1[0]
    labels = labels.slice()
    while (_labels = labels.splice(0, L2.length)).length
      group = {}
      i = 0
      while _labels[0]?
        group[L2[i]] = _labels.shift()
        i++
      groups[L1.shift()] = group

    if Object.keys(groups).length is 1
      groups = groups[firstLabel]
    groups

  setLabel: (labelChar2target, _label=false) ->
    for label, elem of labelChar2target
      if _.isElement elem
        elem.setLabelText (_label or label)
      else
        @setLabel elem, label

  getTarget: (labelChar) ->
    sufficientlabelCharLength = _.first(_.keys(@labelChar2target)).length
    labelChar = labelChar.toUpperCase()
    target = @labelChar2target[labelChar]
    if _.isElement target
      return target

    pattern = ///^#{_.escapeRegExp(labelChar)}///
    labels = []
    for label in @labels
      if pattern.test label.getLabelText()
        labels.push label
      else
        label.destroy()

    if labelChar.length >= sufficientlabelCharLength
      @input.labelChar = ''
      @labels = labels
      @labelChar2target = target
      @setLabel target
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
    @labelChar2target = {}

  getVisibleEditors: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getLabelChars: (num=1) ->
    labelChars = settings.get('labelChars').split('')
    if num is 1
      labelChars
    else if num is 2
      _labelChars = []
      for labelCharA in labelChars
        for labelCharB in labelChars
          # _labelChars.push labelCharA + labelCharB
          _labelChars.push labelCharB + labelCharA
      _labelChars
