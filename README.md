# Simple shell to run cypher-shell and send output to less
###  - From within an editor, such as `atom` that supports embedded terminals
###  - From the command line in a terminal shell
###  - In a terminal shell started in Neo4j Desktop
# 
-----
<table>
    <tr>
        <th>Unix shell</th>
        <th>Cmd.exe</th>
    </tr>
    <tr>
        <td width="50%">
            <a href="images/cypher-shell-less-atom.gif">
                <img src="images/cypher-shell-less-atom.gif" width="100%">
            </a>
        </td>
        <td width="50%">
            <a href="https://user-images.githubusercontent.com/1690993/41786131-a625d870-7612-11e8-882d-f1574184faba.gif">
                <img src="https://user-images.githubusercontent.com/1690993/41786131-a625d870-7612-11e8-882d-f1574184faba.gif" width="100%">
            </a>
        </td>
    </tr>
    <tr>
        <th>Terminal in panel</th>
        <th>Support <a href="https://www.iterm2.com/documentation-images.html">showing images</a></th>
    </tr>
    <tr>
        <td width="50%">
            <a href="https://user-images.githubusercontent.com/1690993/41784748-a7ed9d90-760e-11e8-8979-dd341933f1bb.gif">
                <img src="https://user-images.githubusercontent.com/1690993/41784748-a7ed9d90-760e-11e8-8979-dd341933f1bb.gif" width="100%">
            </a>
        </td>
        <td width="50%">
            <img src="https://user-images.githubusercontent.com/1690993/51725223-1dfa3780-202f-11e9-9600-6e24b78d562d.png" width="100%">
        </td>
    </tr>
</table>
![](images/cypher-shell-less-atom.gif)

 ## _Why?_
 
 I wrote this because I find it efficient to write large queries in atom and wanted a mechanism to 
 just highlight my query and run it in terminal within atom while paging through the output. 
 `less-cypher-shell` allows you to:
 
 - Write and test cypher queries from with or within your favorite editor if it supports
   embedded terminal functionality.
   
 - Have the ouput go to a pager instead of sending all output to the screen as it does if 
   you're working within the cypher-shell.
   
 - Wanted to be able to run `less-cypher-shell.sh` from a terminal in Neo4j Desktop or where the 
   Neo4j binaries are detached from the Desktop Neo4j environment. The detached environment is
   how I use `less-cypher-shell.sh` day-to-day since the atom editor environment is launched unaware
   of the Neo4j Desktop environment even if launched from within a Neo4j Desktop terminal.  
   
 - Avoid the overhead of the browser to potentially get results back much faster.
   Useful for showing clients that it's the browser, not the engine that
   is choking.

## _Is it overkill?_

 Maybe. You can always run cypher-shell from a terminal and a file 
 and then pipe it to less. I prefer the highlight or paste and go method.

 Especially useful when using editors like atom that have terminal emulation
 and the ability to easily highlight and transfer text to the terminal window.
 The atom packages `atom-ide-terminal` or `termination` allow the highlighting of
 text, hitting a key sequence in the editor to transfer the text to a
 terminal window. For example, if you have the text in an atom editor window
 with a terminal open:

 ```
 run-cypher-less.sh
 MATCH (n) RETURN n
 ```
  1. Highlight the above text, ___including the line with `run-cypher-less.sh`___, hit 
     the transfer to terminal sequence keys (e.g. for the default key sequence 
     for atom-ide-terminal is ctl-enter). Being in a terminal window, `less-cypher-shell.sh` 
     runs and then processes the remaining highlited text from `stdin`. You can launch your 
     another editor, such as `vi` with a command line switch in `less-cypher-shell.sh` 
     if you don't want to mess with `stdin`. But, that's what the main editor window is for.

  2. Enter a new line on the terminal window if needed and hit ctl-D (if using the
     default stdin, see command line options below).

  3. Page through you output since it's going through `less`.

 Of course there's no interactivity for entering a uid / pw. Set those with
 environment variables or pass them in to the call to less-cypher-shell.sh:

 ```
 less-cypher-shell.sh -u neo4jUser -p neoPassword
```

 All cypher-shell command line options can be passed. The script does test 
 for invalid cypher-shell parameters and other cypher-shell errors.

 ### Command line options

 There are other options that are meant to be useful from the command line.

 * Any valid cypher-shell parameters are accepted
   Note that the script's default value for the cypher-shell `--format` is `verbose`.
   The option is replaced by if `--format <cypher-shell format option>` 
   is supplied on the command line.

 * less-cypher-shell.sh specific options:
 
   -V : use vi instead of stdin
   
   -E : <editor> user defined editor (default is vi).  Note that the editor cannot
        return to the script until the file is written and control given back
        to the script. Running less-cypher-shell.sh to use the atom editor in a new
        window and wait for atom to exit from the command line it would be:
       
```
       # less-cypher-shell.sh -u uuu -p xxx -E 'atom --new-window --wait'
```


 There's not too much error checking when it comes to less-cypher-shell.sh specific parameters, and
 operational mistakes. But, I did try and catch the basics, such as making sure there's a semicolon 
 at the end of the cypher statement. Need that to happen for the whole thing to work anyways. It will
 not run empty or files with blank lines. It also validates all cypher-shell options and prints the 
 native cypher-shell error message if there's an issue.  

### Using Within Desktop

- There is a way to use within the terminal window opened available through the Neo4j Desktop. Just make
  sure that:
  
  1. `less-cypher-shell.sh` is in your `PATH` environment variable
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
  `less-cypher-shell.sh`:
  
  ``` 
  ln -s /usr/local/bin/less-cypher-shell.sh /usr/local/bin/crl 
  ```
  Or, just rename the darn thing. It's only a shell script
  
- Sorry. Don't have a windows machine, so no powershell or linux sub-system version

