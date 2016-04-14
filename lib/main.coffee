{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
{
  getVisibleEditors, decorateRanges, getRangesForText, getLabelChars
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

    @subscribe @input.onDidChooseLabel ({labelChar}) =>
      if label = @findLabel(labelChar)
        label.land()
        if getConfig('flashOnLand')
          label.flash(getConfig('flashType'))

    @subscribe @input.onDidChange (text) =>
      @search(text)
      jumpTriggerInputLength = getConfig('jumpTriggerInputLength')
      if jumpTriggerInputLength and (text.length >= jumpTriggerInputLength)
        @jump()

    @subscribe @input.onDidSetMode (mode) =>
      switch mode
        when 'search'
          @input.reset()
          @clearLabels()
        when 'jump'
          @showLabel()

  subscribe: (disposable) ->
    @subscriptions.add(disposable)

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
      for marker in markers
        labels.push(new Label().initialize({editor, marker}))
    @setLabelChar(labels)

  setLabelChar: (@labels) ->
    amount = @labels.length
    chars = getConfig('labelChars')
    labelChars = getLabelChars({amount, chars})
    usedCount = _.countBy(labelChars.slice(), (text) -> text)

    labelPosition = getConfig('labelPosition')
    for [label, text] in _.zip(@labels, labelChars)
      label.setLabelText(text, {usedCount: usedCount[text], labelPosition})

  findLabel: (input) ->
    [matched, unMatched] = _.partition @labels, (label) ->
      label.getText().toLowerCase().startsWith(input.toLowerCase())

    label.destroy() for label in unMatched

    if matched.length
      if matched[0].getText().length is input.length
        if matched.length is 1
          return matched[0]
        else
          @input.reset()
          @setLabelChar(matched)
      else
        matched.forEach (label) -> label.char1.className = 'decided'
    null

  clearLabels: ->
    label.destroy() for label in @labels
    @labels = []

  clear: ->
    @clearLabels()
    @clearAllMarkers()
