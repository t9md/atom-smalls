## 0.2.0
- Completely rewritten
 - use native overlay marker
 - remove settings.coffee
 - extract many functions as utils.coffee
 - Input communicate with main through emitting event
 - Tweak style
 - Support lowercase char

## 0.1.9
- Fix: #2 Workaround upstream Atom bug. setting view not appear from Atom v1.4.0.
- Remove dependency to atom-config-plus module.

## 0.1.8 - Refactoring
- Update readme to follow vim-mode's rename from command-mode to normal-mode

## 0.1.7 - Refactoring
- Cleanup code.

## 0.1.6 - Style improve
- Padding, box-shadow, no-margin.

## 0.1.5 - Improve
- Refactoring.
- Doc update.
- Better labeling strategy.
- Support more than infinite label nesting(was max two level).
- Indicate partial match for two char label.
- Change label color to indicate its final choice or not.

## 0.1.4 - Improve, FIX
- [FIX] need escape RegExp
- Rename variables

## 0.1.3 - Improve
- Now can switch from jump-mode to search-mode when onDidChange when you edit text like `ctrl-h`.

## 0.1.2 - Change style
- Change style and update doc.

## 0.1.1 - Imporove
- Remove unused comment and code.
- [FIX] label clearing throw error when label nested.
## 0.1.0 - First Release
