# Simple shell to run cypher-shell and send output to less
###  - From within an editor, such as _Sublime Text 3_, _Atom_, _VSCode_, or any other editor that supports embedded terminals
###  - From the command line in a terminal shell
###  - In a terminal shell started in Neo4j Desktop
# 
-----
<table>
    <tr>
        <th>_Sublime Text 3_</th>
    </tr>
    <tr>
        <td width="100%">
            <a href="images/sublime.gif">
                <img src="images/sublime.gif" width="100%">
            </a>
        </td>
    </tr>
    <tr>
        <th>Atom</th>
    </tr>
    <tr>
        <td width="100%">
            <a href=images/_Atom_.gif">
                <img src="images/atom.gif" width="100%">
            </a>
        </td>
    </tr>
</table>


 ## _Why?_
 
 I wrote this because for two reasons:

 1. I find it more efficient to write complex Cypher queries in an editor and wanted a mechanism to 
 just highlight my query and run it in an embedded terminal and then page through the output. 

 2. Often the query I write is fast, but it returns too much data for the Neo4j Browser to render. The
 Neo4j Browser is an electron based browser app after all.

 `repl-cypher-shell.sh` allows you to:
 
 - Write and test cypher queries from with or within your favorite editor if it supports
   embedded terminal functionality.
   
 - Have the ouput go to a pager instead of sending all output to the screen as it does if 
   you're working within the cypher-shell.
   
 - Run `repl-cypher-shell.sh.sh` from a terminal in Neo4j Desktop or where the 
   Neo4j binaries are detached from the Desktop Neo4j environment. The detached environment is
   how I use `repl-cypher-shell.sh.sh` day-to-day as an editor's environment is launched unaware
   of the Neo4j Desktop environment even if launched from within a Neo4j Desktop terminal.  
   
 - Avoid the overhead of the browser to potentially get results back much faster.
   Useful for cases where the query performance is fine, but the Neo4j Browser electron based app
   cannot render the results. Note that Neo4j Bloom can be used to render large amounts of data.

## _Is it overkill?_

 Maybe. You can always run cypher-shell from a terminal and a file 
 and then pipe it to less. I prefer the highlight or paste and go method.

 Especially useful when using editors such as _Sublime Text 3_, _VSCode_, and _Atom_ that have 
 terminal emulation and the ability to easily highlight and transfer text to the terminal window.
 
## _Installation_

- If using an external editor:

  Have terminal capabilities enabled if you're using an editor. The _Sublime Text 3_ package _terminus_, 
  and the _Atom_ package _platformio-ide-terminal_ allow for the highlighting of text and then hitting a key 
  sequence in the editor to transfer the text to a terminal window.


## _Example Usage_

 For example, if you have the text in a _Sublime Text 3_ or _Atom_ editor window with a terminal open:

    repl-cypher-shell.sh
    MATCH (n) RETURN n
 
  1. Open an embeded terminal window, e.g. terminus for _Sublime Text 3_ or platformio-ide-terminal.

  2. Highlight the above text, ___including the line with `repl-cypher-shell.sh`___, hit 
     the transfer to terminal sequence keys. I gave examples of key mappings in the TERMINAL_MAPPING directory
     for _Atom_ and _Sublime Text 3_. These keybindings enable

     _Atom_:

     -  `ctrl+1` to copy text and send to open terminal.

     _Sublime Text 3_:

     - `ctrl+shift+0` to copy text and send to open terminal. 
     - `ctrl+shift+1` will send a `<CR-LF><CTL-D>` at the end of the selected text to run 
     the query immediately.   Being in a terminal window, `repl-cypher-shell.sh.sh` 
     runs and then processes the remaining highlited text from `stdin`. 

  3. You can launch your 
     another editor, such as `vi` with a command line switch in `repl-cypher-shell.sh.sh` 
     if you don't want to mess with `stdin`. But, that's what the main editor window is for.

  2. Enter a new line on the terminal window if needed and hit ctl-D (if using the
     default stdin, see command line options below).

  3. Page through you output since it's going through `less`.

 All cypher-shell command line options can be passed to `repl-cypher-shell.sh`. The script does test 
 for invalid cypher-shell parameters and other cypher-shell errors.

 ### Command line options

 There are other options that are meant to be useful from the command line.

 * Any valid cypher-shell parameters are accepted
   Note that the script's default value for the cypher-shell `--format` is `verbose`.
   The option is replaced by if `--format <cypher-shell format option>` 
   is supplied on the command line.

 * repl-cypher-shell.sh.sh specific options:
 
   -V : use vi instead of stdin
   
   -E : <editor> user defined editor (default is vi).  Note that the editor cannot
        return to the script until the file is written and control given back
        to the script. Running repl-cypher-shell.sh.sh to use the _Atom_ editor in a new
        window and wait for _Atom_ to exit from the command line it would be:
       
```
       # repl-cypher-shell.sh.sh -u uuu -p xxx -E '_Atom_ --new-window --wait'
```


 There's not too much error checking when it comes to repl-cypher-shell.sh.sh specific parameters, and
 operational mistakes. But, I did try and catch the basics, such as making sure there's a semicolon 
 at the end of the cypher statement. Need that to happen for the whole thing to work anyways. It will
 not run empty or files with blank lines. It also validates all cypher-shell options and prints the 
 native cypher-shell error message if there's an issue.  

### Using Within Desktop

- There is a way to use within the terminal window opened available through the Neo4j Desktop. Just make
  sure that:
  
  1. `repl-cypher-shell.sh.sh` is in your `PATH` environment variable
  2. The `cypher-shell` for the instance you're running is also in your `PATH` before any other 
  `cypher-shell` versions that may be incompatible. 
  3. Add /usr/local/bin to your path (for mac osx anyways). 

- You ___WILL___ need a working and compatible Neo4j environment if the database that's running
  was started in the Neo4j Desktop and you're _not_ in a Neo4j Desktop window. 
  See [this repo](https://github.com/dfgitn4j/setPATH) if you're ooking for tools to change your 
  Neo4j and java environments on the fly.
  
  This all should be cleaner and it'd beeasly enough to do.  maybe for another day? 

 ### BUGS:
 
  - I am sure there are some as I only tested on mac catelina 10.15 using `zsh` over the course
    of writing this in an afternoon. Did try to account for the differences between bash and 
    zsh for array indexing. 
    
### Hints and distractions

- Do a soft link to a a directory somewhere on your path to an easier thing to type instead of
  `repl-cypher-shell.sh.sh`:
  
  ``` 
  ln -s /usr/local/bin/repl-cypher-shell.sh.sh /usr/local/bin/crl 
  ```
  Or, just rename the darn thing. It's only a shell script
  
- Sorry. Don't have a windows machine, so no powershell or linux sub-system version

