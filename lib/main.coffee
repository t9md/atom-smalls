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

    @subscriptions.add atom.commands.add 'atom-text-editor.smalls.search',
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
    @labels            = []

    @input ?= new Input().initialize(this)
    @input.focus()

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
    markers = []
    @scan editor, pattern, (range) =>
      markers.push editor.markScreenRange range,
        invalidate: 'never'
        persistent: false

    for marker in markers
      editor.decorateMarker marker,
        type: 'highlight'
        class: 'smalls-candidates'

    @markersByEditorID[editor.id] = markers

  scan: (editor, pattern, callback) ->
    [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
    for row in [firstVisibleRow..lastVisibleRow]
      continue if editor.isFoldedAtScreenRow(row)
      lineText = editor.lineTextForScreenRow row
      while match = pattern.exec lineText
        start = [row, match.index]
        end   = [row, match.index + match[0].length]
        callback [start, end]

  showLabel: ->
    @labels = []
    for editor in @getVisibleEditor()
      container = new Container()
      container.initialize(editor)
      @containers.push container

      editorView = atom.views.getView(editor)
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
    return unless target = @label2target[label]
    if _.isElement target
      target.jump()
      @clear()
    else
      for elem in @labels when elem.getLabelText() isnt label
        elem.destroy()
      @label2target = target
      @setLabel target

  clear: ->
    label.destroy() for label in @labels
    container.destroy() for container in @containers

    @labels = []
    @containers = []
    @label2target = {}

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getLabelChars: ->
    settings.get('labelChars').split('')
