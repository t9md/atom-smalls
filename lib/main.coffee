{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

Label = null
Container = null
Input = null

module.exports =
  config: settings.config

  activate: ->
    {Label, Container} = require './label'
    Input = require './input'

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'smalls:start': => @start()
      'smalls:dump': => @dump()

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  dump: ->
    console.log @markersByEditorID

  start: ->
    @markersByEditorID = {}
    @containers        = []
    @label2target      = {}
    input = new Input()
    input.initialize(this)

  highlight: (text) ->
    pattern = ///#{_.escapeRegExp(text)}///ig
    for editor in @getVisibleEditor()
      @decorate editor, pattern

  decorate: (editor, pattern) ->
    [startRow, endRow] = editor.getVisibleRowRange().map (row) ->
      editor.bufferRowForScreenRow(row)
    scanRange = new Range([startRow, 0], [endRow, Infinity])

    if markers = @markersByEditorID[editor.id]
      for marker in markers
        marker.destroy()

    markers = []
    @scan editor, pattern, (range) =>
      # marker = editor.markBufferRange range,
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
      lineContents = editor.lineTextForScreenRow row
      while match = pattern.exec(lineContents)
        start = [row, match.index]
        end = [row, match.index + match[0].length]
        callback new Range(start, end)

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
    for editorID, markers of @markersByEditorID
      for marker in markers
        marker.destroy()

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
