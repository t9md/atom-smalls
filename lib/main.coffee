{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
{
  getVisibleEditors
  decorateRanges,
  getLabelChars
  getRangesForText
  getRangesForRegExp
} = require './utils'

Label = null
Input = null

getConfig = (param) ->
  atom.config.get("smalls.#{param}")

module.exports =
  activate: ->
    Label = require './label'
    Input = require './input'
    @input = new Input()

    @markersByEditor = new Map
    @labels = []

    @subscriptions = new CompositeDisposable

    @subscribe atom.commands.add 'atom-text-editor',
      'smalls:start': =>
        @input.focus()
      'smalls:start-word-jump': =>
        @input.resetLabelCharChoice()
        @showLabelForRegex(/\w+/g)
        @input.focus({mode: 'jump'})

    @subscribe @input.onDidChooseLabel ({labelChar}) =>
      @landOrUpdateLabelCharForLabels(labelChar)

    @subscribe @input.onDidChange (text) =>
      @clearAllMarkers()
      return unless text
      @search(text)
      jumpTriggerInputLength = getConfig('jumpTriggerInputLength')
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @input.jump()

    @subscribe @input.onDidSetMode (mode) =>
      switch mode
        when 'search'
          @input.resetLabelCharChoice()
          @clearLabels()
        when 'jump'
          @showLabels()

  showLabelForRegex: (pattern) ->
    for editor in getVisibleEditors()
      markers = getRangesForRegExp(editor, pattern).map (range) ->
        editor.markBufferRange(range)
      if markers.length
        @markersByEditor.set(editor, markers)

  subscribe: (disposable) ->
    @subscriptions.add(disposable)

  deactivate: ->
    @clear()
    @subscriptions.dispose()

  land: (label) ->
    editor = label.editor
    atom.workspace.paneForItem(editor).activate()
    point = label.getPosition()
    if (editor.getSelections().length is 1) and (not editor.getLastSelection().isEmpty())
      editor.selectToBufferPosition(point)
    else
      editor.setCursorBufferPosition(point)

    label.flash(getConfig('flashType')) if getConfig('flashOnLand')

  clearAllMarkers: ->
    @markersByEditor.forEach (markers) ->
      marker.destroy() for marker in markers
    @markersByEditor.clear()

  search: (text) ->
    for editor in getVisibleEditors()
      markers = decorateRanges(editor, getRangesForText(editor, text))
      if markers.length
        @markersByEditor.set(editor, markers)

  showLabels: ->
    labels = []
    @markersByEditor.forEach (markers, editor) ->
      startColumn = editor.getFirstVisibleScreenColumn()
      endColumn = startColumn + editor.getEditorWidthInChars()
      visibleColumns = [startColumn..endColumn]
      filterMarkers = (markers) ->
        markers.filter (marker) ->
          {start, end} = marker.getScreenRange()
          (start.column in visibleColumns) or (end.column in visibleColumns)

      for marker in filterMarkers(markers)
        labels.push(new Label().initialize({editor, marker}))
    @setLabelCharToLabels(labels)

  setLabelCharToLabels: (@labels) ->
    labelChars = getLabelChars(amount: @labels.length, chars: getConfig('labelChars'))
    usedCountByText = _.countBy(labelChars, (text) -> text)

    labelPosition = getConfig('labelPosition')
    for [label, text] in _.zip(@labels, labelChars)
      usedCount = usedCountByText[text]
      label.setLabelText(text, {usedCount, labelPosition})

  landOrUpdateLabelCharForLabels: (labelChar) ->
    labelCharInLowerCase = labelChar.toLowerCase()
    [matched, unMatched] = _.partition @labels, (label) ->
      label.getText().toLowerCase().startsWith(labelCharInLowerCase)

    unless matched.length
      @input.labelChar = @input.oldLabelChar
      return

    label.destroy() for label in unMatched

    if matched.length is 1
      @land(matched[0])
    else
      if labelChar.length is matched[0].getText().length
        @input.resetLabelCharChoice()
        @setLabelCharToLabels(matched)
      else
        matched.forEach (label) -> label.char1.className = 'decided'

      null

  clearLabels: ->
    label.destroy() for label in @labels
    @labels = []

  clear: ->
    @clearLabels()
    @clearAllMarkers()
