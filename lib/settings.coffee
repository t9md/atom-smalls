ConfigPlus = require 'atom-config-plus'

config =
  labelChars:
    order:   1
    type:    'string'
    default: ';ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  labelPosition:
    order:   3
    type:    'string'
    default: 'start'
    enum:    ['start', 'end']
  jumpTriggerInputLength:
    order:       3
    type:        'integer'
    default:     100
    description: "If input exceed this length, automatically start jump mode"
  # labelStyle:
  #   order:       111
  #   type:        'string'
  #   default:     'badge icon icon-location'
  #   description: "Style class for count span element. See `styleguide:show`."
  flashOnLand:
    order:       32
    type:        'boolean'
    default:     true
    description: "flash effect on land"
  flashType:
    order:       35
    type:        'string'
    default:     'match'
    enum:        ['match', 'word']
    description: 'Range to be flashed'

# Default: badge icon icon-location
# Case-1: badge badge-error icon icon-bookmark
# Case-2: badge badge-success icon icon-light-bulb
# Case-3: btn btn-primary selected inline-block-tight
module.exports = new ConfigPlus('smalls', config)
