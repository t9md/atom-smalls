# smalls

Rapid cursor positioning across any visible chars with search and jump.

![gif](https://raw.githubusercontent.com/t9md/t9md/9e2b924427829d0264841dbf211858629dd0e7d3/img/atom-smalls.gif)

# Features

* Search and jump to position across visible panes.
* Flashing cursor position on landing(enbaled by default).
* Automatically start jump-mode with configured input length(disabled by default).
* [easymotion](https://github.com/easymotion/vim-easymotion) style label jump.
* Port of my [vim-smalls](https://github.com/t9md/vim-smalls/blob/master/README.md).
* Can choose label display position from 'start' or 'end' of matching text.
* Can configure label characters(two chars required at minimum).
* Heuristically determine appropriate number of label to use.
* Change label color to indicate if its final choice(blue is final choice).
* `line-through` decided label char for two chars label.
* Showing **Capital letter label** to standout and you can input lowercase char to chose.

# How to use

1. Start smalls-mode with `smalls:start`
2. Input character then Enter(`core:confirm`) or `smalls:jump`.
3. Choose label then the cursor land to new position with flashing.

# Commands

* `smalls:start`: Start smalls jumping mode.
* `smalls:jump`: Start jump mode, available within only smalls input UI.

# Keymap
No keymap by default.

e.g.

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-;': 'smalls:start'

# Optional.
# By this setting you can speedily start jump with minimal finger movement.  
# Limitation: You can't search `;` itself with smalls..
'atom-text-editor.smalls.search':
  ';': 'smalls:jump'
```

My setting, I'm [vim-mode](https://atom.io/packages/vim-mode) user.  

```coffeescript
'atom-text-editor.vim-mode.normal-mode':
  ';': 'smalls:start'
```
`;` is key for `vim-mode:repeat-find` in vim-mode.  
If you follow my keymap, assign it to other keymap.

and setting labelChars to `;AWEFJIO`

# Customizing label style

You can customize label style in `style.less`.

e.g.

```less
atom-text-editor::shadow .smalls-label {
  box-shadow: 0px 0px 10px @text-color;
  background-color: @background-color-error;
  &.final {
    background-color: @background-color-info;
  }
}
```

# Labeling strategy

smalls chose appropriate label chars depending on number of candidates.
Strategy is as following.

1. One char label is sufficient, use one char label.
2. Two char label is sufficient, use two char label.
3. If two char label is not enough, use two char label *multiple* time and redraw label by your choice until it reached final candidates.

# Label color

While choosing label, our eye usually be fixed to final destination position and not noticed how many other candidates are there.  
So sometimes its frustrating when just after you chose label, re-appear another label to further narrowing candidates.  
To minimize this surprise, smalls make this distinguishable by CSS class(color).  
If label is unique(means, same label is **NOT** used multiple time), it means **final** choice.  
In this case label element have `final` CSS class.  
And by default it set different color than non-final label.  

# Similar packages

Atom
* [jumpy](https://atom.io/packages/jumpy)
* [easy-motion](https://github.com/adrian-budau/easy-motion)
* [quick-jump](https://atom.io/packages/quick-jump)
* [QuickJumpPlus](https://atom.io/packages/QuickJumpPlus)

Vim
* [vim-easymotion](https://github.com/easymotion/vim-easymotion)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [vim-sneak](https://github.com/justinmk/vim-sneak)
* [vim-seek](https://github.com/goldfeld/vim-seek)
* [vim-smalls](https://github.com/t9md/vim-smalls)

Emacs
* [ace-jump-mode](https://github.com/winterTTr/ace-jump-mode)

IntelliJ
* [AceJump](https://github.com/johnlindquist/AceJump)

# TODO

* [ ] Bouncing animation on choice(CSS animation?)
* [ ] Unlock scroll cursor with hotkey?
* [ ] Narrowing based on grammar scope?
* [ ] If start with selection, only search selected area?
* [ ] Special command to put multiple cursor to candidate?
* [ ] Special command to mutate candidate like upcase, downcase, camelcase, etc..
* [ ] Start with setting candidate when selection is not multi-line.
* [ ] When started with multi-line selection, search only within selection.
* [x] Use panel to read input from user
* [x] Customizable label style
* [x] Refactoring especially `Input` view.
* [x] Better labeling algorithm to support more than 2 level nested label.
* [x] Change label color on final choice
* [x] Indicate first char is decided on two char label.

# Thanks to great predecessor!!
My smalls work is based following work.

- Lokaltog's [vim-easymotion](vim-easymotion)
- DavidLGoldberg's [DavidLGoldberg/jumpy](https://github.com/DavidLGoldberg/jumpy)
