import sublime
import sublime_plugin

# Requires the terminus package!
# how to add command tutorial: https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be
# add in sublime root install Packages/User directory 
class SendSelectionToTerminusCommand(sublime_plugin.TextCommand):
    """
    Extract the contents of the first selection and send it to Terminus.
    """
    def run(self, edit, tag=None, visible_only=True):
        self.view.window().run_command("terminus_send_string", {
            "string": self.view.substr(self.view.sel()[0]) + '\n\x04',
            "tag": tag,
            "visible_only": visible_only
            })
        self.view.window().run_command("toggle_terminus_panel")
