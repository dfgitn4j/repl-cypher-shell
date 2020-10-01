#set -xv
# script to front-end cypher-shell and pass output to pager

### shell accomodations

# for zsh to avoid having to do this for command line word split in this shell
# args=(${user_name} ${_} ${cypherShellArgs} ${cypher_format_arg})
# cypher-shell "${args[@]}"
setopt SH_WORD_SPLIT >/dev/null 2>&1
shellName=${0##*/}  # shell name

usage() {

  if [[ ${quiet_output} == "N" ]]; then # usage can be called when error occurs
  cat << USAGE

 NAME

  ${shellName}
   - Frontend to cypher-shell with REPL flavor on command line, in a text editor embedded
     terminal (e.g. Sublime Text, atom, VSCode, IntelliJ), with output sent through a pager. 

 SYNOPSIS

  ${shellName}

    [-u | --username]        cypher-shell username parameter.
    [-p | --password]        cypher-shell password parameter.
    [-C | --cypher-shell]    path to cypher-shell executable to be used. Run --help for how to use.
    [-P | --param]           cypher-shell -P | --param strings. Run --help for how to use.
    [-f | --file]            cypher-shell -f | --file containing query. Run --help for how to use.
    [--format]               cypher-shell --format option.

    [-A | --saveAll]         save cypher query and output results files.
    [-S | --saveCypher]      save each query statement in a file.
    [-R | --saveResults]     save each query output in a file.
    [-V | --vi]              use vi editor.
    [-E | --editor] [cmd]    use external editor. See NOTES.
    [-L | --lessOpts] [opts] use these less pager options instead of defaults.

    [-t | --time]            print time elapsed between sending query and
                             creating the results file.
    [-c | --showCmdLn]       show script command line args in output. See NOTES.
    [-q | --quiet]           minimal output.

    [-1 | --one]             run query execution loop only once and exit.
    [-N | --noLogin]         login to Neo4j database not required.
    [-X | --exitOnError]     exit script on error.

    [-U | --usage]           command line parameter usage only.
    [-v | --version]         cypher-shell display version and exit.
    [--driver-version]       cypher-shell display driver version and exit.
    [-h | --help]            detailed help message.

    [*] ANY other parameters are passed through as is to cypher-shell.

 
USAGE
  fi
}

dashHelpOutput() {

  cat << THISNEEDSHELP

 $(usage)

 DESCRIPTION

  ${shellName} is a front-end wrapper to cypher-shell that executes cypher
  statements and pipes the output into the less pager with options to save
  output. There are two execution scenarios where different command line options
  can apply:

  2) Command Line

     Run cypher commands through ${shellName} from the command line. Cypher
     input can be copy / paste, direct entry via an editor or stdin, or piped in.
     The default input and editing is through stdin. It is suggested that the
     --vi option for a seamless REPL experience. External gui editors can be
     used but must be exited for the query to run. It is better to call 
     ${shellName} from an terminal embedded in teh gui editor to get the same
     REPL experience. 

     Neo4j Desktop terminal provides a database compatible version of cypher-shell,
     but you may have to use the -C | --cypher-shell parameter to tell ${shellName}
     where to find it.

  1) Embedded Terminal

    Run cypher commands and page through output using in an IDE terminal window
    or editors such as atom or sublime text 3 that can send selected text to an
    embedded or external terminal.

    Some editors, such as sublime text have the capability to modify text before
    being sent to a terminal window.  This allows for inserting the keystrokes
    to terminate stdin by sending a newline and Ctl-D to close stdin and  pass
    the text to cypher-shell for execution. Otherwise the user must change window
    focus and enter Ctl-D on a newline to start execution.  Sublime Text 3 user
    packages are used to extend the sublime functionality see the documentation or
    https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be as a starting point.

    There is a basic User package and key binding config in the EDITOR_MAPPING 
    directory.

 OPTIONS

  -u | --username <Neo4j database username> 
  
    Database user name. Will override NEO4J_USERNAME if set.

  -p | --password <Neo4j database password>
  
    Database password. Will override NEO4J_USERNAME if set.

  -C | --cypher-shell <path to cypher-shell>

    Used to specify a different cypher-shell than the first one found in the PATH environment
    variable.  Meant to be used with a standalone cypher-shell if not in path, or if the
    cypher-shell found in PATH is incompatible with the Neo4j Desktop database version being run. 
    On the Neo4j Desktop terminal command line, use the calling sytnax below to use the cypher-shell that
    comes is part of the current running database and starting from the initial terminal directory:

      repl-cypher-shell.sh --cypher-shell ./bin/cypher-shell

  -P | --param <cypher-shell parameters>
  
    Database parameters passed to cypher-shell. Delimit parameter string with
    single quotes ('') and use double quote for character parameter values (""), e.g:
  
      --param 'lim => 5' --param 'id => "AB00X901"'

  -f | --file <file name>
  
    File containing cypher to run and it overrides cypher-shell input file parameter in the 4.x 
    version of cypher-shell. Intercepting this flag allows it to work the cypher-shell
    3.5.x

  -format <auto,verbose,plain>
  
    cypher-shell formatting option. Default is 'verbose'.

  -v | --version | --driver-version)
  
    cypher shell version commands. run and exit.

  -A | --saveAll)
  
    Save all cypher queries and output in individual files.   Save query and query
    results to files in the current directory. The files will have the same
    timestamp and session identifiers Files will be in current directory with the
    format:
  
        cypher query: ${OUTPUT_FILES_PREFIX}_[succesful query cnt].[datetime query was run][session ID]${QRY_FILE_POSTFIX}
        results text: ${OUTPUT_FILES_PREFIX}_[succesful query cnt].[datetime query was run][session ID]${RESULTS_FILE_POSTFIX}
  
        For example:
  
        ${OUTPUT_FILES_PREFIX}_001.$(date +%FT%T)_${SESSION_ID}${QRY_FILE_POSTFIX}
        ${OUTPUT_FILES_PREFIX}_001.$(date +%FT%T)_${SESSION_ID}${RESULTS_FILE_POSTFIX}

  -S | --saveCypher)
  
    Save cypher query to a file in the current directory. The file will have the
    same timestamp and session identifier in the file name as the query results
    file if it is also kept.  Files will be in current directory with the
    format as described in  --save_all
  
  -R | --saveResults)
      
      Save query results to a file in the current directory. The file will have the
      same timestamp and session identifier in the file name as the query results
      file if it is also kept.  Files will be in current directory with the
      format as described in --save_all

  -V | --vi)
  
    Use vi editor for cypher input instead of stdin.  Use when running from
    command line versus and embedded terminal.

  -E | --editor <'editor command line with options'>
  
    Define an editor that can be started from the command line in insert mode.
    This *requires* '<editor command line with options>' be single quotes if
    there are command line options needed.  For example to launch atom or
    sublime:
      sublime: ${shellName} -E 'subl --new-window --wait'
         atom: ${shellName} -E 'atom --new-window --wait'

  -L | --lessOpts <'less command options'>
  

    [opts] for the --lessOpts parameter require escaping the first command line
    option that begin with '-' and '--' by prepending each '-' with a '\'
    backslash. E.g. for the script's --lessOpts that defines options to run the
    less pager with using the less --LINE-NUMBERS and --chop-long-lines would be 
    submitted to ${shellName} as:

       --lessOpts '\-\-LINE-NUMBERS --chop-long-lines'

    ** --QUIT-AT_EOF ** if any of the less options for quit at end of file may
    end up with a blank screen for output that does not fill the complete
    terminal screen.  Change clear command in script if this is an issue.

  -c | --showCmdLine 
  
    Print the command line arguments the script was called for every query.

  -t | --time 
  
    Print time elapsed between sending query and getting results file for every
    query.

  -q | --quiet 
  
    Minimal output, no connection messages, etc.

  -1 | --one 
  
    Run once then exit.

  -N | --noLogin 
  
    No login required for database.

  -X | --exit_on_error 
  
    Exit if cypher-shell returns an error.

  -U | --Usage
  
    Parameter calling usage.

  -h | --help 
  
    This message.

  [*]

    Every command line parameter not explicitly caught by the script are assumed
    to be cypher-shell options and are passed through to cypher-shell. An example
    of passing login information to cypher-shell, e.g:
  
         ${shellName} -a <ip address>

 INSTALLATION

  1. Install cypher-shell and validate that it is compatible with the targeted version(s) of 
     the Neo4j Graph Database.  Suggesting using a 4.x version of cypher-shell. Alternative is
     to use the --cypher-shell parameter to specify a cypher-shell installation to use. 

  2. Download ${shellName} from github (https://github.com/dfgitn4j/repl-cypher-shell).

  2. Make file executable (e.g. chmod 755 ${shellName}).

  3. Place in directory that is in the PATH variable. For example /usr/local/bin
     seems to be good for mac's because it's in the PATH of the Neo4j Desktop
     termininal environment.


 EXAMPLES

  See https://github.com/dfgitn4j/repl-cypher-shell for visual examples using embeddedd 
  terminals in atom, sublime, etc.

  1. Run ${shellName} in a terminal environment that has in its PATH 
     environment variable a version of cypher-shell that is compatible with the 
     database version being connected to. Use the -C | --cypher-shell command line option 
     to use the cypher-shell that is part of the currently running Neo4j Destkop database 
     installation. e.g. run from the directory you're in when a Neo4j Desktop
     terminal is launched:

       repl-cypher-shell.sh --cypher-shell ./bin/cypher-shell

  2. Add ${shellName} in PATH if needed (e.g. /usr/local/bin)

  3. Run ${shellName} taking in consideration the environment described in step 1.

    - Run cypher-shell with Neo4j database username provided and ask for a
      password if the NEO4J_PASSWORD environment variable is not set:

        ${shellName} -u neo4j

    - Use vi editor and keep an individual file for each cypher command run:

        sTrp-cypher-shell.sh --vi

    - Use sublime as the editor. Expected scenario is to run
      ${shellName} from a terminal window *within* the gui editor:

       ${shellName} --saveCypher -E 'subl --new-window --wait'

     See https://www.sublimetext.com/docs/3/osx_command_line.html

THISNEEDSHELP
}

setDefaults () {
  # pipe input?
 [ -p /dev/fd/0 ] && is_pipe="Y" || is_pipe="N"

 db_ver_qry="CALL dbms.components() YIELD name, versions, edition
  WITH name, versions, edition WHERE name='Neo4j Kernel'
  CALL dbms.showCurrentUser() YIELD username
  RETURN versions, edition, username;"

  db_40_db_name_qry="CALL db.info() YIELD name as db_name RETURN db_name;"
   # exit codes
   # IMPORTANT for testing scripts where grep is used to get the names and codes
   # Variables must begin with 'RCODE_'  and follow var=<nbr> pattern with nothing else on the line
   # Codes must be sequential starting at 0
   # Return codes are meant mostly for non-interactive (e.g. run once) or critical error exit
  RCODE_SUCCESS=0
  RCODE_INVALID_CMD_LINE_OPTS=1
  RCODE_CYPHER_SHELL_NOT_FOUND=2
  RCODE_CYPHER_SHELL_ERROR=3
  RCODE_INVALID_FORMAT_STR=4
  RCODE_NO_USER_NAME=5
  RCODE_NO_PASSWORD=6
  RCODE_EMPTY_INPUT=7
  RCODE_MISSING_INPUT_FILE=8

  cypherRetCode=0  # cypher-shell return code
  cypherShellArgs="" # any cypher-shell args passed in

   # Start first exec for vi in append mode.
  vi_initial_open_opts=' +star '

  SESSION_ID="${RANDOM}" # nbr to id this session. For when keeping intermediate cypher files
  OUTPUT_FILES_PREFIX="qry_" # prefix all intermediate files begin with
  QRY_FILE_POSTFIX=".cypher" # prefix all intermediate files begin with
  TIME_OUTPUT_HEADER="# query / output creation file runtime:"
  RESULTS_FILE_POSTFIX=".txt"
  TMP_FILE="tmpEditorCypherFile.${SESSION_ID}"
  TMP_DB_CONN_FILE="tmpDbConnectTest.${SESSION_ID}"

  edit_cnt=0  # count number of queries run, controls stdin messaging.
  success_run_cnt=1 # count number of RCODE_SUCCESSful runs for file names, start at 1 since the file names are created before the query is run
 
  # frig'n shell differences can be
  #if [[ $(ps -p $$ -ocomm=) == "bash" ]]; then
  #  isBash=1
  #fi
}

printTimeFromSeconds() {
  printf "%02d:%02d:%02d" $(($1/3600)) $(($1/60%60)) $(($1%60))
}

# either or, works for one char answers, e.g. [Yy]
yesOrNo() {
  if [[ ${is_pipe} == "N" ]]; then
    msg=${1}
    printf "%s" "${msg}"
    read option
    case ${option} in
      [Yy]) return 0  ;; # you can change what you do here for instance
      [Nn]) return 1  ;;
      *) yesOrNo "$msg"  ;;
    esac
  fi
}

printContinueOrExit() {
  if [[ ${run_once} ]]; then # don't give option to continue
    exitShell ${cypherRetCode}
  fi
  if [[ ${is_pipe} == "N" ]]; then
    printf "%s" "Press Enter to continue. Ctl-C to exit ${shellName} "
    read n
  fi
}

messageOutput() {  # to print or not to print
  if [[ ${quiet_output} == "N" ]]; then
    printf "%s\n" "${1}"
  fi
}

# one and done cypher-shell options run
runCypherShellInfoCmd () {
  messageOutput "Found cypher-shell command argument '${_currentParam}'. Running and exiting. Bye."
  cypher-shell "${1}"
  exitShell ${RCODE_SUCCESS}
}

# find a string in a string, return exit code from grep
findStr() {
  lookFor="${1}"
  shift
  for arg in "$@"; do inThis="${inThis} ${arg}"; done
  echo "${inThis}" | grep --extended-regexp --quiet -e "${lookFor}"
  return $?
}

 # getOptArgs - gets 0 or more flag options, sets a var with the vals in _retOpts for a flag until next
 #  flag, and sets _shiftCnt as the number of options found to shift the source array
 #  and does error cking.
 #    1st param = expected number of parameters, -1 = no limit (i.e. -f abc 1 dca -a will return abc 1 dca)
 #    2nd param = error message
 #    3rd param = options passed in
 #
 #  i.e called with getOptArgs -1 "my error" "-f abc 1 dec -a" will set:
 #      _retOpts="abc 1 dec"
 #      _shiftCnt=3
 # calling function then needs to shift it's input array by _shiftCnt
getOptArgs() {

  _retOpts=""  # init no options found
  _nbrExpectedOpts="${1}"  # nbr options expected
  shift
  _currentParam=${1}
  shift  # $@ should now have remaing opts, if any
  _shiftCnt=1

  if [[ ${_nbrExpectedOpts} == 0 ]]; then
    if [[ ${1} != -* ]] && [[ ${1} ]]; then
      messageOutput  "No option expected for ${_currentParam}. Bye."
      exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
    fi
  elif [[ ${_nbrExpectedOpts} -eq 1 ]]; then
    if [[ ${1} == -* ]] || [[ ! ${1} ]] ; then
      messageOutput "Missing options for: ${_currentParam}. Bye."
      exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
    else # valid one param option
      _retOpts="${1}"
      (( _shiftCnt++ )) # shift over flag and single parameter
    fi
  else # undefined pattern, 0 or unlimited options until next flag
    if [[ ${1} == -*  || ! ${1} ]]; then # flag only, e.g. --whyme
      _retOpts="${1}"
    else # multi param
      while [[ ${1} != -*  &&  ${1} ]] ; do
        _retOpts="${_retOpts}${1}"
        if [[ ${_nbrExpectedOpts} -ne -1 ]] && [[ ${_shiftCnt} -gt  ${_nbrExpectedOpts} ]]; then
          messageOutput "Wrong options for ${_currentParam}. Bye."
          exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
        fi
        (( _shiftCnt++ ))
        shift
      done
    fi
  fi

  return 0
}

getArgs() {
  # less options --shift .01 allows left arrow to only cut off beginning "|"
  # while scrolling at the expense of slower left arrow scrolling
  # Note: less will clear screen before user sees ouput if the quit-at-end options
  # are used. e.g. --quit-at-eof.  Look for comment with string "LESS:" in script
  # if this behavior bugs you.
  use_pager='less'
  less_options='--LONG-PROMPT --shift .05'

  user_name="" # blank string by default
  user_password=""
  cypher_format_arg="--format verbose " # need extra space at end for param validation test
  no_login_needed="N"
  external_editor="N"
  save_all="N"
  save_cypher="N"
  save_results="N"
  show_cmd_line="N"
  time_qry="N"
  quiet_output="N"
  cypherShellInfoArg=""
  coll_args=""
  use_params=""
  input_cypher_file_name=""
  use_this_cypher_shell=""

  while [ ${#@} -gt 0 ]
  do
     case ${1} in
       # -u, -p, -P and --format are cypher-shell arguments that may affect
       # how cypher-shell is called
       # string parameters vals are in in double quotes: --param 'id => "Z4485661"'
      -u | --username ) # username to connect as.
         getOptArgs 1  "$@"
         user_name="${_currentParam} ${_retOpts}"
         coll_args="${coll_args} ${user_name}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -p | --password ) # username to connect as.
         getOptArgs 1  "$@"
         user_password="${_currentParam} ${_retOpts}"
         coll_args="${coll_args} ${user_password}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -C | --cypher-shell ) # username to connect as.
         getOptArgs 1  "$@"
         use_this_cypher_shell="${_retOpts}"
         coll_args="${coll_args} ${use_this_cypher_shell}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -P | --param)
         getOptArgs 1  "$@"
         use_params="${use_params} ${_currentParam} '${_retOpts}'"
         coll_args="${coll_args} ${use_params}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -f | --file ) # cypher file name
         getOptArgs 1 "$@"
         input_cypher_file="${_currentParam} ${_retOpts}"
         input_cypher_file_name="$(echo ${input_cypher_file} | sed -E -e 's/(--file|-f)[[:space:]]*//')"
         shift $_shiftCnt # go past number of params processed
         coll_args="${coll_args} ${input_cypher_file}"
         ;;
      --format)
         getOptArgs 1 "$@"
         # note the extra space at end of cypher_format_arg makes validation testing below easier
         cypher_format_arg="${_currentParam} ${_retOpts} "
         shift $_shiftCnt # go past number of params processed
         coll_args="${coll_args} ${cypher_format_arg}"
         ;;
        # one and done cyphe-shell command line options
      -v | --version | --driver-version) # keep cypher queries and output results files.
         getOptArgs 0 "$@"
         cypherShellInfoArg=${_currentParam}
         shift $_shiftCnt
         ;;
        # begin shell specific options
        # save optoins
      -A | --saveAll) # keep cypher queries and output results files.
         getOptArgs 0 "$@"
         save_all="Y"
         coll_args="${coll_args} ${_currentParam}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -S | --saveCypher) # keep the cypher queries around for future use.
         getOptArgs 0 "$@"
         save_cypher="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -R | --saveResults) # keep the cypher queries around for future use.
         getOptArgs 0 "$@"
         save_results="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
        # editor options
      -V | --vi)
         getOptArgs 0 "$@"
         external_editor="Y"
         use_vi="vi " # start in start input mode
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -E | --editor)
         getOptArgs -1  "$@"
         external_editor="Y"
         use_editor="${_retOpts}"
         coll_args="${coll_args} ${_currentParam}"
         shift $_shiftCnt # go past number of params processed
         ;;
        # run options
          # override default less options
          # '-' and '--' command line options for less must have '-' prepended
          # with a backslash e.g. -L '\-\-line-numbers'
      -L | --lessOpts )
         getOptArgs -1 "$@"
         less_options="${_retOpts}"
         less_options=$(echo ${_retOpts} | sed -e 's/\\//g') # remove '\' from '\-'
         coll_args="${coll_args} ${_currentParam} ${_retOpts}"
         shift $_shiftCnt # go past number of params processed
         ;;
      -c | --showCmdLn ) # show command line args in output
         getOptArgs 0 "$@"
         show_cmd_line="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -t | --time) # print time elapsed between sending query and getting resutls file
         getOptArgs 0 "$@"
         time_qry="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -q | --quiet ) # minimal output
         getOptArgs 0 "$@"
         quiet_output="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -1 | --one) # run query execution loop only once
         getOptArgs 0 "$@"
         run_once="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -N | --noLogin) # flag to say don't need login prompt
         getOptArgs 0 "$@"
         no_login_needed="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;
      -X | --exitOnError )
         getOptArgs 0 "$@"
         exit_on_error="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift $_shiftCnt # go past number of params processed
         ;;

      -h | --help)
         dashHelpOutput
         exitShell ${RCODE_SUCCESS}
         ;;
      -U | --usage)
        usage
        exitShell ${RCODE_SUCCESS}
        ;;

        # treat everything elase as cypher-shell commands.  cypher-shell call
        # will have to check for invalid arguments
      *)
         getOptArgs -1 "$@"
         cypherShellArgs="${cypherShellArgs} ${_currentParam} ${_retOpts}"
         #cypherShellArgs="${cypherShellArgs} ${_currentParam}"
         shift $_shiftCnt # go past number of params processed
         coll_args="${coll_args} ${cypherShellArgs}"
         ;;
      "")
         break # done with loop
         ;;
     esac
  done

  # can be multiple param flags, want final value for var with command line args
  # coll_args="${coll_args} ${use_params}"

  # first ck if have a one-and-done argument
  if [[ ! -z ${cypherShellInfoArg} ]]; then
     runCypherShellInfoCmd ${cypherShellInfoArg} # run info cmd and exit
  fi
   # parameter checks.  well, kinda

  retCode=0 
  echo "${cypher_format_arg}" | grep -q -E ' auto | verbose | plain '
  if [[ $? -ne 0 ]]; then # invalid format option
    messageOutput "Invalid --format option '${cypher_format_arg}'."
    retCode=${RCODE_INVALID_FORMAT_STR}
  fi

  if [[ ${show_cmd_line} == "Y" || ${time_qry} == "Y" ]] && [[ ${quiet_output} == "Y" ]]; then
    messageOutput "Invalid command line options. Do not specify show command line opts and / or query time with quiet option. Bye."
    retCode=${RCODE_INVALID_CMD_LINE_OPTS}
  fi

  if [[ ${use_editor} && ${use_vi} ]]; then
    messageOutput "Invalid command line options.  Cannot use vi and another editor at the same time."
    retCode=${RCODE_INVALID_CMD_LINE_OPTS}
  fi

  if [[ ! -z ${input_cypher_file_name} && ! -f ${input_cypher_file_name} ]]; then # missing input file
    messageOutput "Missing file for parameter '${input_cypher_file}'."
    retCode=${RCODE_MISSING_INPUT_FILE}
  fi

  if [[ ${is_pipe} == "Y" ]]; then
    have_error="N"
    if [[ ${external_editor} == "Y" ]]; then  # could do this, but why?
      messageOutput "Cannot use external editor and pipe input at the same time."
      retCode=${RCODE_INVALID_CMD_LINE_OPTS}
    elif [[ ! -z ${input_cypher_file} ]]; then
      messageOutput "Cannot use input file and pipe input at the same time."
      retCode=${RCODE_INVALID_CMD_LINE_OPTS}
    fi
    if [[ ${retCode} -ne 0 ]]; then
      exec <&-  # close stdin
    fi
  fi

  if [[ ${retCode} -ne 0 ]]; then
    messageOutput "Command line parameters passed: ${coll_args}"
    messageOutput "Good Bye."
    exitShell ${retCode}
  fi

}

saveTheFiles () {
  # clean-up cypher and output files if not being kept
  if [[ ${save_all} == "N" ]]; then
    if [[ ${save_cypher} == "N" && -f ./${cypherFile} ]]; then
      rm -f ./${cypherFile} 2>/dev/null
    fi
    if [[ ${save_results} == "N" && -f ./${resultsFile} ]]; then
      rm -f ./${resultsFile} 2>/dev/null
    fi
  fi
}

intermediateFileHandling () {
  # flags on what to do with files and userEditor to keep
  # current query file around for editing (overwrite new cypherFile)
  if [[ ${external_editor} == "Y" && ${edit_cnt} -ne 0 ]]; then
    cp ${cypherFile} ${TMP_FILE}
  fi

  saveTheFiles # cleanup intermediate files

   # set new file names
  date_stamp=$(date +%FT%I-%M-%S%p) # avoid ':' sublime interprets : as line / col numbers
  printf -v cypherFile "%s%03d.%s_%s%s" ${OUTPUT_FILES_PREFIX} ${success_run_cnt} ${date_stamp} ${SESSION_ID} ${QRY_FILE_POSTFIX}
  printf -v resultsFile "%s%03d.%s_%s%s" ${OUTPUT_FILES_PREFIX} ${success_run_cnt} ${date_stamp} ${SESSION_ID} ${RESULTS_FILE_POSTFIX}

  if [[ ${edit_cnt} -eq 0 && ! -z ${input_cypher_file} ]]; then # have input cypher file
    cp ${input_cypher_file_name} ${cypherFile}
  elif [[ ${external_editor} == "Y" && ${edit_cnt} -ne 0 ]]; then
    mv ${TMP_FILE} ${cypherFile} # cypher error external editor, use last file
  fi
}
 
# HERE BE DRAGONS
# if you mess with the shell, make sure that the file variables exist and keep the test in 
# because the find command with the -exec rm {} and a '*' wildcard can be VERY dangerous. Just say'm
exitCleanUp() {

  if [[ -z ${OUTPUT_FILES_PREFIX} || -z ${SESSION_ID} || -z ${QRY_FILE_POSTFIX} ]]; then
    messageOutput "INTERNAL ERROR: Missing variable value \
                  OUTPUT_FILES_PREFIX = ${OUTPUT_FILES_PREFIX} SESSION_ID = ${SESSION_ID} QRY_FILE_POSTFIX = ${QRY_FILE_POSTFIX}"
    exitShell "INTERNAL_ERROR"
  fi

  saveTheFiles # cleanup intermediate files

  if [[ ${save_cypher} == "Y" || ${save_results}  == "Y" || ${save_all}  == "Y" ]]; then
     # note extra $(( )) is to remove spaces from wc result for implementations that pad with spaces
    fileCnt=$(($(find . -maxdepth 1 -type f -name "${OUTPUT_FILES_PREFIX}*${SESSION_ID}*" -print | wc -l)))
    if [[ ${fileCnt} -ne 0 ]]; then
      messageOutput "**** Don't forget about the ${fileCnt} saved files with session id ${SESSION_ID} ****"
    fi
  else # cleanup any files from this session hanging around
    find . -maxdepth 1 -type f -name "${OUTPUT_FILES_PREFIX}*${SESSION_ID}${QRY_FILE_POSTFIX}"  -exec rm {} \;
    find . -maxdepth 1 -type f -name "${OUTPUT_FILES_PREFIX}*${SESSION_ID}${RESULTS_FILE_POSTFIX}"  -exec rm {} \;
  fi
  # clean up cypher-shell message and tmp files used for less
  find . -maxdepth 1 -type f -name "${TMP_FILE}" -exec rm {} \; # remove message and temp file
  find . -maxdepth 1 -type f -name "${TMP_DB_CONN_FILE}.*"  -exec rm {} \; # remove message and temp file
  if [[ ${is_pipe} == "N" ]]; then
    stty echo sane # reset stty just in case
  fi
}

# exit shell with return code passed in
exitShell() {
  if [ "${1}" -ne "${1}" ] 2>/dev/null; then # not an integer, then internal error
    retCode=-1
  elif [[ -z ${1} ]]; then # Ctl-C sent
    retCode=0
  else
    retCode=${1}
  fi
  exitCleanUp
  exit ${retCode}

}

# validate cypher-shell in PATH
haveCypherShell () {
  # ck to see if you can connect to cypher-shell w/o error
  if [[ ${use_this_cypher_shell} == "" ]]; then
    if [[ $(which cypher-shell > /dev/null;echo $?) -ne 0 ]]; then
      messageOutput "*** Error: cypher-shell not found.  Bye."
      exitShell ${RCODE_CYPHER_SHELL_NOT_FOUND}
    else
      use_this_cypher_shell=$(which cypher-shell)
    fi
  elif [ ! -x ${use_this_cypher_shell} ]; then
    messageOutput "*** Error: --cypher-shell ${use_this_cypher_shell} parameter value for full path to cypher-shell not found or is not executable.  Bye."
    exitShell ${RCODE_CYPHER_SHELL_NOT_FOUND}
  fi
}

 # need to do our own uid / pw input when not getting cypher pasted in
getCypherShellLogin () {

  if [[ ${no_login_needed} == "N" ]]; then
      # get user name if needed
    if [[ -z ${user_name} && -z ${NEO4J_USERNAME} ]]; then # uid not in env var or command line
      if [[ ${is_pipe} == "Y" ]]; then
        messageOutput "Missing username needed for non-interactive input (pipe). Bye."
        exitShell ${RCODE_NO_USER_NAME}
      fi
      printf 'username: '
      read user_name
      user_name=" -u ${user_name} "  # for command line if needed
    fi
      # get password if needed
    if [[ -z ${user_password}  && -z ${NEO4J_PASSWORD} ]]; then # pw not in env var or command line
      if [[ ${is_pipe} == "Y" ]]; then
        messageOutput "Missing password needed for non-interactive input (pipe). Bye."
        exitShell ${RCODE_NO_PASSWORD}
      fi
      stty -echo # turn echo off
      printf 'password: '
      read user_password
      user_password=" -p ${user_password} "  # for command line if needed
      stty echo  # turn echo on
      echo
    fi
  fi

}

 # look to see if this shell launch statement is included in the input and
 # remove it if shell has already been run
cleanAndRunCypher () {

  cypher_shell_cmd_line="${1}" # cypher-shell command line options

  sed -i '' "/.*${shellName}.*/d" ${cypherFile}  # delete line with a call to this shell if necessary
  # check to see if the cypher file is empty
  grep --extended-regexp --quiet -e '[^[:space:]]' ${cypherFile} >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    cypherRetCode=${RCODE_EMPTY_INPUT} # do not run cypher, trigger continue or exit msg
    messageOutput "Empty input. No cypher to run."
  else   # put in semicolon at end if needed, command line opts / run cypher-shell
    sed '1!G;h;$!d' ${cypherFile} | awk 'NF{print;exit}' | grep --extended-regexp --quiet '^.*;\s*$|;\s*//.*$'
    if [[ $? -ne 0 ]]; then
      printf "%s" ";" >> ${cypherFile}
    fi
     # run cypher in cypher-shell
    if [[ ${show_cmd_line} == "Y" ]]; then # show command line arguments for this script
      printf "\nScript started with: %s\n\n" "${coll_args}" > ${resultsFile}
    else
      cat /dev/null > ${resultsFile}
    fi

    # eval cypher-shell "${cypher_shell_cmd_line}" < ${cypherFile}  >> ${resultsFile} 2>&1
    # all of THIS just to get to here
    eval "${use_this_cypher_shell}" "${cypher_shell_cmd_line}" < ${cypherFile}  >> ${resultsFile} 2>&1

    if [[ $? -ne 0 ]]; then
      cypherRetCode=${RCODE_CYPHER_SHELL_ERROR}
    else
      cypherRetCode=0
    fi
  fi
}

verifyCypherShell () {
  # connect to cypher-shell and get details
  messageOutput "Connecting to database"
  cypherFile="${TMP_DB_CONN_FILE}${QRY_FILE_POSTFIX}"

   # set intermediate file names that are not part of user query processing
  resultsFile="${TMP_DB_CONN_FILE}${RESULTS_FILE_POSTFIX}"

  echo $db_ver_qry > ${cypherFile}    # get database version query
  getCypherShellLogin # get cypher-shell login credentials if needed
  cleanAndRunCypher "${user_name} ${user_password} ${cypherShellArgs} --format plain"
  if [[ ${cypherRetCode} -eq 0 ]]; then # clean login to db

    if [[ ${quiet_output} == "N" && ${is_pipe} == "N" ]]; then
      msg_arr=($(tail -1 ${resultsFile} | tr ', ' '\n')) # tr for macOS
      db_version=${msg_arr[@]:0:1}
      db_edition=${msg_arr[@]:1:1}
      db_username=${msg_arr[@]:2:1}
      #  v 4, db.info gives you current database name
      # db.info -> 	"neo4j"	"2020-08-03T16:54:43.627Z"
      # dbms.components -> "Neo4j Kernel"	["4.1.1"]	"community"
      #  v 3
      # db.components -> 	["3.5.20"]	"community"
      printf -v msg "Using Neo4j %s version %s as user %s" ${db_edition} ${db_version} ${db_username}

      if [[ ${db_version} == *$'4.'* ]]; then
         # let's assume this works, and it's OK if it doesn't
        echo "${db_40_db_name_qry}" > ${cypherFile}
        cleanAndRunCypher "${user_name} ${user_password} ${cypherShellArgs} --format plain"

        msg_arr=($(tail -1 ${resultsFile} | tr ', ' '\n')) # tr for macOS
        db_name=${msg_arr[@]:0:1}
        msg="${msg} using database ${db_name}"

      fi
      rm -f ${cypherFile} ${resultsFile}
      clear
      messageOutput "${msg}"
    fi
  else # ERROR cypherRetCode != 0
    messageOutput "ERROR: cypher-shell return code: ${cypherRetCode}"
    messageOutput "Script started with: ${coll_args}"
    messageOutput "Ran: cypher-shell ${cypher_shell_cmd_line} "
    messageOutput "cypher-shell results:"
    messageOutput "$(cat ${resultsFile})"
    rm -f ${cypherFile} ${resultsFile}
    exitShell ${cypherRetCode}
  fi

}

# input cypher text, either from pipe, editor, or stdin (usually terminal window in editor)
getCypherText () {
  # { cat <&3 3<&- & } 3<&0 > ${cypherFile}

  if [[ ! -z ${input_cypher_file_name} ]]; then # running from a file, already set in intermediateFileHandling
    return
  fi
  if [[ ${external_editor} == "N" ]]; then
    if [[ ${is_pipe} == "N" ]]; then # input is from a pipe
      messageOutput "==> USE Ctl-D on a blank line to terminate stdin and execute cypher statement. ${edit_cnt} edits in this session"
      messageOutput "        Ctl-C to terminate stdin and exit ${shellName} without running cypher statement."
    fi
    cat /dev/null > ${cypherFile}
    while IFS= read -r line; do
       printf '%s\n' "$line" >> ${cypherFile}
    done
  else # using external editor
    while true; do
      if [[ ${use_editor} ]]; then
        eval ${use_editor} ${cypherFile}
      elif [[ ${use_vi} ]]; then
        if [[ ${edit_cnt} -eq 0 ]]; then
          eval "${use_vi} ${vi_initial_open_opts} ${cypherFile}" # open file option +star (new file)
        else
          eval ${use_vi} ${cypherFile}
        fi
      fi
      # ask user if they want to run file or go back to edit
      yesOrNo "Run query (y) or continue to edit (n)? Ctl-C to exit ${shellName}? "
      if [[ $? -eq 1 ]]; then # answered 'n', continue
        continue  # go back to edit on same file
      else # answered yes to running query
        break
      fi # continue with new intermediate files
    done
  fi
  (( edit_cnt++ ))  # increment query edit count
}

# execution loop cypher error output
runtimeErrorOutput () {
  if [[ ${quiet_output} == "N" ]]; then
    messageOutput "Error running cypher statement(s). cypher-shell error code: ${cypherRetCode}"
    if [[ -f ${resultsFile} ]]; then # results file if it exists, will not with empty input cypher
      printf "=== Error Message:\n%s\n=== End of Error Output\n\n" "$(${use_pager} ${resultsFile})"
    fi
  fi
}

# main loop for running cypher-shell until termination condition
executionLoop () {

  while true; do
     # LESS: comment this out if using less --quit-at-eof type options
    if [[ ${edit_cnt} -gt 0 ]]; then # 0 means leave connection message
      clear # clear the terminal
    fi

    intermediateFileHandling  # intermediate files for cypher and output
    getCypherText  # consume input

    qry_start=$(date +%s)
    messageOutput "Starting query execution: $(date)"
    cleanAndRunCypher "${user_name} ${user_password} ${use_params} ${cypherShellArgs} ${cypher_format_arg}"

    if [[ ${time_qry} == "Y" ]]; then # put execution time in results file
      printf '%s %s\n\n%s' "${TIME_OUTPUT_HEADER}" "$(printTimeFromSeconds $(($(date +%s) - ${qry_start})))" "$(cat ${resultsFile})" >${resultsFile}
    fi

    if [[ ${cypherRetCode} -eq 0 ]]; then
      messageOutput "Finished query execution and output file creation: $(date)"
      ${use_pager} ${less_options} ${resultsFile}
      (( success_run_cnt ++ ))
      if [[ ${external_editor} == "Y" ]]; then # don't go straight back into editor
        printContinueOrExit
      fi
    else # ERROR running cypher code
      if [[ ${exit_on_error} == "Y" || ${is_pipe} == "Y" ]]; then # print error and exit
        runtimeErrorOutput
        exitShell ${cypherRetCode}
      elif [[ ${cypherRetCode} != ${RCODE_EMPTY_INPUT} ]]; then # error message can be long, esp multi-stmt. send through pager
        runtimeErrorOutput
        printContinueOrExit
      fi
    fi
    if [[ ${run_once} == "Y" || ${is_pipe} == "Y" ]]; then # exit shell if run 1, or is from a pipe
      exitShell ${cypherRetCode}
    fi

  done
}

# main
#trap exitShell ${cypherRetCode} EXIT
trap exitShell SIGINT 


setDefaults
getArgs "$@"
haveCypherShell
verifyCypherShell   # verify that can connect to cypher-shell
executionLoop       # execute cypher statements
exitShell 0
