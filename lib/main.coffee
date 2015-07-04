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
    [startRow, endRow] = editor.getVisibleRowRange()
    scanRange = new Range([startRow, 0], [endRow, Infinity])

    if markers = @markersByEditorID[editor.id]
      for marker in markers
        marker.destroy()

    markers = []
    editor.scanInBufferRange pattern, scanRange, ({range, stop}) =>
      marker = editor.markBufferRange range,
        invalidate: 'never'
        persistent: false
      markers.push marker

    for marker in markers
      editor.decorateMarker marker,
        type: 'highlight'
        class: 'smalls-candidates'

    @markersByEditorID[editor.id] = markers

  showLabel: ->
    labels = @getLabels()
    for editor in @getVisibleEditor()
      container = new Container().initialize(editor)
      editorView = atom.views.getView(editor)
      label2marker  = @getLabel2marker labels, @markersByEditorID[editor.id]
      label2target = @getLabel2Target label2marker, editorView
      for target in _.values(label2target)
        container.appendChild target

      @containers.push container
      _.extend @label2target, label2target

  getLabel2marker: (labels, markers) ->
    label2marker = {}
    for marker in markers
      break unless label = labels.shift()
      label2marker[label] = marker
    label2marker

  # [NOTE]
  # _.mapObject is different between underscore.js and underscore-plus
  # This is underscore-plus.
  getLabel2Target: (label2marker, editorView) ->
    _.mapObject label2marker, (label, marker) ->
      element = new Label()
      element.initialize {editorView, label, marker}
      [label, element]

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
