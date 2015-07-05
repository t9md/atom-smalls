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

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'smalls:start': => @start()
      'smalls:dump':  => @dump()

    @subscriptions.add atom.commands.add 'atom-text-editor.smalls',
      'smalls:jump': => @getInput()?.startJumpMode()

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  getInput: ->
    @input

  start: ->
    @markersByEditorID = {}
    @containers        = []
    @label2target      = {}
    @input ?= new Input().initialize(this)
    @input.focus()

  dump: ->
    console.log @markersByEditorID

  search: (text) ->
    pattern = ///#{_.escapeRegExp(text)}///ig
    for editor in @getVisibleEditor()
      @clearDecoration editor
      if text isnt ''
        @decorate editor, pattern

  clearDecoration: (editor) ->
    if markers = @markersByEditorID[editor.id]
      for marker in markers
        marker.destroy()

  decorate: (editor, pattern) ->
    [startRow, endRow] = editor.getVisibleRowRange().map (row) ->
      editor.bufferRowForScreenRow(row)
    scanRange = new Range([startRow, 0], [endRow, Infinity])

    markers = []
    @scan editor, pattern, (range) =>
      marker = editor.markScreenRange range,
        invalidate: 'never'
        persistent: false
      markers.push marker

    for marker in markers
      editor.decorateMarker marker,
        type: 'highlight'
        class: 'smalls-candidates'

    @markersByEditorID[editor.id] = markers

  scan: (editor, pattern, callback) ->
    [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
    for row in [firstVisibleRow...lastVisibleRow]
      if editor.isFoldedAtScreenRow(row)
        continue
        # callback new Range(new Point(row, 0), new Point(row, 0))
      lineText = editor.lineTextForScreenRow row
      while match = pattern.exec lineText
        start = [row, match.index]
        end = [row, match.index + match[0].length]
        callback [start, end]

  # collectPoints: (editor, pattern) ->
  #   points = []
  #   [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
  #   for row in [firstVisibleRow...lastVisibleRow]
  #     if editor.isFoldedAtScreenRow(row)
  #       callback new Range(new Point(row, 0), new Point(row, 0))
  #       # points.push
  #     else
  #       lineContents = editor.lineTextForScreenRow row
  #       while match = pattern.exec(lineContents)
  #         points.push new Point(row, match.index)
  #   points
  #
  showLabel: ->
    labels = @getLabels()
    @labelElements = []
    for editor in @getVisibleEditor()
      container = new Container().initialize(editor)
      editorView = atom.views.getView(editor)
      for marker in @markersByEditorID[editor.id]
        labelElement = new Label().initialize {editorView, marker}
        container.appendChild labelElement
        @labelElements.push labelElement
      @containers.push container

    @label2target = @assignLabel labels, @labelElements
    @setLabel @label2target

  getTarget: (label) ->
    label = label.toUpperCase()
    return unless target = @label2target[label]
    if _.isElement target
      target.jump()
      @clear()
    else
      for elem in @labelElements when elem.textContent isnt label
        elem.destroy()
      @label2target = target
      @setLabel target

  setLabel: (label2target, _label=false) ->
    for label, elem of label2target
      if _.isElement elem
        elem.textContent = (_label or label)
      else
        @setLabel  elem, label

  assignLabel: (labels, targets) ->
    groups = {}
    firstLabel = labels[0]
    targets = targets.slice()
    _labels = @getLabels()
    while (_targets = targets.splice(0, _labels.length)).length
      group = {}
      i = 0
      while _targets[0]?
        group[_labels[i]] = _targets.shift()
        i++
      groups[labels.shift()] = group

    if Object.keys(groups).length is 1
      groups = groups[firstLabel]
    groups

  # Others
  # -------------------------
  clear: ->
    for editor in @getVisibleEditor()
      @clearDecoration editor

    for label, element of @label2target
      element.remove()
    @label2target = null
    for container in @containers
      container.destroy()
    @containers = []

  # Utility
  # -------------------------
  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getLabels: ->
    settings.get('labelChars').split('')
