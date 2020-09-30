# https://stackoverflow.com/questions/56523116/atom-override-keybinding-for-platformio
atom.commands.add "atom-workspace", "my-custom-toggle": ->
    activeEditor = atom.views.getView atom.workspace.getActiveTextEditor()

    pioTerminal = document.querySelector("platformio-ide-terminal.terminal-view")
    parentNode = pioTerminal.parentNode if pioTerminal

    if !parentNode or parentNode.style.display is "none"
      atom.commands.dispatch(activeEditor, "platformio-ide-terminal:toggle")

    # atom.commands.dispatch(activeEditor, "custom:termInsSelandFocus")  # error https://github.com/platformio/platformio-atom-ide-terminal/issues/856
    atom.commands.dispatch(activeEditor, "platformio-ide-terminal:focus")

atom.commands.add "atom-workspace", "custom:termInsSelandFocus", (evt) ->
  atom.commands.dispatch evt.target, "platformio-ide-terminal:insert-selected-text"
  atom.commands.dispatch evt.target, "platformio-ide-terminal:focus"
