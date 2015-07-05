# smalls

Rapid cursor positioning across any visible chars with search and jump.

# Features

* Search and jump to position across visible panes.
* Flashing cursor position on landing(enbaled by default).
* Automatically start jump-mode with configured input length.
* [easymotion](https://github.com/easymotion/vim-easymotion) style label jump.
* Port of my [vim-smalls](https://github.com/t9md/vim-smalls/blob/master/README.md).
* Can choose where label is shown from 'start' and 'end' of matching text.

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
# By this setting we can speedily start jump with minimal hand movement.  
# Limitation: You can't search `;` itself with smalls..
'atom-text-editor.smalls.search':
  ';': 'smalls:jump'
```

* My setting, I'm [vim-mode](https://atom.io/packages/vim-mode) user.
NOTE `;` is bound to `vim-mode:repeat-find`, very important command.
So If you follow my keymap, you'd better assign `vim-mode:repeat-find` to other
keybind.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  ';': 'smalls:start'
```

# Customizing label style

You can customzize label style in `style.less`.

e.g.

```less
atom-text-editor::shadow {
  .smalls {
    &.label {
      background-color: @background-color-success;
    }
  }
}
```

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

* [x] Use panel to read input from user
* [x] Customizable label style
* [x] Refactoring especially `Input` view.
* [ ] Better algorithm for labeling.
* [ ] Unlock scroll cursor with hotkey?
* [ ] Narrowing based on grammar scope?
