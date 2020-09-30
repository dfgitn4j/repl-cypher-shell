## Sublime User Package

Files to configure sublime text editor key sequence to send selected text with or without a carriage return and ctl-D appended. 
`ctrl+shift+0` does not append a carriage return and ctl-D, `ctrl+shift+1` does.  Note that an active terminal must be open for this to work.  See [this link](https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be) if you're new to Sublime Text 3 user packages.

### Files:

**sendTextToTerminus.py**

```python
import sublime
import sublime_plugin

# how to add command tutorial: https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be
# add in sublime root install Packages/User directory 
# should add create and tag terminal if one is not open functionality
class SendSelectionToTerminusCommand(sublime_plugin.TextCommand):
    """
    Extract the contents of the first selection and send it to Terminus.
    """
    def run(self, edit, tag=None, visible_only=True, add_ctl_d=True):
        if add_ctl_d :
            term_string='\n\x04'
        else :
            term_string=''

        self.view.window().run_command("terminus_send_string", {
            "string": self.view.substr(self.view.sel()[0]) + term_string,
            "tag": tag,
            "visible_only": visible_only
            })
        self.view.window().run_command("toggle_terminus_panel")
```

**Default (OSX).sublime-keymap**

```json
[
	{
        "keys": ["ctrl+shift+0"],
        "command": "send_selection_to_terminus",
        "args": {
            "visible_only": "True", 
            "add_ctl_d": false
        },
        "context": [
            { "key": "selection_empty", "operator": "equal", "operand": false },
            { "key": "num_selections", "operator": "equal", "operand": 1 }
        ]
    },
    {
        "keys": ["ctrl+shift+1"],
        "command": "send_selection_to_terminus",
        "args": {
            "visible_only": "True", 
            "add_ctl_d": true
        },
        "context": [
            { "key": "selection_empty", "operator": "equal", "operand": false },
            { "key": "num_selections", "operator": "equal", "operand": 1 }
        ]
    }
]    
```


