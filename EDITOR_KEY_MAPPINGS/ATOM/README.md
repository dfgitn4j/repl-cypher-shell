## Atom Text Editor

Have used with the atom package [platformio-ide-terminal](https://atom.io/packages/platformio-ide-terminal) since it's a fork with recent-ish
maintained version of the original terminal-plus package.

##### Custom Key Binding

Added the following code to atom's `init.coffee` file to enable pasting the text selected in the editor pane and
setting focus to the terminal window.

```coffeescript
atom.commands.add "atom-workspace", "custom:termInsSelandFocus", (evt) ->
  atom.commands.dispatch evt.target, "platformio-ide-terminal:insert-selected-text"
  atom.commands.dispatch evt.target, "platformio-ide-terminal:focus"
```

Then added this code into atom's `keymap.cson` to bind the above to the `ctl-4`
key combination.
```yaml
atom-text-editor':
  'ctrl-4': 'termInsSelandFocus'
```

##### Example Sequence of

https://atom.io/packages/atom-terminal-panel
https://roland-ewald.github.io/2017/02/26/atom-terminal.htm
