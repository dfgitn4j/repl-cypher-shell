import sublime
import sublime_plugin

# how to add command tutorial: https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be
# add in sublime root install Packages/User directory 
class SendSelectionToTerminusCommand(sublime_plugin.TextCommand):
    """
    Extract the contents of the first selection and send it to Terminus.
    """
    def run(self, edit, tag=None, visible_only=True, add_ctl_d=True, send_q_for_pager=False):
        if add_ctl_d :
            term_string='\n\x04'
        else :
            term_string='\n'

        if send_q_for_pager :
            q_string='q\n'
        else :
            q_string='\n'

        self.view.window().run_command("terminus_send_string", {
         "string": q_string + self.view.substr(self.view.sel()[0]) + term_string,
         "tag": tag,
         "visible_only": visible_only
         })
#        self.view.window().run_command("toggle_terminus_panel")

