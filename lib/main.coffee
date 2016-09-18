{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
{
  getVisibleEditors
  decorateRanges
  getLabelChars
  getRangesForWord
  getRangesForText
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
      'smalls:start': => @input.focus()

    @subscribe atom.commands.add 'atom-text-editor',
      'smalls:jump-word': => @input.focusWord()

    @subscribe @input.onDidChooseLabel ({labelChar}) =>
      @landOrUpdateLabelCharForLabels(labelChar)

    @subscribe @input.onDidChange (text) =>
      @search(text)
      jumpTriggerInputLength = getConfig('jumpTriggerInputLength')
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @input.jump()

    @subscribe @input.onDidSetMode (mode) =>
      switch mode
        when 'search'
          @input.resetLabelCharChoice()
          @clearLabels()
        when 'searchword'
          @input.resetLabelCharChoice()
          @clearLabels()
          @searchWord()
        when 'jump'
          @showLabels()

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
    @clearAllMarkers()
    return unless text
    for editor in getVisibleEditors()
      markers = decorateRanges(editor, getRangesForText(editor, text))
      if markers.length
        @markersByEditor.set(editor, markers)

  searchWord: ->
    @clearAllMarkers()
    for editor in getVisibleEditors()
      markers = decorateRanges(editor, getRangesForWord(editor))
      if markers.length
        @markersByEditor.set(editor, markers)

  showLabels: ->
    labels = []
    @markersByEditor.forEach (markers, editor) ->
      for marker in markers
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
    matched = @labels.filter (label) ->
      if label.getText().toLowerCase().startsWith(labelCharInLowerCase)
        true
      else
        label.destroy()
        false

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
