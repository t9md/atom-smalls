ConfigPlus = require 'atom-config-plus'

config =
  flashOnLand:
    order: 32
    type: 'boolean'
    default: true
    description: "flash cursor line on land"
  flashDurationMilliSeconds:
    order: 33
    type: 'integer'
    default: 200
    description: "Duration for flash"
  flashColor:
    order: 34
    type: 'string'
    default: 'info'
    enum: ['info', 'success', 'warning', 'error', 'highlight', 'selected']
    description: 'flash color style, correspoinding to @background-color-#{flashColor}: see `styleguide:show`'
  flashType:
    order: 35
    type: 'string'
    default: 'line'
    enum: ['line', 'word', 'point']
    description: 'Range to be flashed'
  debug:
    order: 99
    type: 'boolean'
    default: false
    description: "Output history on console.log"
  labelChars:
    order:   101
    type:    'string'
    default: ';ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  maxInput:
    order:   102
    type:    'integer'
    default: 100
  labelPosition:
    order: 110
    type: 'string'
    default: 'start'
    enum: ['start', 'end']
  labelStyle:
    order: 111
    type: 'string'
    default: 'badge icon icon-location'
    description: "Style class for count span element. See `styleguide:show`."

# Default: badge icon icon-location
# Case-1: badge badge-error icon icon-bookmark
# Case-2: badge badge-success icon icon-light-bulb
# Case-3: btn btn-primary selected inline-block-tight
module.exports = new ConfigPlus('smalls', config)
