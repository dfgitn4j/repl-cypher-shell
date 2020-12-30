#set -xv
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

    [-u | --username]        cypher-shell username parameter.
    [-p | --password]        cypher-shell password parameter.
    [-C | --cypher-shell]    path to cypher-shell executable to be used. Run --help for how to use.
    [-P | --param]           cypher-shell -P | --param strings. Run --help for how to use.
    [-f | --file]            cypher-shell -f | --file containing query. Run --help for how to use.
    [--format]               cypher-shell --format option.query results files

    [-A | --saveAll]         save cypher query and output results files.
    [-S | --saveCypher]      save each query statement in a file.
    [-R | --saveResults]     save each query output in a file.
    [-V | --vi]              use vi editor.
    [--nano]                Use nano editor started with 'nano -t' flag.
    [-E | --editor] [cmd]    use external editor. Run --help for how to use.
    [-L | --lessOpts] [opts] use these less pager options instead of defaults.

    [-t | --time]            output query start time.
    [-c | --showCmdLn]       show script command line args in output.
    [-q | --quiet]           no informational output messages.

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
    to terminate stdin by sending a newline and Ctl-D to close stdin and  pass
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
  
    cypher shell version commands. run and exit.

  -A | --saveAll)
  
    Save all cypher queries and output in individual files.   Save query and query
    results to files in the current directory. The files will have the same
    timestamp and session identifiers Files will be in current directory with the
    format:
  

        cypher query: ${OUTPUT_FILES_PREFIX}_[datetime query was run]_[session ID]-[qry nbr]${QRY_FILE_POSTFIX}
        results text: ${OUTPUT_FILES_PREFIX}_[datetime query was run]_[session ID]-[qry nbr]${RESULTS_FILE_POSTFIX}
  
        For example:

        cypher query: $(printf "%s_%s_%s-%d%s" "${OUTPUT_FILES_PREFIX}" "$(date +%FT%I-%M-%S%p)" "${SESSION_ID}" 1 "${QRY_FILE_POSTFIX}")
        results text: $(printf "%s_%s_%s-%d%s" "${OUTPUT_FILES_PREFIX}" "$(date +%FT%I-%M-%S%p)" "${SESSION_ID}" 1 "${RESULTS_FILE_POSTFIX}")

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

  VI_INITIAL_OPEN_OPTS=' +star '  # Start first exec for vi in append mode.

  edit_cnt=0        # count number of queries run, controls stdin messaging.
  success_run_cnt=0 # count number of RCODE_SUCCESSful runs for file names
  file_nbr=0        # output file number if query / results file(s) are saved
  db_name=""        # will only be populated on neo4j 4.x databases

   # variables used in file name creation
   # file patterns are in the form of:
   # ${OUTPUT_FILES_PREFIX} ${date_stamp} ${SESSION_ID} ${file_nbr} (${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})
  SESSION_ID="${RANDOM}" # nbr to id this session. For when keeping intermediate cypher files
  OUTPUT_FILES_PREFIX="qry" # prefix all intermediate files begin with
  QRY_FILE_POSTFIX=".cypher" # prefix all intermediate files begin with
  RESULTS_FILE_POSTFIX=".txt"
  TMP_FILE="tmpEditorCypherFile.${SESSION_ID}"
  TMP_DB_CONN_QRY_FILE="tmpDbConnectTest.${SESSION_ID}${QRY_FILE_POSTFIX}"
  TMP_DB_CONN_RES_FILE="tmpDbConnectTest.${SESSION_ID}${RESULTS_FILE_POSTFIX}"
  date_stamp=$(date +%FT%I-%M-%S%p) # avoid ':' sublime interprets : as line / col numbers

  SAVE_QRY_FILE_PATTERN="${OUTPUT_FILES_PREFIX}.*${SESSION_ID}.*${QRY_FILE_POSTFIX}"
  SAVE_RESULTS_FILE_PATTERN="${OUTPUT_FILES_PREFIX}.*${SESSION_ID}.*${RESULTS_FILE_POSTFIX}"
}


findStr() {
  # ${1} is the string to find
  
  local lookFor
  local inThis
  lookFor="${1}"
  shift
  for arg in "$@"; do inThis="${inThis} ${arg}"; done
  echo "${inThis}" | grep --extended-regexp --ignore-case --quiet -e "${lookFor}"
  return $?
}

enterYesNoQuit() {
  # ${1} is valid response pattern in form of "<CR>YNQynq", <CR> defaults to Yes
  # ${2} is the  message for the user
  local valid_opts
  local msg
  local ret_code
  if [[ ${is_pipe} == "N" ]]; then
    if [[ -z ${1} ]]; then
      valid_opts="<CR>YNQynq"
    else 
      valid_opts="${1}"
    fi
    if [[ -z ${2} ]]; then 
      msg="[<Enter> | y <Enter> to continue, N<Enter> to return, q <Enter> to quit."
    else
      msg="${2}"
    fi
    printf "\n%s" "${msg}"
    
    read -r option  
    printf -v option "%.1s" "${option}" # get 1st char - no read -N 1 on osx, bummer
    findStr "${option}" "${valid_opts}"
    if [[ $? -eq 1 ]]; then
      messageOutput "'${option}' is an invalid choice."
      enterYesNoQuit "${valid_opts}" "${msg}"
    else
      case ${option} in
        [Yy]) ret_code=0 ;; 
        [Nn]) ret_code=1 ;;
        [Qq]) exitShell ;;
        *) 
          if [[ -z ${option} ]]; then # press return
            ret_code=0
          else
            enterYesNoQuit "${valid_opts}" "${msg}"
          fi  
        ;;
      esac

      return ${ret_code}
    fi
  fi
}

printContinueOrExit() {
  # $1 is optional message
  local msg=${1:-""}
  if [[ ${run_once}  == "Y" ]]; then # ctl-c; don't give option to continue
    exitShell "${cypherRetCode}"
  fi
  if [[ ${is_pipe} == "N" && ${quiet_output} == "N" ]]; then
    if [[ -z ${msg} ]]; then
      enterYesNoQuit "<CR>q" "Press Enter to continue, q Enter to quit. "
    else 
      enterYesNoQuit "<CR>q" "${msg} Press Enter to continue, q Enter to quit. "
    fi
  fi
}

messageOutput() {  # to print or not to print
  # Not all messages to to output, some go to tty and results file to stdout
  # $1 is message $2 is optional format string for printf
  local fmt_str=${2:-"%s\n"}
  if [[ ${quiet_output} == "N" && ${is_pipe} == "N"  ]]; then
    printf "${fmt_str}" "${1}"
  fi
}

outputWelcomeMsg ()
{
  local db_msg
  if [[  -n "${db_name}" ]]; then
    db_msg="in database ${db_name}"
  fi
  messageOutput "Using Neo4j ${db_edition:-?} version ${db_version:-?} as user ${db_username:-?} ${db_msg}" 
  if [[ -n ${editor_to_use} ]]; then
    sleep 2 # let user see welcome message before opening editor
  fi
}

outputQryRunMsg ()
{
  local db_msg=""
  if [[  -n "${db_name}" ]]; then
    db_msg="Database: ${db_name}"
  fi
  if [[ ! -n "${editor_to_use}" ]]; then # header for stdin
    messageOutput "==> USE Ctl-D on a blank line to execute cypher statement. ${db_msg}"
    messageOutput "        Ctl-C to terminate stdin and exit ${SHELL_NAME} without running cypher statement."
  elif [[ ! -z ${db_msg} ]]; then 
    messageOutput "==> Using ${db_msg}"
  fi
}

# one and done cypher-shell options run
runCypherShellInfoCmd () {
  # messageOutput "Found cypher-shell command argument '${_currentParam}'. Running and exiting. Bye."
  cypher-shell "${1}"
  exitShell ${?}
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
  # less options --shift .01 allows left arrow to only cut off beginning "|"
  # while scrolling at the expense of slower left arrow scrolling
  # Note: less will clear screen before user sees ouput if the quit-at-end options
  # are used. e.g. --quit-at-eof.  Look for comment with string "LESS:" in script
  # if this behavior bugs you.
  #less_options=('--LONG-PROMPT' '--shift .05' '--line-numbers')
  less_options=('--LONG-PROMPT' '--shift .01')

  user_name=""               # blank string by default
  user_password=""

  cypherShellArgs=""         # any args not in case are assumed to be cypher-shell specific args passed in
  cypher_format_arg="--format verbose " # need extra space at end for param validation test
  cypher_shell_cmd_line=""   # a string with all the cypher-shell specific command line opts, if passed in.
  no_login_needed="N"        # skip login prompting
  save_cypher="N"            # save each query in own file
  save_results="N"           # save each query output in own file
  show_cmd_line="N"          # show command line args in output
  cmd_arg_msg=""             # string to for command line arguments in output $show_cmd_line="Y"
  qry_start_time="N"               # time between query submit to cypher-shell and return
  quiet_output="N"           # no messages or prompts
  cypherShellInfoArg=""      # any info flags passed: -v | --version | --driver-version
  coll_args=""               # all argumnents passed to script
  use_params=""              # query parameter arguments
  input_cypher_file_name=""  # intput file
  use_this_cypher_shell=""   # cypher-shell to use. mostly for desktop
  editor_to_use=""           # launch editor command line

  cypherRetCode=${RCODE_SUCCESS} # cypher-shell return code

  while [ ${#@} -gt 0 ]
  do
     case ${1} in
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
      -C | --cypher-shell ) # username to connect as.
         getOptArgs 1  "$@"
         use_this_cypher_shell="${arg_ret_opts}"
         coll_args="${coll_args} ${use_this_cypher_shell}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;

         # intercepted cypher-shell args
      -P | --param)
         getOptArgs 1  "$@"
         use_params="${use_params} ${_currentParam} '${arg_ret_opts}'"
         coll_args="${coll_args} ${use_params}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -f | --file ) # cypher file name
         getOptArgs 1 "$@"
         input_cypher_file="${_currentParam} ${arg_ret_opts}"
         input_cypher_file_name="$(echo "${input_cypher_file}" | sed -E -e 's/(--file|-f)[[:space:]]*//')"
         shift "${arg_shift_cnt}" # go past number of params processed
         coll_args="${coll_args} ${input_cypher_file}"
         ;;
      --format) # cypher-shell format option
         getOptArgs 1 "$@"
         # note the extra space at end of cypher_format_arg makes validation testing below easier
         cypher_format_arg="${_currentParam} ${arg_ret_opts} "
         shift "${arg_shift_cnt}" # go past number of params processed
         coll_args="${coll_args} ${cypher_format_arg}"
         ;;
      -d | --database) 
           # intercept cypher-shell -d DATABASE parameter. Used to determine
           # which db to run query in based on last command line or last :use command
         getOptArgs 1 "$@"
         db_name="${arg_ret_opts}"
         coll_args="${coll_args} ${db_name}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
        # one and done cyphe-shell command line options
      -v | --version | --driver-version) # 
         getOptArgs 0 "$@"
         cypherShellInfoArg=${_currentParam}
         shift "${arg_shift_cnt}"
         ;;

        # begin shell specific options
        # save optoins
      -A | --saveAll) # keep cypher queries and output results files.
         getOptArgs 0 "$@"
         save_cypher="Y"
         save_results="Y"
         coll_args="${coll_args} ${_currentParam}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -S | --saveCypher) # keep the cypher queries around for future use.
         getOptArgs 0 "$@"
         save_cypher="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -R | --saveResults) # keep the cypher queries around for future use.
         getOptArgs 0 "$@"
         save_results="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
        # editor options
      -V | --vi)
         getOptArgs 0 "$@"
         editor_to_use="vi" 
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      --nano)
         getOptArgs 0 "$@"
         editor_to_use="nano -t" 
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -E | --editor)
         getOptArgs -1  "$@"
         editor_to_use="${arg_ret_opts}"
         coll_args="${coll_args} ${_currentParam}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
          # run options
          # override default less options
          # '-' and '--' command line options for less must have '-' prepended
          # with a backslash e.g. -L '\-\-line-numbers'
      -L | --lessOpts )
         getOptArgs -1 "$@"
         less_options="${arg_ret_opts}"
         less_options=$(echo ${arg_ret_opts} | sed -e 's/\\//g') # remove '\' from '\-'
         coll_args="${coll_args} ${_currentParam} ${arg_ret_opts}"
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -c | --showCmdLn ) # show command line args in output
         getOptArgs 0 "$@"
         show_cmd_line="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -t | --time) # print time query started
         getOptArgs 0 "$@"
         qry_start_time="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -q | --quiet ) # minimal output
         getOptArgs 0 "$@"
         quiet_output="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -1 | --one) # run query execution loop only once
         getOptArgs 0 "$@"
         run_once="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -N | --noLogin) # flag to say don't need login prompt
         getOptArgs 0 "$@"
         no_login_needed="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
         ;;
      -X | --exitOnError )
         getOptArgs 0 "$@"
         exit_on_error="Y"
         coll_args="${coll_args} ${_currentParam} "
         shift "${arg_shift_cnt}" # go past number of params processed
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
      "")
         break # done with loop
         ;;
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
  if [[ -n ${cypherShellInfoArg} ]]; then
    runCypherShellInfoCmd "${cypherShellInfoArg}" # run info cmd and exit
  fi
   # parameter checks.  well, kinda
  return_code=${RCODE_SUCCESS} 
  if ! echo "${cypher_format_arg}" | grep -q -E ' auto | verbose | plain '; then
    messageOutput "Invalid --format option: '${cypher_format_arg}'."
    return_code=${RCODE_INVALID_FORMAT_STR}
  elif [[ -n ${editor_to_use} && ${run_once} == "Y" ]]; then
    messageOutput "Invalid command line options.  Cannot use an editor and run once at the same time."
    return_code=${RCODE_INVALID_CMD_LINE_OPTS}
  elif [[ -n ${input_cypher_file_name} && ! -f ${input_cypher_file_name} ]]; then # missing input file
    messageOutput "File '${input_cypher_file}' with cypher query does not exist."
    return_code=${RCODE_MISSING_INPUT_FILE}
  elif [[ ${is_pipe} == "Y" ]]; then
    if [[ -n ${editor_to_use} ]]; then  # could do this, but why?
      messageOutput "Cannot use external editor and pipe input at the same time."
      return_code=${RCODE_INVALID_CMD_LINE_OPTS}
    elif [[ -n ${input_cypher_file} ]]; then
      messageOutput "Cannot use input file and pipe input at the same time."
      return_code=${RCODE_INVALID_CMD_LINE_OPTS}
    fi
    if [[ ${return_code} -ne 0 ]]; then
      exec <&-  # close stdin
    fi
  fi

  if [[ ${return_code} -ne 0 ]]; then
    messageOutput "Command line parameters passed: ${coll_args}"
    messageOutput "Good Bye."
    exitShell ${return_code}
  fi

  if [[ ${show_cmd_line} == "Y" ]]; then # output command line args
    cmd_arg_msg="Script started with: ${coll_args}"
  fi

    # string with all the cypher-shell only command line arguments. 
  setCypherShellCmdLine

}
 
cleanupConnectFiles() {
  rm ${TMP_DB_CONN_QRY_FILE} ${TMP_DB_CONN_RES_FILE} >/dev/null 2>&1
}

existingFileCnt () {
  # 1st param is the file pattern to test
  printf '%0d' $(find * -type f -depth 0 | grep --color=never -E "${1}" | wc -l ) 
}

exitCleanUp() {

  if [[ ${save_cypher} == "Y" || ${save_results}  == "Y" ]]; then
     # current edit produced $QRY_FILE_POSTFIX file may be empty on ctl-c
    find . -maxdepth 1 -type f -empty -name "${cypherFile}"  -exec rm {} \;
  
    if [[ ${save_results} == "Y" ]]; then
      messageOutput "**** There are $(existingFileCnt "${SAVE_RESULTS_FILE_PATTERN}") results files (${RESULTS_FILE_POSTFIX}) with session id ${SESSION_ID} ****"
    fi
    if [[ ${save_cypher} == "Y" ]]; then
      messageOutput "**** There are $(existingFileCnt "${SAVE_QRY_FILE_PATTERN}") query files (${QRY_FILE_POSTFIX}) with session id ${SESSION_ID} ****"
    fi
  else # cleanup any file from this session 
    find . -maxdepth 1 -type f -name "${cypherFile}"  -exec rm {} \;
    find . -maxdepth 1 -type f -name "${resultsFile}"  -exec rm {} \;
  fi

   # files for connection testing.  
  find . -maxdepth 1 -type f -name "${TMP_FILE}" -exec rm {} \; # remove message and temp file
  cleanupConnectFiles
  
  if [[ ${is_pipe} == "N" ]]; then
    stty echo sane # reset stty just in case
  fi
}

consumeStdIn () {
    # There can be after error text being sent to an embedded terminal that should be discarded
    # $1 is the timeout to wait for EOL.  Used to allow initial read to process any pasted text in buffer
  if [[ ${is_pipe} == "N" ]]; then
    while read -t $1 -u 0 -rs x; do
      consumeStdIn 0 # no need to wait for input after first line
    done
  fi

}

exitShell() {
  # exit shell with return code passed in
  consumeStdIn 1 # disccard extra paste lines passed in, if any. Wait 1s for input to catch up with paste
  if [ "${1}" -ne "${1}" ] 2>/dev/null; then # not an integer, then internal error
    messageOutput "INTERNAL ERROR.  Sorry about that.  ${1}"
    return_code=-1
  elif [[ -z ${1} ]]; then # Ctl-C sent
    return_code=${RCODE_SUCCESS}
  else
    return_code=${1}
  fi
  exitCleanUp
  exit "${return_code}"

}

haveCypherShell () {
  # validate cypher-shell in PATH
  # ck to see if you can connect to cypher-shell w/o error
  if [[ -z ${use_this_cypher_shell} ]]; then
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


getCypherShellLogin () {
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
  
runInternalCypher () {
  # run internal cypher queries, always --format plain
  local qry_file 
  local out_file 
  qry_file="${1}"
  out_file="${2}"

  fmtCurrentDbCmdArg # use 'current db' for db_cmd_arg

   # cypher-shell with no formatting args to be able to parse the output string
  eval "'${use_this_cypher_shell}'" "${user_name}" "${user_password}" "${db_cmd_arg}" "${cypherShellArgs}"  --format plain < "${qry_file}" > "${out_file}" 2>&1
  cypherRetCode=$?
  if [[ ${cypherRetCode} -ne 0 ]]; then
    messageOutput ""
    messageOutput "=========="
    messageOutput "ERROR: cypher-shell generated error"
    outputWelcomeMsg  # db version, neo4j edition, user and db if known
    messageOutput "Using this cypher-shell: ${use_this_cypher_shell}"
    messageOutput "cypher-shell return code: ${cypherRetCode}"
    messageOutput "Script started with: ${coll_args}"
    messageOutput "Arguments passed to cypher-shell: ${cypherShellArgs}"
    messageOutput "cypher-shell output:"
    messageOutput "$(cat "${out_file}")"
    messageOutput "=========="
    messageOutput ""

    exitShell ${cypherRetCode}
  fi
}

verifyCypherShell () {
  # connect to cypher-shell and get details
  messageOutput "Connecting to database"

  getCypherShellLogin # get cypher-shell login credentials if needed
  echo "${db_ver_qry}" > ${TMP_DB_CONN_QRY_FILE}    # get database version query
  runInternalCypher "${TMP_DB_CONN_QRY_FILE}" "${TMP_DB_CONN_RES_FILE}"
  msg_arr=($(tail -1 ${TMP_DB_CONN_RES_FILE} | tr ', ' '\n')) # tr for macOS
  db_version=${msg_arr[@]:0:1}
  db_edition=${msg_arr[@]:1:1}
  db_username=${msg_arr[@]:2:1}
  cleanupConnectFiles
}

get4xDbName () {
  # db_name not set, and 4.x ver of Neo4j
  if [[ -z "${db_name}" ]] && [[ ${db_version} == *$'4.'* ]]; then
    echo "${db_40_db_name_qry}"  > ${TMP_DB_CONN_QRY_FILE}    # get database name query
    runInternalCypher "${TMP_DB_CONN_QRY_FILE}" "${TMP_DB_CONN_RES_FILE}"  
    msg_arr=($(tail -1 ${TMP_DB_CONN_RES_FILE} | tr ', ' '\n')) # tr for macOS
    db_name="${msg_arr[@]:0:1}"
    cleanupConnectFiles
  fi

}

setCypherShellCmdLine () {
  # set the cypher-shell command line arguments.
  cypher_shell_cmd_line="'${use_this_cypher_shell}' ${user_name} ${user_password} ${use_params} ${db_cmd_arg} ${cypherShellArgs} ${cypher_format_arg}"
}


fmtCurrentDbCmdArg () {
   # set the cypher-shell cmd line arg for db
   # either passed on cmd line, or last :use stmtn
  db_cmd_arg=""
  if [[ ! -z ${db_name} ]]; then # db specified on cmd line or :use stmt
    db_cmd_arg="-d ${db_name}"
    setCypherShellCmdLine
  fi
}

findColonUseStmnt () {
  # find last :use database statement to use as the db to run next call to cypher-shell
  # provides a seamless, single session cypher-shell experience
  # last_use_stmt=$(grep --extended-regexp --ignore-case -e ':use\s+[`]?[a-zA-z][a-zA-z0-9.-]{2,62}[`]?[;]{0,1}.*$' "${cypherFile}" 2>/dev/null | sed -E -e 's/[`]//g' -e "s/.*:use[ $(printf '\t')]*//" -e 's/;//' | tail -1)
  last_use_stmt=$(grep --extended-regexp --ignore-case --color=never -e ':use\s+[`]?[a-zA-z][a-zA-z0-9.-]{2,62}[`]?[;]{0,1}.*$' "${cypherFile}" | tail -1 | sed -E -e 's/[`]//g' -e "s/.*:use[ ]*//" -e 's/;//' )
  if [[ ! -z ${last_use_stmt} ]]; then
    db_name="${last_use_stmt}"
    fmtCurrentDbCmdArg
  fi
}


cleanAndRunCypher () {
  clear
  sed -i '' "/.*${SHELL_NAME}.*/d" ${cypherFile}  # delete line with a call to this shell if necessary
  
   # check to see if the cypher file is empty
  if ! grep --extended-regexp --quiet -e '[^[:space:]]' "${cypherFile}" >/dev/null 2>&1  ; then
    cypherRetCode=${RCODE_EMPTY_INPUT} # do not run cypher, trigger continue or exit msg
    printContinueOrExit "Empty input. No cypher to run."
  else 
       # add semicolon to end of file if not there.  need it for cypher to run
      if ! sed '1!G;h;$!d' ${cypherFile} | awk 'NF{print;exit}' | grep --extended-regexp --quiet '^.*;\s*$|;\s*//.*$'; then
        # printf "%s" ";" >> ${cypherFile}
        sed -i '' -e '$s/$/;/' ${cypherFile}
      fi

     # run cypher in cypher-shell, use eval to allow printf to run in correct order
     # saving results file, run with tee command to create file
    if [[ ${save_results}  == "Y" ]]; then
      eval "[[ ${show_cmd_line} == "Y" ]] && printf '// Command line args: %s\n' \""${cmd_arg_msg}"\"; \
            [[ ${qry_start_time} == "Y" ]] && printf '// Query started: %s\n' \""$(date)"\";  \
            ${cypher_shell_cmd_line} < ${cypherFile}  2>&1" | tee  ${resultsFile} | less ${less_options[@]}
    else 
      eval "[[ ${show_cmd_line} == "Y" ]] && printf '// Command line args: %s\n' \""${cmd_arg_msg}"\"; \
            [[ ${qry_start_time} == "Y" ]] && printf '// Query started: %s\n' \""$(date)"\";  \
            ${cypher_shell_cmd_line} < ${cypherFile}  2>&1" | less ${less_options[@]}
    fi

     # ck return code - PIPESTATUS[0] for bash, pipestatus[1] for zsh
    if [[ ${PIPESTATUS[0]} -ne 0 || ${pipestatus[1]} -ne 0 ]]; then
      cypherRetCode=${RCODE_CYPHER_SHELL_ERROR}
    else
      findColonUseStmnt 
      cypherRetCode=${RCODE_SUCCESS}
    fi
  fi
}

generateFileNames () {
  (( file_nbr++ )) # increment file nbr if saving files
  date_stamp=$(date +%FT%I-%M-%S%p) # avoid ':' sublime interprets : as line / col numbers
  printf -v cypherFile "%s_%s_%s-%d%s" ${OUTPUT_FILES_PREFIX} ${date_stamp} ${SESSION_ID} ${file_nbr} ${QRY_FILE_POSTFIX}
  printf -v resultsFile "%s_%s_%s-%d%s" ${OUTPUT_FILES_PREFIX} ${date_stamp} ${SESSION_ID} ${file_nbr} ${RESULTS_FILE_POSTFIX}
}

intermediateFileHandling () {
  local cur_cypher_qry_file=${cypherFile}
  generateFileNames
  cat /dev/null > ${cypherFile} 
    # if not first time through, ck to save files, blank resultsFile
  if [[ ${edit_cnt} -ne 0 ]]; then
    if [[ -n ${editor_to_use} ]]; then # use previous file if using editor
      cp ${cur_cypher_qry_file} ${cypherFile}
    fi

    if [[ ${save_cypher} == "N" ]]; then
      find . -maxdepth 1 -type f -name "${cur_cypher_qry_file}"  -exec rm {} \;
    fi

    if [[ ${save_results} == "N" ]]; then
      find . -maxdepth 1 -type f -name "${resultsFile}"  -exec rm {} \;
    fi
  elif [[ ${edit_cnt} -eq 0 ]]; then # 1st time thru w/ input file
    if [[ -n ${input_cypher_file_name} ]]; then
      cp ${input_cypher_file_name} ${cypherFile}
    fi
  fi
}

getCypherText () {

  # input cypher text, either from pipe, editor, or stdin (usually terminal window in editor)
  if [[ -n ${input_cypher_file_name} && ${run_once} == "Y" ]]; then
    cat ${input_cypher_file_name} > ${cypherFile}  # run once with input file
    return
  elif [[ ! -n ${editor_to_use} ]]; then # using stdin
    if [[ ${is_pipe} == "N" ]]; then # input is from a pipe
      outputQryRunMsg # output run query header
    fi
      
    if [[ -n ${input_cypher_file_name} && ${edit_cnt} -eq 0 ]]; then # running from a file on first input
      cat ${input_cypher_file_name} | tee ${cypherFile} 
    else
      cat /dev/null > ${cypherFile}  # start clean since we're not in an editor. 
    fi
      # execute query w/o input if have input file and doing a -1 option
    local old_ifs=${IFS}
    while IFS= read -r line; do
      printf '%s\n' "$line" >> ${cypherFile}
    done
    IFS=${old_ifs}
  else # using external editor
    while true; do
      if [[ ${editor_to_use} != "vi" ]]; then
        ${editor_to_use} ${cypherFile}
      else # using vi
        if [[ ${edit_cnt} -eq 0 &&  -z "${input_cypher_file}" ]]; then
          ${editor_to_use} ${VI_INITIAL_OPEN_OPTS} ${cypherFile} # open file option +star (new file)
        else
          ${editor_to_use} ${cypherFile}
        fi
      fi
      # ask user if they want to run file or go back to edit
      
      outputQryRunMsg
      enterYesNoQuit "<CR>QN" "<Enter> to run query, (n) to continue to edit, (q) to exit ${SHELL_NAME} " 
      if [[ $? -eq 1 ]]; then # answered 'n', continue
        continue  # go back to edit on same file
      else # answered yes to running query
        break
      fi # continue with new intermediate files
    done
  fi
  (( edit_cnt++ ))  # increment query edit count
}


executionLoop () {
  # main loop for running cypher-shell until termination condition
  while true; do
    
    #if [[ ${edit_cnt} -gt 0 ]]; then # 0 means leave connection message
    #  clear # clear the terminal
    #fi

    intermediateFileHandling  # intermediate files for cypher and output
    getCypherText  # consume input

    cleanAndRunCypher 

    if [[ ${cypherRetCode} -eq 0 ]]; then
      # messageOutput "Finished query execution: $(date)"
      (( success_run_cnt++ ))
      if [[ -n ${editor_to_use} ]]; then # don't go straight back into editor
        outputQryRunMsg
        printContinueOrExit "Using ${editor_to_use} to edit."
      fi
    elif [[ ${exit_on_error} == "Y" ]]; then # print error and exit
      exitShell ${cypherRetCode} # ERROR running cypher code
    fi
    if [[ ${run_once} == "Y" || ${is_pipe} == "Y" ]]; then # exit shell if run 1, or is from a pipe
      exitShell ${cypherRetCode}
    fi
    clear

  done
}

# main
### shell accomodations

# for zsh to avoid having to do this for command line word split in this shell
# args=(${user_name} ${_} ${cypherShellArgs} ${cypher_format_arg})
# cypher-shell "${args[@]}"
setopt SH_WORD_SPLIT >/dev/null 2>&1
set -o pipefail

SHELL_NAME=${0##*/}  # shell name must be set here to avoid zsh / bash diffs

trap printContinueOrExit SIGINT 
trap exitShell SIGHUP SIGTERM 

setDefaults

if [[ ${is_pipe} == "N" ]]; then
  clear
fi

getArgs "$@"
haveCypherShell
verifyCypherShell   # verify that can connect to cypher-shell
get4xDbName         # get database name if using 4.x
fmtCurrentDbCmdArg # use 'current db' for db_cmd_arg
outputWelcomeMsg
executionLoop       # execute cypher statements
exitShell ${RCODE_SUCCESS}

