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
    @label2target      = {}
    @labels            = []
    @input.focus()

  search: (text) ->
    pattern = ///#{text}///ig
    for editor in @getVisibleEditors()
      @clearDecorations editor
      if text isnt ''
        @decorate editor, pattern

  clearDecorations: (editor) ->
    if markers = @markersByEditorID[editor.id]
      for marker in markers
        marker.destroy()

  decorate: (editor, pattern) ->
    markers = []
    @scan editor, pattern, (range) =>
      markers.push editor.markScreenRange range,
        invalidate: 'never'
        persistent: false

    for marker in markers
      editor.decorateMarker marker,
        type: 'highlight'
        class: 'smalls-candidate'

    @markersByEditorID[editor.id] = markers

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

    @label2target = @assignLabel @getLabelChars(), @labels
    @setLabel @label2target

  assignLabel: (labelChars, targets) ->
    groups = {}
    firstLabel = labelChars[0]
    targets = targets.slice()
    _labelChars = @getLabelChars()
    while (_targets = targets.splice(0, _labelChars.length)).length
      group = {}
      i = 0
      while _targets[0]?
        group[_labelChars[i]] = _targets.shift()
        i++
      groups[labelChars.shift()] = group

    if Object.keys(groups).length is 1
      groups = groups[firstLabel]
    groups

  setLabel: (label2target, _label=false) ->
    for label, elem of label2target
      if _.isElement elem
        elem.setLabelText (_label or label)
      else
        @setLabel elem, label

  getTarget: (label) ->
    label = label.toUpperCase()
    target = @label2target[label]
    return unless target
    if _.isElement target
      target.jump()
      @clear()
    else
      for elem in @labels when elem.getLabelText() isnt label
        elem.destroy()
      @label2target = target
      @setLabel target

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
    @label2target = {}

  getVisibleEditors: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getLabelChars: ->
    settings.get('labelChars').split('')
