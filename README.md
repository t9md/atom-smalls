# smalls

Rapid cursor positioning across any visible chars with search and jump.

![gif](https://raw.githubusercontent.com/t9md/t9md/27897f4b49bc518da19940593f120d774c2c22cc/img/atom-smalls.gif)

# Features

* Search and jump to position across visible panes.
* Flashing cursor position on landing(enbaled by default).
* Automatically start jump-mode with configured input length.
* [easymotion](https://github.com/easymotion/vim-easymotion) style label jump.
* Port of my [vim-smalls](https://github.com/t9md/vim-smalls/blob/master/README.md).
* Can choose where label is shown from 'start' and 'end' of matching text.
* Can onfigure label characters.
* Showing **Capital letter label** to standout and your input automatically upcased when finding matching label.
* Efficient labeling strategy to reduce key type and brain context switch.

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
atom-text-editor::shadow .smalls-label {
  background-color: @background-color-error;
}
```

# Labels Chars and supported candidates

`labelChars` define set of character to be used as label.  
Number of label characters limit number of accommodate matching candidates.  
So question is how many candidates this labelChars accommodate?
Formula is bellow(`L` means `labelChars.length`).

* `Candidates = (L x L) x (L * L)`

e.g.

| labelChars | Formula             | Candidates |
| ---------- | ------------------- | ---------- |
| `AB`       | `(2 * 2) * (2 * 2)` | 16         |
| `ABC`      | `(3 * 3) * (3 * 3)` | 81         |
| `ABCD`     | `(4 * 4) * (4 * 4)` | 256        |

# Labeling strategy

Currently label will nest to two level depending on number of candidates.  
* one = one character label(e.g. `A`)
* two = two character label(e.g. `AB`)
* L1 = level1, 1st layer label.
* L2 = level2, 2nd layer label.

Label appear L1 > L2 order.

Depending on number of candidates, labeling strategy is determined by following order

1. `L1 = one`
2. `L1 = two`
3. `L1 = one, L2 = two`
4. `L1 = two, L2 = two`


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
* [ ] Better labeling algorithm to support more than 2 level nested label.
* [ ] Unlock scroll cursor with hotkey?
* [ ] Narrowing based on grammar scope?

# Thanks to great predecessor!!
My smalls work is based following work.

- Lokaltog's [vim-easymotion](vim-easymotion)
- DavidLGoldberg's [DavidLGoldberg/jumpy](https://github.com/DavidLGoldberg/jumpy)
