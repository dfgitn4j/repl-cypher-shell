# Simple Frontend Shell  To Improve The Usability of Neo4j's `cypher-shell` command line tool

> - Run Cypher queries easily from within an editor, such as _Sublime Text 3_, _Atom_, _VSCode_, _IntelliJ_, or any other editor that supports embedded terminals.
> - As a command line REPL interface to cypher-shell, including in a terminal window started from Neo4j Desktop

-----
<table>
    <tr>
        <th><b>Sublime Text 3</b></th>
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
 
## Two Reasons:

 1. I find it more efficient to write complex Cypher queries in an editor and wanted a mechanism to 
    just highlight my query and run it and page through the text output. 

 2. Often the query I write is fast, but it returns too much data for the Neo4j Browser to render in a 
    reasonable amount of time. The Neo4j Browser is an [electronjs](https://www.electronjs.org/) based web 
    browser app after all, and there's only so much a web browser can do. There's always Neo4j Bloom to 
    visualize large sets of data, but it's functionality is not targeted at the development workflow scenario 
    I am looking for. 

 3. Most of the code for `repl-cypher-shell.sh` was already built for another database command line tool a 
    long, long, long... time... ago. I think you can tell from the style.  Should redo in python.  OK. three reasons.


#### `repl-cypher-shell.sh` allows you to:
 
 - Write and run cypher queries using `cypher-shell` within your favorite gui editor that supports
   embedded terminal functionality.  Almost all do, I've used `repl-cypher-shell.sh` in _Sublime Text 3_, _Atom_, 
   _VSCode_ and _IntelliJ_.  

 - Provide a Cypher query development and runtime enviroment avoids the overhead of the Neo4j Browser and return 
   data in the form dictated by the Cypher query.

 - Provide a REPL enviroment and controlled output when running from the command line without a gui editor. This includes 
   output managed by a pager instead of sending all output to the screen as it does if you're working within the cypher-shell.

 - Be able to save executed queries and output automatically. 
   
 - Use the above functinoalty with an installation of `cypher-shell` detached from the Desktop Neo4j environment or the server. 
   The detached environment is how I use `repl-cypher-shell.sh.sh` day-to-day. .  
   
## _Is it overkill?_

 Maybe. But `repl-cypher-shell.sh` gives me a way my Cypher queries from within tools I use for coding. 
 There's also times where I wanted a REPL and controlled output environment when running `cypher-shell` from the 
 command line.  You can always run `cypher-shell` from a terminal pipe output to a pager, but that is a
 rough REPL enviroment. I prefer the highlight or paste and go method, or running in a command line cycle 
 through this workflow:

  vi or emacs to edit cypher query :point_right: save query and exit vi :point_right: run query in cypher-shell :point_right: view output in pager :point_right: return to vi  :metal:

 That's all good, but the main value of `repl-cypher-shell.sh` comes from using within editors such as _Sublime Text 3_, 
 _VSCode_, and _Atom_, etc. to send cypher queries to an embedded terminal window to be run repeated.y.
 
## _Installation_

#### Install Neo4j `cypher-shell` , or use the `cypher-shell` that comes with the Neo4j Desktop

A `cypher-shell` installation is a pre-requisite to running `repl-cypher-shell.sh` front-end. Multiple versions
of `cypher-shell` can be downloaded and installed, or you can use the cypher-shell that is in the database 
environment created when you create a Neo4j database using the Neo4j Desktop.


1. Install stand alone `cypher-shell` and add to your PATH environment variable (the most common approach)  
   
   Install `cypher-shell` and validate that it is compatible with the targeted version(s) of 
   the Neo4j Graph Database. Standalone`cypher-shell` can be downloaded from the [Neo4j Download Center](https://neo4j.com/download-center/). 
   Suggest using a 4.x version of `cypher-shell` but you might need to have mixed java environments since the
   Neo4j 3.x product line uses java 8 and 4.x uses java 11 . Add the `cypher-shell` executable path to your PATH 
   environment variable.

2. Use the Neo4j Desktop version of cypher-shell already installed with the database created and managed by the Neo4j Desktop.

   This approach is useful when you don't have a standalone version of the `cypher-shell` installed, or
   have version compatibility issues. There is the `repl-cypher-shell.sh` `--cypher-shell` command line 
   parameter that specifies a `cypher-shell` installation to use. See [Running From Command Line](#running-from-command-line-repl-kind-of-workflow) section below.

#### `repl-cypher-shell.sh` Environment

1. Download `repl-cypher-shell.sh`.

2. Make file executable (e.g. `chmod 744 repl-cypher-shell.sh`).

3. Place in directory that is in the PATH variable. For example /usr/local/bin
   seems to be good for mac's because it's in the PATH of the Neo4j Desktop
   termininal environment.

### Enable embedded terminal functionality if using a gui code editor

  Editors such as _Sublime Text 3_ or _Atom_ need embedded terminal functionality added to the base install.
  The _Sublime Text 3_ _terminus_ package, and the _Atom_ package _platformio-ide-terminal_ enable terminals to 
  be launched within the editor.  They also allow for the highlighting of text and then hitting a key 
  sequence in the editor to transfer the text to a terminal window. The examples in the [EDITOR_MAPPINGS](EDITOR_MAPPINGS) folder enable: 

  _Atom_:

  -  `ctrl+1` to copy text and send to open terminal.

  _Sublime Text 3_:

  - `ctrl+shift+0` to copy text and send to open terminal. 
  - `ctrl+shift+1` will send a `<CR-LF><CTL-D>` at the end of the selected text to run 
     the query immediately.   

## _Example Usage_

### Running From Within A GUI Text Editor

  Assuming you have this text in an editor window:

    repl-cypher-shell.sh

    MATCH (n) RETURN n LIMIT 10
 
  1. Open an embeded terminal window, e.g. _terminus_ for _Sublime Text 3_ or _platformio-ide-terminal_.

  2. Start `repl-cypher-shell.sh`

     - Highlight the `repl-cypher-shell.sh` line in the editor and transfer it to the terminal window through 
       copy-paste-into-terminal key sequence, or just copy and paste into the terminal.

     - Hit Enter key in the terminal window to start the shell if needed. A user name and password will
       be asked for if it's needed.

  2. Run Cypher

     - Repeat the same with the `MATCH` text if needed and hit ctl-D.

  3. Consume Output

     - Page through the output in the terminal window since it's going through `less`. I especially like 
       the horizontal scrolling capabilities in less for wide rows. 

  4. Repeat

     - cypher-shell input is still active

  _*NOTE:*_ Input is through stdin so there's no real editing keys in the terminal input, but that's what the
  editor is for. 


### Running From Command Line (REPL kind of workflow)

  1. Add `repl-cypher-shell.sh` in PATH if needed (e.g. /usr/local/bin)

  1. Determine which `cypher-shell` to run:
    
     1. Run `repl-cypher-shell.sh` in a terminal environment that has in its PATH environment variable a 
        version of `cypher-shell` that is compatible with the database version being connected to. 

     1. Use the `-C | --cypher-shell` command line option to specify the `cypher-shell` install. 
        This is useful when you do not have a standalone `cypher-shell` installed. To do this, open
        a Neo4j Desktop terminal window for the currently running database and run this command from 
        the command line prompt:

         `repl-cypher-shell.sh --cypher-shell ./bin/cypher-shell`

  1. Run `repl-cypher-shell.sh` taking in consideration the environment described in step 1.

     - Run `cypher-shell` with Neo4j database username provided and ask for a
       password if the NEO4J_PASSWORD environment variable is not set:
 
          `${shellName} -u neo4j`
 
      - Use vi editor and keep an individual file for each cypher command run:
 
          `repl-cypher-shell.sh --vi`
 
      - Use a visual editor. Can be done, but the expected scenario is to run
        ${shellName} from a terminal window *within* the gui editor:
 
        `repl-cypher-shell.sh --saveCypher -E 'subl --new-window --wait'`

        `repl-cypher-shell.sh.sh -u uuu -p xxx -E '_Atom_ --new-window --wait'`

### BUGS:
 
  - There has to be.  
    
### Hints and distractions
 
 - Unfortunately this is a shell script that has been tested mainly on Mac OSX, and ubuntu.  Seemed to work OK in a Windows Subsystem for Linux.

