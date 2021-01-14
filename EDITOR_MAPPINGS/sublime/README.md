## Sublime User Package

Files to c 
`ctrl+shift+0` does not append a carriage return and ctl-D, `ctrl+shift+1` does.  Note that an active terminal must be open for this to work.  See [this link](https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be) if you're new to Sublime Text 3 user packages.

**sendTextToTerminus.py**

Configure sublime text editor key sequence to send selected text:
1. With or without ctl-D
2. Send a "q" to exit less pager, with or without with a ctl-D 

ctl-D terminates stdin to run the query when in interactive mode.

**Default (OSX).sublime-keymap**

Map sublime key sequence to for sendTextToTerminus.py