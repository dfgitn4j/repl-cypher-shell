# script to front-end cypher-shell and pass output to pager

usage() {

  if [[ ${quiet_output} == "N" ]]; then # usage can be called when error occurs
  cat << USAGE

 NAME

  ${SHELL_NAME}
   - Frontend to cypher-shell with REPL flavor on command line, in a text editor embedded
     terminal (e.g. Sublime Text, atom, VSCode, IntelliJ), with output sent through a pager. 

 SYNOPSIS

  ${SHELL_NAME}

  ** cypher-shell main options **

  [-u | --username]  cypher-shell username parameter.
  [-p | --password]  cypher-shell password parameter.
  [-P | --param]     Parameter stings strings. Run --help for how to use.
  [-f | --file]      File containing query.
  [--format]         cypher-shell --format option.
  
  ** Query output save options **

  [-A | --saveAll]     [allFilesPrefix]   Save cypher query and output results 
                                          files with optional user set prefix.
  [-R | --saveResults] [resultFilePrefix] Save each results output in to a file 
                                          with optional user set prefix.
  [-S | --saveCypher]  [cypherFilePrefix] Save each query statement in a file
                                          with optional user set prefix.
  [-D | --saveDir]     [dirPath]          Directory to save files to.  Default 
                                          is ${DEF_SAVE_DIR} if dirPath is not provided. 

  ** Editor options to use when running from command line **

  [-E | --editor] [cmd]  Use external editor. Run --help for how to use.
  [--nano]               Use nano editor started with 'nano -t' flag.
  [-V | --vi]            Use vi editor.

  ** Runtime options **

  [-C | --cypher-shell]    Path to cypher-shell to use.
  [-c | --showCmdLn]       Show script command line args in output.
  [-i | --incCypher]       Include cypher query at begining of output.
  [-I | --incCypherAsCmnt] Include commented cypher query at beginning of output.
  [-L | --lessOpts] [opts] Use these less pager options instead of defaults.  
  [-N | --noLogin]         Login to Neo4j database not required. 
  [-q | --quiet]           No informational output messages.
  [-t | --time]            Output query start time.
  [-1 | --one]             Run query execution loop only once and exit.
  [-X | --exitOnError]     Exit script on error.

  ** Usage **

  [-U | --usage]           Command line parameter usage only.
  [-h | --help]            Detailed help message.

  *** remaining parameters ***

  [*] ANY other parameters are passed through as is to cypher-shell.
      Invalid parameters will be caught by cypher-shell.
USAGE
  fi
}

dashHelpOutput() {

  cat << THISNEEDSHELP

 $(usage)

 DESCRIPTION

  ${SHELL_NAME} is a front-end wrapper to cypher-shell that executes cypher
  statements and pipes the output into the less pager with options to save
  output. There are two execution scenarios where different command line options
  can apply:

  1) Embedded Terminal

    Run cypher commands and page through output using in an IDE terminal window
    or editors such as atom or sublime text 3 that can send selected text to an
    embedded or external terminal.

    Some editors, such as sublime text have the capability to modify text before
    being sent to a terminal window.  This allows for inserting the keystrokes
    to terminate stdin by sending a newline and Ctl-D to close stdin and pass
    the text to cypher-shell for execution. Otherwise the user must change window
    focus and enter Ctl-D on a newline to start execution.  Sublime Text 3 user
    packages are used to extend the sublime functionality see the documentation or
    https://www.youtube.com/watch?v=lBgDilqulxg&feature=youtu.be as a starting point.

    There is a basic User package and key binding config in the EDITOR_MAPPING 
    directory.

  2) Command Line

     Run cypher commands through ${SHELL_NAME} from the command line. Cypher
     input can be copy / paste, direct entry via an editor or stdin, or piped in.
     The default input and editing is through stdin. It is suggested that the
     --vi option for a seamless REPL experience. External gui editors can be
     used but must be exited for the query to run. It is better to call 
     ${SHELL_NAME} from an terminal embedded in a gui editor to get the same
     REPL experience. 

     Neo4j Desktop terminal provides a database compatible version of cypher-shell,
     but you may have to use the -C | --cypher-shell parameter to tell ${SHELL_NAME}
     where to find it.

  NOTE: The :use database statement does not persist across queries. Each
        new query run will execute in the database ${SHELL_NAME} was
        started with unless a :use database statement is part of the query.

 OPTIONS

  -u | --username <Neo4j database username> 
  
    Database user name. Will override NEO4J_USERNAME if set.

  -p | --password <Neo4j database password>
  
    Database password. Will override NEO4J_USERNAME if set.

  -C | --cypher-shell <path to cypher-shell executable>

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
  
    cypher shell version commands. Run and exit.

  -A [allFilesPrefix] | --saveAll [allFilesPrefix])
  
    Save all cypher queries and output in individual files in the current 
    directory. The default is to name the files with a timestamp and session 
    identifiers.  Files will be in current directory with the format:
  
      cypher query: ${OUTPUT_FILES_PREFIX}_[datetime query was run]_[session ID]-[qry nbr]${QRY_FILE_POSTFIX}
      results text: ${OUTPUT_FILES_PREFIX}_[datetime query was run]_[session ID]-[qry nbr]${RESULTS_FILE_POSTFIX}
  
      For example:

      cypher query: $(printf "%s_%s_%s-%d%s" "${OUTPUT_FILES_PREFIX}" "$(date +%FT%I-%M-%S%p)" "${SESSION_ID}" 1 "${QRY_FILE_POSTFIX}")
      results text: $(printf "%s_%s_%s-%d%s" "${OUTPUT_FILES_PREFIX}" "$(date +%FT%I-%M-%S%p)" "${SESSION_ID}" 1 "${RESULTS_FILE_POSTFIX}")

    The optional parameter [allFilesPrefix]-[qry nbr].[cypher|txt] will be used instead of the default
    file naming above. 
  
  -R [resultFilePrefix] | --saveResults [resultFilePrefix])
      
    Save query results to a file in the current directory. The file will have the
    same timestamp and session identifier in the file name as the query results
    file if it is also kept.  Files will be in current directory with the
    format as described in --saveAll

  -S [cypherFilePrefix] | --saveCypher [cypherFilePrefix])
  
    Save cypher query to a file in the current directory. The file will have the
    same timestamp and session identifier in the file name as the query results
    file if it is also kept.  Files will be in current directory with the
    format as described in  --saveAll

  -V | --vi)
  
    Use vi editor for cypher input instead of stdin.  Use when running from
    command line versus and embedded terminal.

  --nano)
  
    Use nano editor started with 'nano -t' flag for convenience.

  -E | --editor <'editor command line with options'>
  
    Define an editor that can be started from the command line in insert mode.
    This *requires* '<editor command line with options>' be single quotes if
    there are command line options needed.  For example to launch nano, atom,
    or sublime:

     sublime: ${SHELL_NAME} -E 'subl --new-window --wait'
        atom: ${SHELL_NAME} -E 'atom --new-window --wait'

  -L | --lessOpts <'less command options'>
  
    [opts] for the --lessOpts parameter require escaping the first command line
    option that begin with '-' and '--' by prepending each '-' with a '\'
    backslash. E.g. for the script's --lessOpts that defines options to run the
    less pager with using the less --LINE-NUMBERS and --chop-long-lines would be 
    submitted to ${SHELL_NAME} as:

       --lessOpts '\-\-LINE-NUMBERS --chop-long-lines'

    ** --QUIT-AT_EOF ** if any of the less options for quit at end of file may
    end up with a blank screen for output that does not fill the complete
    terminal screen.  Change clear command in script if this is an issue.

  -c | --showCmdLine 
  
    Print the command line arguments the script was called for every query.

  -t | --time 
  
    Output query start time.

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
  
         ${SHELL_NAME} -a <ip address>

 INSTALLATION

  1. Install cypher-shell and validate that it is compatible with the targeted version(s) of 
     the Neo4j Graph Database.  Suggesting using a 4.x version of cypher-shell. Alternative is
     to use the --cypher-shell parameter to specify a cypher-shell installation to use. 

  2. Download ${SHELL_NAME} from github (https://github.com/dfgitn4j/repl-cypher-shell).

  2. Make file executable (e.g. chmod 755 ${SHELL_NAME}).

  3. Place in directory that is in the PATH variable. For example /usr/local/bin
     seems to be good for mac's because it's in the PATH of the Neo4j Desktop
     termininal environment.


 EXAMPLES

  See https://github.com/dfgitn4j/repl-cypher-shell for visual examples using embeddedd 
  terminals in atom, sublime, etc.

  WINDOWED TEXT EDITOR (e.g. Sublime Text 3, atom, VSCode, etc.)

  Assuming you have this text in an editor window:

    repl-cypher-shell.sh

    MATCH (n) RETURN n LIMIT 10
 
  1. Open an embeded terminal window, e.g. _terminus_ for _Sublime Text 3_ or _platformio-ide-terminal_.

  2. Start  ${SHELL_NAME}

     - Highlight the  ${SHELL_NAME} line in the editor and transfer it to the terminal window through 
       copy-paste-into-terminal key sequence, or just copy and paste into the terminal.

     - Hit Enter key in the terminal window to start the shell if needed. A user name and password will
       be asked for if it's needed.

  2. Run Cypher

     - Repeat the same with the MATCH text if needed and hit ctl-D.

  3. Consume Output

     - Page through the output in the terminal window since it's going through less. I especially like 
       the horizontal scrolling capabilities in less for wide rows. 

  4. Repeat

     - cypher-shell input is still active

  NOTE: Input is through stdin so there's no real editing keys in the terminal input, but that's what the
  editor is for. 


  COMMAND LINE (REPL kind of workflow)

  1. Add  ${SHELL_NAME} in PATH if needed (e.g. /usr/local/bin)

  2. Determine which cypher-shell to use and then run  ${SHELL_NAME}
    
     a. Run  ${SHELL_NAME} in a terminal environment that has a version of cypher-shell that is 
        compatible with the database version being connected to in the PATH environment variable. 

     b. Use the -C | --cypher-shell command line option to specify the cypher-shell install. 
        This is useful when you do not have a standalone cypher-shell installed. To do this, open
        a Neo4j Desktop terminal window for the currently running database and run this command from 
        the command line prompt:

        ${SHELL_NAME} --cypher-shell ./bin/cypher-shell

        !!! It's bad practice to work in the initial directory the shell starts
        in if in a  Neo4j Desktop launched terminal. Mistakes happen, and _any_ files
        you created will be gone if you delete the  database through Neo4j Desktop. 
        Suggestion is to capture the Neo4j Desktop install directory and the cd to 
        another, non-Neo4j Desktop managed directory.  For example, on launching a Neo4j
        Desktop terminal:


        n4jcypshell="$(pwd)/bin/cypher-shell"
        cd ~/MyWorkingDirectory
        ${SHELL_NAME} --cypher-shell $n4jcypshell --vi


  EXAMPLES

    - Run cypher-shell with Neo4j database username provided and ask for a
      password if the NEO4J_PASSWORD environment variable is not set:

        ${SHELL_NAME} -u neo4j

    - Use vi editor and keep an individual file for each cypher command run and save 
      cypher query and results output files:

        sTrp-cypher-shell.sh --vi -u neo4j --time --saveAll

    - Use sublime as the editor. Expected scenario is to run
      ${SHELL_NAME} from a terminal window *within* the gui editor:

       ${SHELL_NAME} --saveCypher -E 'subl --new-window --wait'

      See https://www.sublimetext.com/docs/3/osx_command_line.html

THISNEEDSHELP
}

setConstants() {
  DB_VER_QRY="CALL dbms.components() YIELD name, versions, edition
  WITH name, versions, edition WHERE name='Neo4j Kernel'
  CALL dbms.showCurrentUser() YIELD username
  RETURN versions, edition, username;"

  DB_4x_NAME_QRY="CALL db.info() YIELD name as db_name RETURN db_name;"

   # exit codes
   # IMPORTANT for testing scripts where grep is used to get the names and codes
   # Variables must begin with 'RCODE_'  and follow var=<nbr> pattern with nothing else on the line
   # Codes must be sequential starting at 0
   # Return codes are meant mostly for non-interactive (e.g. run once) or critical error exit
   # cypher-shell returns 1 on any failure
  RCODE_SUCCESS=0
  RCODE_CYPHER_SHELL_ERROR=1
  RCODE_INVALID_CMD_LINE_OPTS=2
  RCODE_CYPHER_SHELL_NOT_FOUND=3
  RCODE_INVALID_FORMAT_STR=4
  RCODE_NO_USER_NAME=5
  RCODE_NO_PASSWORD=6
  RCODE_EMPTY_INPUT=7
  RCODE_MISSING_INPUT_FILE=8
  RCODE_NO_WRITE_PERM=9
  RCODE_INTERNAL_ERROR=100
}

setDefaults () {
  setConstants

  [ -p /dev/fd/0 ] && is_pipe="Y" || is_pipe="N"   # pipe input?

  edit_cnt=0              # count number of queries run, controls stdin messaging.
  file_nbr=0              # output file number if query / results file(s) are saved
  # db_name=""            # will only be populated on neo4j 4.x databases
  save_dir="./"           # directory to use for any output files, including tmp files
  find_dir="."            # directory to use for find
  DEF_SAVE_DIR="RCP_SAVE" # default save directory if none specified with --saveDir option
  lastCypherFile=""       # last cypher file != "" if using editor and saving files, used to keep editing same file

  CS_FORMAT_OPT="--format verbose " # need extra space at end for param validation test
  LESS_DEF_OPT="--LONG-PROMPT --shift .005"
  VI_INITIAL_OPEN_OPTS=' +star '  # Start first exec for vi in append mode.


   # variables used in file name creation
   # file patterns are in the form of:
   # ${OUTPUT_FILES_PREFIX} ${date_stamp} ${SESSION_ID} ${file_nbr} (${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})
  SESSION_ID="${RANDOM}" # nbr to id this session. For when keeping intermediate cypher files
  QRY_FILE_POSTFIX=".cypher" # postfix for all intermediate files
  RESULTS_FILE_POSTFIX=".txt"
  OUTPUT_FILES_PREFIX="qry"  # prefix all intermediate files

  TMP_DB_CONN_QRY_FILE="tmpDbConnectTest.${SESSION_ID}${QRY_FILE_POSTFIX}"
  TMP_DB_CONN_RES_FILE="tmpDbConnectTest.${SESSION_ID}${RESULTS_FILE_POSTFIX}"
  cypherRetCode=${RCODE_SUCCESS} # cypher-shell return code
}

ckSetVarValues() {
  # bad things can happen if any of these shell variables are not set
  if [[ ! -n ${SESSION_ID} || \
        ! -n ${QRY_FILE_POSTFIX} || \
        ! -n ${RESULTS_FILE_POSTFIX} || \
        ! -n ${OUTPUT_FILES_PREFIX} || \
        ! -n ${TMP_DB_CONN_QRY_FILE} || \
        ! -n ${TMP_DB_CONN_RES_FILE} || \
        ! -n ${save_dir} ||
        ! -n ${find_dir} ]] ; then
    messageOutput "*** INTERNAL ERROR found by ckSetVarValues() - Missing needed internal shell variable. Sorry about that." Y "\n%s\n\n"
    messageOutput "SESSION_ID='${SESSION_ID}' QRY_FILE_POSTFIX='${QRY_FILE_POSTFIX}' RESULTS_FILE_POSTFIX='${RESULTS_FILE_POSTFIX}'" N
    messageOutput "OUTPUT_FILES_PREFIX='${OUTPUT_FILES_PREFIX}' TMP_DB_CONN_QRY_FILE='${TMP_DB_CONN_QRY_FILE}' TMP_DB_CONN_RES_FILE='${TMP_DB_CONN_RES_FILE}'" N
    messageOutput "save_dir='${save_dir}' find_dir='${find_dir}'" N
    exitShell ${RCODE_INTERNAL_ERROR}
  fi
}

getOptArgs() {

  # getOptArgs - gets 0 or more flag options, sets a var with the vals in arg_ret_opts for a flag until next
  #  flag, and sets arg_shift_cnt as the number of options found to shift the source array
  #  and does error cking.
  #    1st param = expected number of parameters, -1 = no limit (i.e. -f abc 1 dca -a will return abc 1 dca)
  #    2nd param = error message
  #    3rd param = options passed in
  #
  #  i.e called with getOptArgs -1 "my error" "-f abc 1 dec -a" will set:
  #      arg_ret_opts="abc 1 dec"
  #      arg_shift_cnt=3
  # calling function then needs to shift it's input array by arg_shift_cnt

  arg_ret_opts=""  # init no options found
  arg_nbr_expected_opts="${1}"  # nbr options expected
  shift
  _currentParam=${1}
  shift  # $@ should now have remaing opts, if any
  arg_shift_cnt=1

  if [[ ${arg_nbr_expected_opts} == 0 ]]; then
    if [[ ${1} != -* ]] && [[ ${1} ]]; then
      messageOutput  "No option expected for ${_currentParam}. Bye."
      exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
    fi
  elif [[ ${arg_nbr_expected_opts} -eq 1 ]]; then
    if [[ ${1} == -* ]] || [[ ! ${1} ]] ; then
      messageOutput "Missing options for: ${_currentParam}. Bye."
      exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
    else # valid one param option
      arg_ret_opts="${1}"
      (( arg_shift_cnt++ )) # shift over flag and single parameter
    fi
  else # undefined pattern, 0 or unlimited options until next flag
    if [[ ${1} == -*  || ! ${1} ]]; then # flag only, e.g. --whyme
      arg_ret_opts="${1}"
    else # multi param
      while [[ ${1} != -*  &&  ${1} ]] ; do
        arg_ret_opts="${arg_ret_opts}${1}"
        if [[ ${arg_nbr_expected_opts} -ne -1 ]] && [[ ${arg_shift_cnt} -gt  ${arg_nbr_expected_opts} ]]; then
          messageOutput "Wrong options for ${_currentParam}. Bye."
          exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
        fi
        (( arg_shift_cnt++ ))
        shift
      done
    fi
  fi

  return 0
}

getArgs() {

  local _tmpStr # var for intermediate strings 
  # less options --shift .01 allows left arrow to only cut off beginning "|"
  # while scrolling at the expense of slower left arrow scrolling
  less_options="${LESS_DEF_OPT}"

  user_name=""               # blank string by default
  user_password=""

  cypher_format_arg="${CS_FORMAT_OPT}" 
  cypherShellArgs=""         # any args not in case stmt are assumed to be cypher-shell specific args passed in
  cypher_shell_cmd_line=""   # a string with all the cypher-shell specific command line opts, if passed in.
  no_login_needed="N"        # skip login prompting
  save_cypher="N"            # save each query in own file
  save_results="N"           # save each query output in own file
  save_all="N"               # save cypher and results files
  userSetSaveDir="N"         # Y if user defines a directory to save files to
  show_cmd_line="N"          # show command line args in output
  inc_cypher="N"             # output query before results output
  inc_cypher_as_comment="N"  # output commented query before results output
  cmd_arg_msg=""             # string to for command line arguments in output $show_cmd_line="Y"
  qry_start_time="N"         # time between query submit to cypher-shell and return
  quiet_output="N"           # no messages or prompts
  cypher_shell_info_arg=""   # any info flags passed: -v | --version | --driver-version
  coll_args=""               # all argumnents passed to script
  use_params=""              # query parameter arguments
  # input_cypher_file_name=""  # input file
  use_this_cypher_shell=""   # cypher-shell to use. mostly for desktop
  editor_to_use=""           # launch editor command line

  while [ ${#@} -gt 0 ]; do
     case ${1} in
       # Intercepted cypher-shell args that may require interaction with shell, or to capture values
       # -u, -p, -P and --format are cypher-shell arguments that may affect
       # how cypher-shell is called
       # string parameters vals are in in double quotes: --param 'id => "Z4485661"'
      -u | --username ) # username to connect as.
         getOptArgs 1  "$@"
         user_name="${_currentParam} ${arg_ret_opts}"
         coll_args="${coll_args} ${user_name}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -p | --password ) # username to connect as.
         getOptArgs 1  "$@"
         user_password="${_currentParam} ${arg_ret_opts}"
         coll_args="${coll_args} ${user_password}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -d | --database) 
           # intercept cypher-shell -d DATABASE parameter. Used to determine
           # which db to run query in based on last command line or last :use command
         getOptArgs 1 "$@"
         db_name="${arg_ret_opts}"
         coll_args="${coll_args} ${db_name}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -f | --file ) # cypher file name
         getOptArgs 1 "$@"
         _tmpStr="${_currentParam} ${arg_ret_opts}"
         input_cypher_file_name="$(echo "${_tmpStr}" | sed -E -e 's/(--file|-f)[[:space:]]*//')"
         shift "${arg_shift_cnt}" # go past number of params processed
         coll_args="${coll_args} ${_tmpStr}"
         ;;
      --format) # cypher-shell format option
         getOptArgs 1 "$@"
         # note the extra space at end of cypher_format_arg makes validation testing below easier
         cypher_format_arg="${_currentParam} ${arg_ret_opts} "
         shift "${arg_shift_cnt}" # go past number of params processed
         coll_args="${coll_args} ${cypher_format_arg}"
         ;;
      -P | --param)
         getOptArgs 1  "$@"
         use_params="${use_params} ${_currentParam} '${arg_ret_opts}'"
         coll_args="${coll_args} ${use_params}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -v | --version | --driver-version) # one and done cyphe-shell info options 
         getOptArgs 0 "$@"
         cypher_shell_info_arg="${_currentParam} ${cypher_shell_info_arg}"
         shift "${arg_shift_cnt}"
         ;;

      # begin repl-cypher-shell specific options
        # save options
      -A | --saveAll) # keep cypher queries and output results files.
         getOptArgs -1 "$@"
         save_all="Y"
         coll_args="${coll_args} ${_currentParam}"
         if [[ ${arg_shift_cnt} -eq 2 ]]; then 
           resultFilePrefix=${arg_ret_opts}
           cypherFilePrefix=${arg_ret_opts}
         elif [[ ${arg_shift_cnt} -gt 2 ]]; then
            messageOutput "Only one save all files prefix allowed. "  
            messageOutput "Invalid option: ${_currentParam}${arg_ret_opts}"
            messageOutput "Goodbye."
            exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
         fi     
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -D | --saveDir ) # keep the cypher queries around for future use.
         getOptArgs -1 "$@"
         coll_args="${coll_args} ${_currentParam} "
         if [[ ${arg_shift_cnt} -eq 1 ]]; then
           save_dir="${DEF_SAVE_DIR}"
         elif [[ ${arg_shift_cnt} -eq 2 ]]; then # dirctory name specified
           save_dir="${arg_ret_opts}"
         elif [[ ${arg_shift_cnt} -gt 2 ]]; then
           messageOutput "Only one save directory option allowed. "  
           messageOutput "Invalid option: ${_currentParam}${arg_ret_opts}"
           messageOutput "Goodbye."
           exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
         fi
         userSetSaveDir="Y"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -R | --saveResults ) # keep the cypher queries around for future use.
         getOptArgs -1 "$@"
         save_results="Y"
         coll_args="${coll_args} ${_currentParam} "
         if [[ ${arg_shift_cnt} -eq 2 ]]; then 
           resultFilePrefix=${arg_ret_opts}
         elif [[ ${arg_shift_cnt} -gt 2 ]]; then
            messageOutput "Only one save result file prefix allowed. "  
            messageOutput "Invalid option: ${_currentParam}${arg_ret_opts}"
            messageOutput "Goodbye."
            exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
         fi
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -S | --saveCypher ) # keep the cypher queries around for future use.
         getOptArgs -1 "$@"
         save_cypher="Y"
         coll_args="${coll_args} ${_currentParam} "
         if [[ ${arg_shift_cnt} -eq 2 ]]; then 
           cypherFilePrefix="${arg_ret_opts}"
         elif [[ ${arg_shift_cnt} -gt 2 ]]; then
            messageOutput "Only one save query file prefix allowed. "  
            messageOutput "Invalid option: ${_currentParam}${arg_ret_opts}"
            messageOutput "Goodbye."
            exitShell ${RCODE_INVALID_CMD_LINE_OPTS}
         fi
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;

        # editor options
      -E | --editor)
         getOptArgs -1  "$@"
         editor_to_use="${arg_ret_opts}"
         coll_args="${coll_args} ${_currentParam}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      --nano)
         getOptArgs 0 "$@"
         editor_to_use="nano -t" 
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -V | --vi)
         getOptArgs 0 "$@"
         editor_to_use="vi" 
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;

        # run options
      -C | --cypher-shell ) # path to cypher-shell to use
         getOptArgs 1  "$@"
         use_this_cypher_shell="${arg_ret_opts}"
         coll_args="${coll_args} ${use_this_cypher_shell}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -c | --showCmdLn ) # show command line args in output
         getOptArgs 0 "$@"
         show_cmd_line="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -i | --incCypher ) # output commented query at beginning of output
         getOptArgs 0 "$@"
         inc_cypher="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -I | --incCypherAsCmnt ) # output commented query at beginning of output
         getOptArgs 0 "$@"
         inc_cypher_as_comment="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -L | --lessOpts ) # override default less options
         getOptArgs -1 "$@"
         less_options="${arg_ret_opts}"
          # '-' and '--' command line options for less must have '-' prepended
          # with a backslash e.g. -L '\-\-line-numbers'
         less_options=$(echo ${arg_ret_opts} | sed -e 's/\\//g') # remove '\' from '\-'
         coll_args="${coll_args} ${_currentParam} ${arg_ret_opts}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -N | --noLogin) # flag to say don't need login prompt
         getOptArgs 0 "$@"
         no_login_needed="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -q | --quiet ) # minimal output
         getOptArgs 0 "$@"
         quiet_output="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -t | --time) # print time query started
         getOptArgs 0 "$@"
         qry_start_time="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -X | --exitOnError )
         getOptArgs 0 "$@"
         exit_on_error="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -1 | --one) # run query execution loop only once
         getOptArgs 0 "$@"
         run_once="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;

        # help options
      -h | --help)
         dashHelpOutput
         exitShell ${RCODE_SUCCESS}
         ;;
      -U | --usage)
        usage
        exitShell ${RCODE_SUCCESS}
        ;;

      "")
         break # done with loop
         ;;

        # treat everything elase as cypher-shell commands.  cypher-shell call
      *)
         getOptArgs -1 "$@"
         cypherShellArgs="${cypherShellArgs} ${_currentParam} ${arg_ret_opts}"
         #cypherShellArgs="${cypherShellArgs} ${_currentParam}"
         shift "${arg_shift_cnt}" # go past number of params processed
         coll_args="${coll_args} ${cypherShellArgs}"
         ;;
     esac
  done

  # can be multiple param flags, want final value for var with command line args
  # coll_args="${coll_args} ${use_params}"

  # first ck if have a one-and-done argument

   # parameter checks.  well, kinda
  return_code=${RCODE_SUCCESS} 

  if ! echo "${cypher_format_arg}" | grep -q -E ' auto | verbose | plain '; then
    messageOutput "Invalid --format option: '${cypher_format_arg}'."
    return_code=${RCODE_INVALID_FORMAT_STR}
  elif [[ ${is_pipe} == "Y" ]]; then
    if [[ -n ${editor_to_use} ]]; then  # could do this, but why?
      messageOutput "Cannot use external editor and pipe input at the same time."
      return_code=${RCODE_INVALID_CMD_LINE_OPTS}
    elif [[ -n ${input_cypher_file_name} ]]; then
      messageOutput "Cannot use input file and pipe input at the same time."
      return_code=${RCODE_INVALID_CMD_LINE_OPTS}
    fi
    if [[ ${return_code} -ne 0 ]]; then
      exec <&-  # close stdin
    fi
  elif [[ ${save_all} == "Y" ]] && [[ ${save_cypher} == "Y" || ${save_results} = "Y" ]]; then
    messageOutput "Cannot have save all set with either save cypher or results files simultaneously."
    return_code=${RCODE_INVALID_CMD_LINE_OPTS}
  elif [[ ${userSetSaveDir} == "Y" && ${save_all} == "N" && ${save_cypher} == "N" && ${save_results} == "N" ]]; then
    messageOutput "Set save directory without saving cypher or results files."
    return_code=${RCODE_INVALID_CMD_LINE_OPTS}
  elif [[ -n ${editor_to_use} && ${run_once} == "Y" ]]; then
    messageOutput "Invalid command line options.  Cannot use an editor and run once at the same time."
    return_code=${RCODE_INVALID_CMD_LINE_OPTS}
  elif [[ -n ${input_cypher_file_name} && ! -f ${input_cypher_file_name} && ! -n ${editor_to_use} ]]; then 
    messageOutput "Input file '${input_cypher_file_name}' does not exist."
    return_code=${RCODE_MISSING_INPUT_FILE}
  fi

  if [[ ${return_code} -ne 0 ]]; then # exit if any of the above fail
    messageOutput "Command line parameters passed to cypher-shell: ${coll_args}"
    messageOutput "Good Bye."
    exitShell ${return_code}
  fi
    # make sure we can write to output file / directory
  if [[ -n ${save_dir} ]]; then 
    find_dir="$(echo ${save_dir} | sed 's/\/*$//g')" # make sure no trailing /
    save_dir="${find_dir}/"  # make sure there's a trailing /
    mkdir -p "${save_dir}" 2>/dev/null
    return_code=$?
    if [[ ${return_code} -ne 0 ]]; then
      messageOutput "Cannot make save file directory ${save_dir}"
      exitShell ${RCODE_NO_WRITE_PERM}
    fi
  fi

   # validate write permissions
  local test_file="${save_dir}testDirPermissions.${RANDOM}.txt"
  touch ${test_file} 2>/dev/null
  return_code=$?
  if [[ ${return_code} -ne 0 ]]; then
    messageOutput "Cannot write file to directory $(pwd)"
     exitShell ${RCODE_NO_WRITE_PERM}
  else # can write file
    rm -f ${test_file}
  fi

  if [[ ${show_cmd_line} == "Y" ]]; then # output command line args
    cmd_arg_msg="Command line parameters: ${coll_args}"
  fi

  if [[ ${save_all} == "Y" ]]; then
    save_results="Y"
    save_cypher="Y"
  fi

  setCypherShellCmdLine  # string with all the cypher-shell only command line arguments. 
}

#
# MESSAGING FUNCTIONS
#
validFirstChar() {
  # match only the first first character of $1  
  # $2 is pattern to match, e.g. 'yqn'
  [[ $# -ne 2 ]] &&  exitShell ${RCODE_INTERNAL_ERROR}  # require 2 parameters

  printf -v _lookFor "%.1s" "${1}"
  local _inThis="${2}"
  echo "${_inThis}" | grep --extended-regexp --ignore-case --quiet -e "${_lookFor}"
  return $?
}

messageOutput() {  # to print or not to print
  # Not all messages to to output, some go to tty and results file to stdout
  # $1 is message $2 is optional format string for printf
  local _quote_string=${2:-"Y"}
  local _fmt_str=${3:-"%s\n"}
  if [[ ${quiet_output} == "N" ]]; then
    if [[ ${_quote_string} == "Y" ]]; then
      printf "${_fmt_str}" "${1}"  # quotes means print on one line (default)
    else
      printf "${_fmt_str}" ${1}  # no quotes to allow for space delimited output
    fi
  fi
}

enterYesNoQuit() {
  # ${1} is valid response pattern in form of "YNQynq", <CR> defaults to Yes
  # ${2} is the  message for the user
  # a little risky since $1 and $2 can be optional
  local _ret_code=0
  local _option

  [[ ${is_pipe} == "Y" ]] && return # pipe, no inteactive input

  local _valid_opts="${1:-ynq}"
  local _msg=${2:-"<Enter> | y <Enter> to continue, n <Enter> to return, q <Enter> to quit."}
  messageOutput "${_msg}" "Y" "\n%s"
  
  read -r _option 
  validFirstChar "${_option}" "${_valid_opts}"
  if [[ $? -ne 0 ]]; then
    messageOutput "'${_option}' is an invalid choice." "Y" "%s"
    enterYesNoQuit "${_valid_opts}" "${_msg}"
  else
    case ${_option} in
      [Yy]) _ret_code=0 ;; 
      [Nn]) _ret_code=1 ;;
      [Qq]) exitShell ;;
      *) 
        if [[ -z ${_option} ]]; then # press return
          _ret_code=0
        else
          enterYesNoQuit "${_valid_opts}" "${_msg}"
        fi  
      ;;
    esac
  fi
  return ${_ret_code}
}

continueOrExit() {
  # $1 is optional message
  local _msg=${1:-""}
  if [[ ${run_once} == "Y" ]]; then # ctl-c; don't give option to continue
    exitShell ${cypherRetCode}
  fi
  if [[ ${is_pipe} == "N" ]]; then
    # messageOutput
    enterYesNoQuit "q" "${_msg}Press Enter to continue, q Enter to quit. "
    outputQryRunMsg
  fi
}

exitShell() {
  # exit shell with return code passed in
  consumeStdIn 1 # disccard extra paste lines passed in, if any. Wait 1s for input to catch up with paste
  if [[ ${1} -eq ${RCODE_INTERNAL_ERROR} ]]; then
    exit ${RCODE_INTERNAL_ERROR}
  else 
    if [[ $# -eq 1 ]]; then 
      return_code=${1}
    else
      return_code=${RCODE_SUCCESS}
    fi
    exitCleanUp
  fi
  exit ${return_code}
}

contOrExitOnEmptyFile() {
  cypherRetCode=${RCODE_EMPTY_INPUT} # do not run cypher, trigger continue or exit msg
  continueOrExit "Empty input. No cypher to run. "
}


outputQryRunMsg() {
  local _db_msg
  [[ ${is_pipe} == "Y" ]] && return # input is from a pipe
  clear
  if [[ ${edit_cnt} -eq 0 ]]; then # first time through
    if [[  -n "${db_name}" ]]; then
      _db_msg="in database ${db_name}"
    fi
    messageOutput "Using Neo4j ${db_edition:-?} version ${db_version:-?} as user ${db_username:-?} ${_db_msg}" 
    if [[ -n ${editor_to_use} ]]; then
      sleep 2 # let user see welcome message before opening editor
    fi  
  fi
  if [[ ! -n "${editor_to_use}" ]]; then # header for stdin
    messageOutput "==> USE Ctl-D on a blank line to execute cypher statement. $([[ ${edit_cnt} -ne 0 ]] && echo "Database: ${db_name}.")"
    messageOutput "        Ctl-C to terminate stdin and exit ${SHELL_NAME} without running cypher statement."
  elif [[ "${old_db_name}" != "${db_name}" && ${edit_cnt} -gt 0 ]]; then 
    messageOutput "Using Database: ${db_name}"
    old_db_name="${db_name}"
  fi
}

#
#  FILE HANDLING 
#
existingFileCnt() {
  # $1 is directory, $2 is pattern
  local ret=$(printf '%0d' $(find "${1}" -name "${2}" -type f -depth 1 | wc -l ) )
  echo ${ret}
}

cleanupConnectFiles() {
  # clean the temp files specific to db connection
  rm ${TMP_DB_CONN_QRY_FILE} ${TMP_DB_CONN_RES_FILE} >/dev/null 2>&1
}

exitCleanUp() {
  # clean-up history files
  if [[ ${return_code} -eq ${RCODE_INTERNAL_ERROR} ]]; then 
    return
  fi
  local _exist_file_cnt
  local _msg=''

  cleanupConnectFiles

  # current edit produced $_cypherFilePattern file may be empty on ctl-c or run_once with input file
  find "${find_dir}" -depth 1 -type f -empty -name "${save_qry_pattern}"  -exec rm {} \; 2>/dev/null 

  [[ ${save_dir} != "./" ]] && _msg="in directory ${save_dir}"
  if [[ ${save_cypher} == "Y" || -s ${input_cypher_file_name} ]]; then
    if [[ ${quiet_output} == "N" ]]; then  # will not touch file launched with editor, only history files
      _exist_file_cnt=$(existingFileCnt "${find_dir}" "${save_qry_pattern}")
      if [[ $_exist_file_cnt -ne 0 ]]; then
        [[ ${userDefQryPrefix} != "Y" ]] && _msg="with session id ${SESSION_ID} ${_msg}"
        messageOutput "**** There is ${_exist_file_cnt} query $([[ ${_exist_file_cnt} -eq 1 ]] && printf '%s' 'file' || printf '%s' 'files') (${QRY_FILE_POSTFIX}) ${_msg} ****"
      fi
    fi
  else # clean up any errant cypher query files
    find "${find_dir}" -depth 1 -type f -name "${save_qry_pattern}" -exec rm {} \; 2>/dev/null 
  fi

  if [[ ${save_results} == "Y" && ${quiet_output} == "N" ]]; then
    _exist_file_cnt=$(existingFileCnt "${find_dir}" "${save_results_pattern}") 
    if [[ $_exist_file_cnt -ne 0 ]]; then
      [[ ${userDefResPrefix} != "Y" ]] && _msg="with session id ${SESSION_ID} ${_msg}"
      messageOutput "**** There is ${_exist_file_cnt} result $([[ ${_exist_file_cnt} -eq 1 ]] && printf '%s' 'file' || printf '%s' 'files') (${RESULTS_FILE_POSTFIX}) ${_msg} ****"
    fi
  elif [[ ${save_results} == "N" ]]; then # clean-up results files
    find "${find_dir}" -type f -depth 1 -name "${save_results_pattern}" -exec rm {} \; 2>/dev/null 
  fi 

  if [[ ${is_pipe} == "N" ]]; then
    stty echo sane # reset stty just in case
  fi
}

initIntermediateFiles () {
  generateFileNames

  if [[ -n ${input_cypher_file_name} ]]; then # have cypher input file
    if [[ -n ${editor_to_use} ]]; then  # keep using same file in editor
      cypherEditFile="${input_cypher_file_name}"
       
      if [[ ${save_cypher} == "Y" && -s ${input_cypher_file_name} ]]; then # save unaltered input file with a 0 file number when using an editor
        saveOrigFile=$(echo "${cypherSaveFile}" | sed -e "s/1${QRY_FILE_POSTFIX}"/0${QRY_FILE_POSTFIX}/"")
        cp "${input_cypher_file_name}" "${saveOrigFile}"
        # cp "${input_cypher_file_name}" "$(echo \""${cypherSaveFile}"\"" | sed -e \""s/1${QRY_FILE_POSTFIX}/0${QRY_FILE_POSTFIX}/"\")"
      fi
    else # use save file as the edit file
      cypherEditFile="${cypherSaveFile}"
      cp "${input_cypher_file_name}" "${cypherEditFile}"
    fi
  else

    cypherEditFile="${cypherSaveFile}"
  fi
}

initFileStrings() {
  # prefix can be passed in cypherFilePrefix, or default OUTPUT_FILES_PREFIX
  if [[ ! -n ${cypherFilePrefix} ]]; then  
    cypherFilePrefix="${OUTPUT_FILES_PREFIX}" 
    userDefQryPrefix="N"
  else
    userDefQryPrefix="Y"
  fi
  if [[ ! -n ${resultFilePrefix} ]]; then  
    resultFilePrefix="${OUTPUT_FILES_PREFIX}" 
    userDefResPrefix="N"
  else
    userDefResPrefix="Y"
  fi

  # add $save_dir directory prefix to tmp variables
  TMP_DB_CONN_QRY_FILE="${save_dir}tmpDbConnectTest.${SESSION_ID}${QRY_FILE_POSTFIX}"
  TMP_DB_CONN_RES_FILE="${save_dir}tmpDbConnectTest.${SESSION_ID}${RESULTS_FILE_POSTFIX}"

  # output file patterns
  if [[ ${userDefQryPrefix} == "Y" ]]; then
    save_qry_pattern="${cypherFilePrefix}*${QRY_FILE_POSTFIX}"
  else
    save_qry_pattern="${cypherFilePrefix}*${SESSION_ID}*${QRY_FILE_POSTFIX}"
  fi

  if [[ ${userDefResPrefix} == "Y" ]]; then
    save_results_pattern="${resultFilePrefix}*${RESULTS_FILE_POSTFIX}"
  else
    save_results_pattern="${resultFilePrefix}*${SESSION_ID}*${RESULTS_FILE_POSTFIX}"
  fi
}

generateFileNames() {
  # generating save and results file names
  (( file_nbr++ )) # increment file nbr if saving files
  date_stamp=$(date +%FT%I-%M-%S%p) # avoid ':' sublime interprets : as line / col numbers
  
  if [[ ${userDefQryPrefix} == "Y" ]]; then
    printf -v cypherSaveFile "%s%s-%02d%s" "${save_dir}" "${cypherFilePrefix}" ${file_nbr} "${QRY_FILE_POSTFIX}"
  else
    printf -v cypherSaveFile "%s%s_%s_%s-%d%s" "${save_dir}" "${cypherFilePrefix}" "${date_stamp}" "${SESSION_ID}" ${file_nbr} "${QRY_FILE_POSTFIX}"
  fi

  if [[ ${userDefResPrefix} == "Y" ]]; then
    printf -v resultSaveFile "%s%s-%02d%s" "${save_dir}" "${resultFilePrefix}" ${file_nbr} "${RESULTS_FILE_POSTFIX}"
  else
    printf -v resultSaveFile "%s%s_%s_%s-%d%s" "${save_dir}" "${resultFilePrefix}" "${date_stamp}" "${SESSION_ID}" ${file_nbr} "${RESULTS_FILE_POSTFIX}"
  fi
}

intermediateFileHandling() {
  # manage intermediate save files
  # using editor
  # using editor with save file options
  # stdin
  local _generated_new_file_names="N"  # only call generateFileNames once
  if [[ ${cypherRetCode} -eq 0 ]];then 
  
    if [[ ${save_cypher} == "N" ]]; then # remove file if not use editor and not saving (stdin)
      [[ ! -n ${editor_to_use} ]] &&  rm -f "${cypherSaveFile}"
    else # save_cypher = "Y"
      if [[ -n ${input_cypher_file_name} && -n ${editor_to_use} ]]; then # keep using same file in editor
        cp "${cypherEditFile}" "${cypherSaveFile}" # using editor on edit file, save file is history
        generateFileNames
        cypherEditFile="${input_cypher_file_name}"
      elif [[ -n ${editor_to_use} ]]; then # using an editor on generated file names
        lastCypherFile="${cypherEditFile}"
        generateFileNames
        cp "${lastCypherFile}" "${cypherSaveFile}"
        cypherEditFile="${cypherSaveFile}"
      else # use blank, new files
        generateFileNames
        cypherEditFile="${cypherSaveFile}"
      fi
      _generated_new_file_names="Y"
    fi  
  fi # cypherRetCode is 0
    
  if [[ ${save_results} == "N" || ${cypherRetCode} -ne 0 ]]; then
    rm -f "${resultSaveFile}"
  elif [[ ${save_results} == "Y" && ${_generated_new_file_names} == "N" ]]; then 
    generateFileNames # new file names not generated w save_cypher=Y
  fi

  [[ ! -n ${editor_to_use} ]] && cat /dev/null > "${cypherEditFile}" # using stdin, blank out cypher
}

findStr() {
  # called with pattern findStr 'valid pattern(s)' 'test strings'. e.g. findStr 'yqn' "y n q X"
  # looking for y,n,q,X in string 'yqn'. return 1 if looking for string is not
  # there, e.g. invalid options. leverages --word-regexp so spaces have meaning

  local _inThis="${1}" # 
  shift
  arr=($@)
  for _lookFor in "${arr[@]}" ; do
    echo "${_inThis}" | grep --word-regexp --extended-regexp --ignore-case --quiet -e "${_lookFor}"
    if [[ $? -ne 0 ]]; then # not found, exit
      return 1
    fi
  done
  return 0
}

#
# ENVIRONMENT FUNCTIONS
#
runCypherShellInfoCmd() {
  # one and done cypher-shell options run
  [[ ! -n ${cypher_shell_info_arg} ]] && return # no info arg on command line
  cypher-shell ${cypher_shell_info_arg}
  exitShell ${?}
}

haveCypherShell() {
  # validate cypher-shell in PATH
  # ck to see if you can connect to cypher-shell w/o error
  if [[ ! -n ${use_this_cypher_shell} ]]; then
    if ! which cypher-shell > /dev/null; then
      messageOutput "*** Error: cypher-shell not found. Bye."
      exitShell ${RCODE_CYPHER_SHELL_NOT_FOUND}
    else
      use_this_cypher_shell="$(which cypher-shell)"
    fi
  elif [[ ! -x ${use_this_cypher_shell} || ! -f ${use_this_cypher_shell} ]]; then
    messageOutput "*** Error: --cypher-shell ${use_this_cypher_shell} parameter not found or is not executable. Bye."
    exitShell ${RCODE_CYPHER_SHELL_NOT_FOUND}
  fi
}

getCypherShellLogin() {
   # need to do our own uid / pw input if not set
  if [[ ${no_login_needed} == "N" ]]; then
      # get user name if needed
    if [[ -z ${user_name} && -z ${NEO4J_USERNAME} ]]; then # uid not in env var or command line
      if [[ ${is_pipe} == "Y" ]]; then
        messageOutput "Missing username needed for non-interactive input (pipe). Bye."
        exitShell ${RCODE_NO_USER_NAME}
      fi
      printf 'username: '
      read -r user_name
      user_name=" -u ${user_name} "  # for command line if needed
    fi
      # get password if needed
    if [[ -z ${user_password}  && -z ${NEO4J_PASSWORD} ]]; then # pw not in env var or command line
      if [[ ${is_pipe} == "Y" ]]; then
        messageOutput "Missing password needed for non-interactive input (pipe). Bye."
        exitShell ${RCODE_NO_PASSWORD}
      fi
      # stty -echo # turn echo off
      printf 'password: '
      read -ers user_password
      user_password=" -p ${user_password} "  # for command line if needed
      # stty echo  # turn echo on
    fi
    setCypherShellCmdLine  # add uid / pw command line params if needed
  fi
}
  
runInternalCypher() {
  # run internal cypher queries, always --format plain
  local _qry_file="${1}" 
  local _out_file="${2}" 

  fmtCurrentDbCmdArg # use 'current db' for cypher-shell command line --database opion

   # cypher-shell with no formatting args to be able to parse the output string
  eval "'${use_this_cypher_shell}'" "${user_name}" "${user_password}" "${db_cmd_arg}" "${cypherShellArgs}"  --format plain < "${_qry_file}" > "${_out_file}" 2>&1
  cypherRetCode=$?
  if [[ ${cypherRetCode} -ne 0 ]]; then
    messageOutput ""
    messageOutput ""
    messageOutput "ERROR: cypher-shell generated error"
    messageOutput "Using this cypher-shell: ${use_this_cypher_shell}"
    messageOutput "cypher-shell return code: ${cypherRetCode}"
    messageOutput "Started with: ${SHELL_NAME} ${coll_args}"
    messageOutput "Arguments passed to cypher-shell: ${cypherShellArgs}"
    messageOutput "cypher-shell output:"
    messageOutput "$(cat "${_out_file}")"
    messageOutput ""
    messageOutput ""

    exitShell ${cypherRetCode}
  fi
}

verifyCypherShell() {
  # connect to cypher-shell and get details
  messageOutput "Connecting to database"

  getCypherShellLogin # get cypher-shell login credentials if needed
  echo "${DB_VER_QRY}" > "${TMP_DB_CONN_QRY_FILE}"    # get database version query
  runInternalCypher "${TMP_DB_CONN_QRY_FILE}" "${TMP_DB_CONN_RES_FILE}"
  msg_arr=($(tail -1 "${TMP_DB_CONN_RES_FILE}" | tr ', ' '\n')) # tr for macOS
  db_version=${msg_arr[@]:0:1}
  db_edition=${msg_arr[@]:1:1}
  db_username=${msg_arr[@]:2:1}
  cleanupConnectFiles
}

get4xDbName() {
  # db_name not set, and 4.x ver of Neo4j

  if [[ ${db_version} == *'4.'* ]]; then
    echo "${DB_4x_NAME_QRY}"  > ${TMP_DB_CONN_QRY_FILE}    # get database name query
    runInternalCypher "${TMP_DB_CONN_QRY_FILE}" "${TMP_DB_CONN_RES_FILE}"  
    msg_arr=($(tail -1 "${TMP_DB_CONN_RES_FILE}" | tr ', ' '\n')) # tr for macOS
    db_name="${msg_arr[@]:0:1}"
    old_db_name="${db_name}"
    cleanupConnectFiles
  fi
}

setCypherShellCmdLine() {
  # set the cypher-shell command line arguments.
  cypher_shell_cmd_line="${use_this_cypher_shell} ${user_name} ${user_password} ${use_params} ${db_cmd_arg} ${cypherShellArgs} ${cypher_format_arg}"
}

#
# RUN CYPHER
#
consumeStdIn() {
  # There can be after error text being sent to an embedded terminal that should be discarded
  # $1 is the timeout to wait for EOL.  Used to allow initial read to process any pasted text in buffer
  if [[ ${is_pipe} == "N" ]]; then
    while read -t $1 -u 0 -rs x; do
      consumeStdIn 0 # no need to wait for input after first line
    done
  fi
}

fmtCurrentDbCmdArg() {
   # set the cypher-shell cmd line arg for db
   # either passed on cmd line, or last :use stmtn
  db_cmd_arg=""
  if [[ -n ${db_name} ]]; then # db specified on cmd line or :use stmt
    db_cmd_arg="-d ${db_name}"
    setCypherShellCmdLine
  fi
}

findColonUseStmnt() {
  # find last :use database statement to use as the db to run next call to cypher-shell
  # provides a seamless, single session cypher-shell experience
  # last_use_stmt=$(grep --extended-regexp --ignore-case -e ':use\s+[`]?[a-zA-z][a-zA-z0-9.-]{2,62}[`]?[;]{0,1}.*$' "${cypherEditFile}" 2>/dev/null | sed -E -e 's/[`]//g' -e "s/.*:use[ $(printf '\t')]*//" -e 's/;//' | tail -1)
  last_use_stmt=$(grep --extended-regexp --ignore-case --color=never -e ':use\s+[`]?[a-zA-z][a-zA-z0-9.-]{2,62}[`]?[;]{0,1}.*$' "${cypherEditFile}" | tail -1 | sed -E -e 's/[`]//g' -e "s/.*:use[ ]*//" -e 's/;//' )
  if [[ -n ${last_use_stmt} ]]; then
    db_name="${last_use_stmt}"
    fmtCurrentDbCmdArg
  fi
}

cleanAndRunCypher() {
  clear
  
  if [[ ! -f ${cypherEditFile} ]]; then # did not write 1st file with editor
    contOrExitOnEmptyFile
  else
    sed -i '' "/.*${SHELL_NAME}.*/d" "${cypherEditFile}"  # delete line with a call to this shell if necessary
    # check to see if the cypher file is empty
    if ! grep --extended-regexp --quiet -e '[^[:space:]]' "${cypherEditFile}" >/dev/null 2>&1  ; then
      contOrExitOnEmptyFile
    else
       # add semicolon to end of file if not there.  need it for cypher to run
      if ! sed '1!G;h;$!d' "${cypherEditFile}" | awk 'NF{print;exit}' | grep --extended-regexp --quiet '^.*;\s*$|;\s*//.*$'; then
        # printf "%s" ";" >> ${cypherEditFile}
        sed -i '' -e '$s/$/;/' "${cypherEditFile}"
      fi

       # run cypher in cypher-shell, use eval to allow printf to run in correct order
       # saving results file, run with tee command to create file
      if [[ ${save_results}  == "Y" ]]; then
        eval "[[ ${show_cmd_line} == "Y" ]] && printf '// Command line args: %s\n' \""${cmd_arg_msg}"\"; \
              [[ ${qry_start_time} == "Y" ]] && printf '// Query started: %s\n' \""$(date)"\";  \
              [[ ${inc_cypher} == "Y" ]] && cat \""${cypherEditFile}"\";  \
              if [[ ${inc_cypher} == "Y" ]];then cat ${cypherEditFile}; printf '\n'; fi;  \
              if [[ ${inc_cypher_as_comment} == "Y" ]];then sed -e 's/^/\/\/ /' \""${cypherEditFile}"\"; printf '\n'; fi;  \
              ${cypher_shell_cmd_line} < \""${cypherEditFile}"\"  2>&1" | tee  "${resultSaveFile}" | less ${less_options} 
      else 
        eval "[[ ${show_cmd_line} == "Y" ]] && printf '// Command line args: %s\n' \""${cmd_arg_msg}"\"; \
              [[ ${qry_start_time} == "Y" ]] && printf '// Query started: %s\n' \""$(date)"\";  \
              if [[ ${inc_cypher} == "Y" ]];then cat \""${cypherEditFile}"\"; printf '\n'; fi;  \
              if [[ ${inc_cypher_as_comment} == "Y" ]];then sed -e 's/^/\/\/ /' \""${cypherEditFile}"\"; printf '\n'; fi;  \
              ${cypher_shell_cmd_line} < \""${cypherEditFile}"\"  2>&1" | less ${less_options}
      fi
        # ck return code - PIPESTATUS[0] for bash, pipestatus[1] for zsh
      if [[ ${PIPESTATUS[0]} -ne 0 || ${pipestatus[1]} -ne 0 ]]; then
        cypherRetCode=${RCODE_CYPHER_SHELL_ERROR}
      else
        findColonUseStmnt # retain last :use <db> statement. works for me as a concept
        cypherRetCode=${RCODE_SUCCESS}
      fi
    fi
  fi
}

getCypherText() {
  # input cypher text, either from pipe, editor, or stdin (usually terminal window in editor)
  [[ -n ${input_cypher_file_name} && ${run_once} == "Y" ]] &&  return

  outputQryRunMsg # output run query header
  (( edit_cnt++ ))  # increment query edit count
  if [[ ! -n ${editor_to_use} ]]; then # using stdin
    if [[ -s ${cypherEditFile} ]]; then 
      cat "${cypherEditFile}"  # output existing text
    fi
     # read with -i would be very usefule here.  Not on mac
    local old_ifs=${IFS}
    while IFS= read -r line; do
      printf '%s\n' "$line" >> "${cypherEditFile}"
    done
    IFS=${old_ifs}
  else
    while true; do
      if [[ ${editor_to_use} != "vi" ]]; then
        ${editor_to_use} "${cypherEditFile}"
      else # using vi
        if [[ ! -s ${cypherEditFile} ]]; then
          ${editor_to_use} ${VI_INITIAL_OPEN_OPTS} "${cypherEditFile}" # open file option +star (new file)
        else
          ${editor_to_use} "${cypherEditFile}"
        fi
      fi
      # ask user if they want to run file or go back to edit
      enterYesNoQuit "qn" "<Enter> to run query, (n) to continue to edit, (q) to exit ${SHELL_NAME} " 
      if [[ $? -eq 1 ]]; then # answered 'n', continue
        clear
        continue  # go back to edit on same file
      else # answered yes to running query
        break
      fi # continue with new intermediate files
    done
  fi
}

executionLoop() {
  # main loop for running cypher-shell until termination condition
  
  while true; do
    getCypherText  # consume input
    cleanAndRunCypher 
    intermediateFileHandling  # intermediate files for cypher and output

    if [[ ${cypherRetCode} -ne 0 && ${exit_on_error} == "Y" ]]; then # print error and exit
      exitShell ${cypherRetCode} # ERROR running cypher code
    elif [[ ${run_once} == "Y" || ${is_pipe} == "Y" ]]; then # exit shell if run 1, or is from a pipe
      exitShell ${cypherRetCode}
    fi

    if [[ -n ${editor_to_use} ]]; then # don't go straight back into editor
      outputQryRunMsg
      continueOrExit "Using ${editor_to_use} to edit. "
    fi
  done
}

#
# main
#

### shell accomodations
# for zsh to avoid having to do this for command line word split in this shell
# args=(${user_name} ${_} ${cypherShellArgs} ${cypher_format_arg})
# cypher-shell "${args[@]}"
setopt SH_WORD_SPLIT >/dev/null 2>&1
set -o pipefail
SHELL_NAME=${0##*/}  # shell name must be set in main to avoid zsh / bash diffs

trap continueOrExit SIGINT 
trap exitShell SIGHUP SIGTERM 

setDefaults
getArgs "$@"
ckSetVarValues 
initFileStrings

[[ ${is_pipe} == "N" ]] && clear 

haveCypherShell        # verify that you can reach a cypher-shell executable
verifyCypherShell      # verify that can connect to cypher-shell
get4xDbName            # get database name if using 4.x
fmtCurrentDbCmdArg     # use 'current db' for db_cmd_arg
runCypherShellInfoCmd  # if info run cmd and exit
initIntermediateFiles  # set vars for query and results files
executionLoop          # execute cypher statements
exitShell ${RCODE_SUCCESS}

