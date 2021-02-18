#set -xv
# set -e  # exit on error 
# test parameters in script.  Simpler than using expect
#
# Run with one parameter will return the variables used as exit codes in the 
# script being tested by grep'n for variables that begin with the pattern 
# RCODE in the function initVars (). 
#
# runTests () contains the calls to runShell for each individual test.
# 


# 
# initVars - get return code variables and values from script / set script variables
#

initVars () {
  vars=$(cat <<EOV
  $(cat ${TEST_SHELL} | sed -E -n 's/(^.*RCODE.*=[0-9]+)(.*$)/\1/p')
EOV
  )

  # turn var names into an array that the variables in tue above 
  #   eval statement will reference
  errVarNames=($(echo $vars | sed -E -e 's/=\-?[0-9]+//g'))

  # create ret code variables names with value
  eval $vars 
  
  successMsg="PASS"
  errorMsg="FAIL"

  # RESULTS_OUTPUT_FILE="resultsTestRun-$(date '+%Y-%m-%d_%H:%M:%S')".txt
 
  # some failure tests work on matching the saveAllFilePattern. Temp files 
  # cannot use those postfix's
  #
  # get output file patterns, assumes variable definition in script is the first pattern that matches
  eval "$(grep --color=never OUTPUT_FILES_PREFIX= ${TEST_SHELL} | head -1)" 
  eval "$(grep --color=never QRY_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never TIME_OUTPUT_HEADER= ${TEST_SHELL} | head -1)"

   # file patterns for file existence test
  saveAllFilePattern="${OUTPUT_FILES_PREFIX}.*(${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})"
  saveQryFilePattern="${OUTPUT_FILES_PREFIX}.*${QRY_FILE_POSTFIX}"
  saveResultsFilePattern="${OUTPUT_FILES_PREFIX}.*${RESULTS_FILE_POSTFIX}"
  TMP_TEST_FILE=aFile_${RANDOM}${QRY_FILE_POSTFIX}
  QRY_OUTPUT_FILE="qryResults_${RANDOM}.tmpQryOutputFile"
  RESULTS_OUTPUT_FILE="resultsTestRun.out"
  MY_FILE_NAME="myFileName" # for testing defining input name

  testSuccessQry="WITH 1 AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;"
  testSuccessGrep="grep -c --color=never CYPHER_SUCCESS"

  testFailQry="WITH 1 AS CYPHER_SUCCESS RETURN gibberish;"

  testParamQry='WITH $strParam AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;'
  testParamParams="--param 'x => 2' --param 'strParam => \"goodParam\"'"
  testParamGrep="grep -c --color=never goodParam"
  testTimeParamGrep="grep -c --color=never '${TIME_OUTPUT_HEADER}'"
}

# ckForLeftoverOutputFiles () {
#   existingFileCnt "${QRY_OUTPUT_FILE}" # should be no files. error if there is
#   if [[ ${_fileCnt} -ne 0 ]]; then
#     printf "%s\n\n" "Please clean up previous output files. Tests can fail when they shouldn't if left in place."
#     find * -type f -depth 0 | grep --color=never -E "${saveAllFilePattern}"
#     printf "%s\n\n" "Bye."
#     exit
#   fi
# }
exitShell () {

  rm -f ${QRY_OUTPUT_FILE}

  existingFileCnt "${saveAllFilePattern}" # should be no files. error if there is
  if [[ ${_fileCnt} -ne 0 ]]; then
    printf "Please clean up %d previous output files. Tests can fail when they shouldn't if left in place.\n\n" ${_fileCnt} 
    find * -type f -depth 0 | grep  -E "${1}" 
    printf "%s\n\n" "Bye."
  fi
  exit ${1}
}

interruptShell () {
  printf "\nCtl-C pressed. Bye.\n\n"
  exec <&- # close stdin
  printf "Last ${TEST_SHELL} output message:\n\n"
  cat ${QRY_OUTPUT_FILE}
  exitShell 1
}

exitOnError () {
  if [[ ${EXIT_ON_ERROR} == "Y" ]]; then
    printf "%s\n\n" "Encountered a testing error and EXIT_ON_ERROR = '${EXIT_ON_ERROR}'.  Bye."
    # rm -f ${QRY_OUTPUT_FILE} 
    exit 1
  fi 
}

enterToContinue () {
  if [[ ${ENTER_TO_CONTINUE} == "Y" ]]; then
    printf 'Enter to continue.'
    read n
  fi
}

existingFileCnt () {
  # 1st param is the file pattern to test
  _fileCnt=$(find * -type f -depth 0 | grep --color=never -E "${1}" | wc -l ) 
}

# output for screen and results file
printOutput () {
 #24. PASS  Exit Code: 0  Exp Code: 0 Input: STDIN Err Msg:   Desc: uid/pw tests - using -u and and -p arguments
 # PASS  Exit Code: 0  Exp Code: 0 Input: not providedErr Msg:   Desc: 


  printf "%s  Exit Code: %d  Exp Code: %d Input: %-6s Err Msg: %s Shell: %-4s Desc: %s\n" \
         ${msg} ${actualRetCode} ${expectedRetCode} "${type}" "${secondErrorMsg}" "${shellToUse}" "${desc}"
  printf "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
         ${msg} ${actualRetCode} ${expectedRetCode} ${type} \
         ${errVarNames[@]:${actualRetCode}:1} ${errVarNames[@]:${expectedRetCode}:1}  \
         ${usePipe} "'${callingParams}'" "'${secondErrorMsg}'" "'${shellToUse}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}
}


# runShell ()
# meant to test the various parameter combinations at a surface level, bit of a hack
#
# Behavior control parameters:
#
# outputFilePattern  - the grep pattern used to validate a file exists. Easiest and most portable
# grepFileContentCmd - full grep command to validate a string exists in the ${QRY_OUTPUT_FILE}
# expectedNbrFiles   - valid values are 0 and 1
#
# Test ordering:
# 1.  ${testType} runs tested script with either STDIN, PIPE or FILE as input. capture script exit code
# 2.  If actualRetCode is not zero, update error count
# 3.  Else if not checking for file existence (outputFilePattern is ""), and not check for 
#     a pattern in an output file (grepFileContentCmd is ""), then update success count.
# 4.  Else have file existence and file content existence tests
#  4a.   If outputFilePattern then validate file with ${outputFilePattern} exists and ${expectedNbrFiles} 
#         of them exist.  Valid ${expectedNbrFiles} is 0 and 1
#  4b.   If grep-ing for content in ${QRY_OUTPUT_FILE} and no error triggered by 4a, then run grep cmd 
#         ${grepFileContentCmd} to validate content in ${QRY_OUTPUT_FILE}
#  4c.   If no error, ${updateSuccessCnt} == Y, increment ${successCnt}, else increment ${errorCnt}
#
# Parameters are a param / value pair, e.g. --nbrFiles 0 will set nbrFiles=0
#
# PARAMETERS
#   REQUIRED 
#     --expectedRetCode integer
#     --type "FILE" | "STDIN" | "PIPE"
#     --qry cypher query string
#     --params parameter string for call to repl-cypher-shell.sh
#     --outPattern output file(s) pattern string
#     --nbrFiles integer for expected number of files
#     --grepPattern file content grep pattern string
#  
#     OPTIONAL
#       --shell string representing shell to use, ksh or zsh
#       --desc description string for testing ouput 

runShell () {
  inParams=${@}  # save params in case missing any

   # var values have -- removed, next param is value
  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      declare $paramName="${2}"  # set parameter value
    fi
    shift;shift
  done
  if [[ ! -n ${expectedRetCode+x} || ! -n ${type+x} || ! -n ${qry+x} || \
        ! -n ${params+x} || ! -n ${outPattern+x} || ! -n ${nbrFiles+x} || \
        ! -n ${grepPattern+x} ]]; then
    printf '\n%s\n' "*** ERROR *** Missing required parameter(s) to function runShell."
    printf "Call:\n"
    printf " runShell ${inParams}\n\n"
    exitShell 1
  fi

  desc="${desc:-not provided}"  # description is optional
  shellToUse="${shell:-zsh}"

  secondErrorMsg="" # error not triggered by an invalid return code
  updateSuccessCnt="Y" # assume we're going to have successfull tests

  printf "%02d. " $(( ++runCnt ))  # screen output count

  if [[ ${type} == "STDIN" ]]; then
    eval ${shellToUse} ${TEST_SHELL} -1 ${params} >${QRY_OUTPUT_FILE} 2>/dev/null <<EOF
    ${qry}
EOF
    actualRetCode=$?

  elif [[ ${type} == "PIPE" ]]; then
    echo ${qry} | eval ${shellToUse} ${TEST_SHELL} ${params} >${QRY_OUTPUT_FILE} 
    actualRetCode=$?
  elif [[ ${type} == "FILE" ]]; then # expecting -f <filename> parameter
    ${shellToUse} ${TEST_SHELL} -1 ${params} >${QRY_OUTPUT_FILE} 
    actualRetCode=$?
  else
    # printf "Exiting. Invalid type specification: '${type}' Valid entries are STDIN, PIPE, FILE.\n"
    # printf "Parameters:\n"
    while (( "$#" )); do printf " '$1'\n"; shift; done 
    exit 1
  fi 

  rm ${QRY_OUTPUT_FILE} # remove transient transient output file
  updateSuccessCnt="N"
  if [[ ${actualRetCode} -ne ${expectedRetCode} ]]; then
    printf -v secondErrorMsg "%s" "Expected exit code = ${expectedRetCode}, got ${actualRetCode}"
  elif [[ -z ${outPattern} ]]; then # no output files expected.
    existingFileCnt "${saveAllFilePattern}" # should be no files. error if there is
    if [[ ${_fileCnt} -ne 0 ]]; then
      secondErrorMsg="Output files from shell exist that should not be there."
    else
      updateSuccessCnt="Y"
    fi
  elif [[ -n ${outPattern} ]]; then # file existence and file content existence tests
      # fileCnt=$(find * -type f -depth 0 | grep --color=never -E "${outPattern}" | wc -l ) 
    existingFileCnt "${outPattern}"
    if [[ ${_fileCnt} -ne ${nbrFiles} ]]; then
        printf -v secondErrorMsg "%s" "Expected ${nbrFiles} output files, got ${_fileCnt}"
        # clean up output files. not using find regex for portability
    elif [[ ! -z ${grepPattern} ]] && \
         [[ $(eval "${grepPattern} ${QRY_OUTPUT_FILE}") -eq 0 ]]; then # output of grep cmd should be > 0
      printf -v secondErrorMsg "%s" "grep command '${grepPattern}' on output file: ${QRY_OUTPUT_FILE} failed."
    else
      updateSuccessCnt="Y"
    fi
  else
    updateSuccessCnt="Y"
  fi

  if [[ "${updateSuccessCnt}" == "Y" ]]; then  # clean up qry and results files regardless
    for rmFile in $(find * -type f -depth 0 | grep --color=never -E "${saveAllFilePattern}" ) ; do
      rm ${rmFile}
    done 
  fi

   # set status message and update counts
  if [[ ${updateSuccessCnt} == "Y" ]]; then
    msg="${successMsg}"
    (( ++successCnt ))
    printOutput
  else
    msg="${errorMsg}"
    (( ++errorCnt ))
    printOutput
    exitOnError 
  fi
  enterToContinue
}

chgSaveFilePattern() {
   # $1 = use default output file patterns or new. $2 = new file pattern
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    printf "\n%s\n" "*** Internal error in function chgSaveFilePattern(). Invalid parameters "
    while (( "$#" )); do printf " ${1} "; shift; done 
    exitShell 1
  fi

  if [[ ${1} == "--default" ]]; then
    saveAllFilePattern="${OUTPUT_FILES_PREFIX}.*(${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})"
    saveQryFilePattern="${OUTPUT_FILES_PREFIX}.*${QRY_FILE_POSTFIX}"
    saveResultsFilePattern="${OUTPUT_FILES_PREFIX}.*${RESULTS_FILE_POSTFIX}"
  elif [[ ${1} == "--new" ]]; then
    if [[ -z ${2} ]]; then 
      printf "\n%s\n" "*** Internal error in function chgSaveFilePattern(). Missing file name paramenter."
      exitShell 
    fi
    saveAllFilePattern="${2}.*(${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})"
    saveQryFilePattern="${2}.*${QRY_FILE_POSTFIX}"
    saveResultsFilePattern="${2}.*${RESULTS_FILE_POSTFIX}"
  else
    printf "\n%s\n" "*** Internal error in function $0. invalid option ${1} "
    exitShell 1
  fi
}
# someday write expect scripts for interactive input
testsToRun () {

  runCnt=0
  successCnt=0
  errorCnt=0
   # first and only parameter must be a shell to run
  shellParam=${1:-zsh}
  printf "Starting using ${shellParam}\n"
    # output file header
  printf  "Result\tExit Code\tExp Code\tInput Type\tshell Exit Var\tshell Expected Exit Var\tCalling Params\tError Message\tShell\tDescription\n" > ${RESULTS_OUTPUT_FILE}

  echo "// ONE" > ${TMP_TEST_FILE}
  echo "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE" --qry "" \
           --params "--file ${TMP_TEST_FILE}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "ONE" --shell ${shellParam} \
           --desc "query / file tests - run external cypher file with valid query, validate output"
  
  echo "// TWO" > ${TMP_TEST_FILE}
  echo "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE" --qry "" \
           --params "--file ${TMP_TEST_FILE}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "TWO" --shell ${shellParam} \
           --desc "query / file tests - run external cypher file with valid query, validate output"
exit
  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  printf "\n*** Initial db connect test ***\n" 
  EXIT_ON_ERROR="Y"
   # 01
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params ""  --outPattern "" \
           --nbrFiles 0 --grepPattern "" --shell ${shellParam} \
           --desc "tesing connection - using NEO4J_[USERNAME PASSWORD] environment variables."
  EXIT_ON_ERROR="N"

  # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
  printf "\n*** Invalid paramater tests ***\n"  
   # 02
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN" --qry "" \
           --params "--param"  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "invalid param test - missing parameter argument value."
    # 03
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN" --qry "" \
           --params "--exitOnError noOptValExpected"  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "invalid param test - flag argument only, no option expected."
    # 04
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "" \
           --params "-Nogood"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc  "invalid param test - bad passthru argument to cypher-shell."
    # 05
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN" --qry "" \
           --params "--file"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - missing file argument value."
     # 06
  runShell --expectedRetCode ${RCODE_INVALID_FORMAT_STR} --type "STDIN" --qry "" \
           --params "--format notgood"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - invalid format string."
     # 07
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN" --qry "" \
           --params "--vi --editor 'atom'"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - conflicting editor args."
    # 08
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE" --qry "" \
           --params "--vi"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - incompatible editor argument and pipe input"

  touch ${TMP_TEST_FILE}
    # 09
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE" --qry "" \
           --params "--file ${TMP_TEST_FILE}"  --outPattern "${QRY_OUTPUT_FILE}" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - incompatible file input and pipe input."
  rm ${TMP_TEST_FILE}

    # 10
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE" --qry "" \
           --params "--exitOnError nogood"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - flag argument only, no option expected."
    # 11
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "" \
           --params "-Nogood"  --outPattern "" --shell ${shellParam} \
           --nbrFiles 0  --grepPattern "" \
           --desc "invalid param test - bad pass thru argument to cypher-shell."
    # 12
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE" --qry "" \
           --params "--file"  --outPattern "" --shell ${shellParam} \
           --nbrFiles 0  --grepPattern "" \
           --desc "invalid param test - missing file argument value."
    # 13
  runShell --expectedRetCode ${RCODE_INVALID_FORMAT_STR} --type "PIPE" --qry "" \
           --params "--format notgood" --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc  "invalid param test - invalid format string."
    # 14
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE" --qry "" \
           --params "--vi --editor 'atom'"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - conflicting editor args."
  
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "" \
           --params "--invalid param"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           "invalid param test - invalid parameter argument value."
    # 15
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "" \
           --params "--invalid param"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - invalid parameter argument value."
    # 16
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "" \
           --params "--address n0h0st"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - bad pass-thru argument to cypher-shell."
    # 17
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "" \
           --params "--address n0h0st"  --outPattern "" --shell ${shellParam} \
           --nbrFiles 0  --grepPattern "" \
           --desc "invalid param test - bad pass-thru argument to cypher-shell."
    # 18
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_NOT_FOUND} --type "STDIN" --qry "" \
           --params "--cypher-shell /a/bad/directory/xxx"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "invalid param test - explicitly set cypher-shell executable with --cypher-shell."

  # VALID PARAM TESTS
    # 19
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--cypher-shell ${CYPHER_SHELL}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "param test - explicitly set cypher-shell executable with --cypher-shell."
    # 20
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "" \
           --params "--version"  --outPattern "" --shell ${shellParam} \
           --nbrFiles 0  --grepPattern "" \
           --desc "param test - cypher-shell one-and-done version arg."
    # 21
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "" \
           --params "--version"  --outPattern "" --shell ${shellParam} \
           --nbrFiles 0  --grepPattern "" \
           --desc "param test - cypher-shell one-and-done version arg."
    # 22
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--address localhost"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "param test - good thru argument to cypher-shell."

  # PASSWORD TESTS
  printf "\n*** Starting uid / pw tests ***\n" 
    # 23 
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid} -p ${pw}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "uid/pw tests - using -u and and -p arguments"
    # 24
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "uid/pw tests - using -u and NEO4J_PASSWORD environment variable."
    # 25
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "uid/pw tests - using -p and NEO4J_USERNAME environment variable."
    # 26 
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "uid/pw tests - using -p and NEO4J_USERNAME environment variable."
    # 27
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}xxx"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "uid/pw tests - using -u bad password"
    # 28
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid}xxx" --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam}\
           --desc "uid/pw tests - using -u bad username"
  
  unset NEO4J_USERNAME
    # 29
  runShell --expectedRetCode ${RCODE_NO_USER_NAME} --type "PIPE" --qry "${testSuccessQry}" \
           --params ""  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "uid/pw tests - pipe input with no env or -u usename defined"
  export NEO4J_USERNAME=${uid}

    # 30
  unset NEO4J_PASSWORD
  runShell --expectedRetCode ${RCODE_NO_PASSWORD} --type "PIPE" --qry "${testSuccessQry}" \
           --params ""  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "uid/pw tests - pipe input with no env or -p password defined"
  export NEO4J_PASSWORD=${pw}
  
  printf "\n*** Starting bad query test ***\n" 
    # 31
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testFailQry}" \
           --params ""  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "query tests - bad cypher query"
    # 32
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "${testFailQry}" \
           --params ""  --outPattern "" \
           --nbrFiles 0  --grepPattern ""  --shell ${shellParam} \
           --desc "query tests - bad cypher query piped input"

  # QUERY INPUT TESTING 
  printf "\n*** Starting query method and param and output tests ***\n" 
    # 33
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--time"  --outPattern "" \
           --nbrFiles 0  --grepPattern "${testTimeParamGrep}" --shell ${shellParam} \
           --desc "param test - test --time parameter output."
    # 34
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testParamQry}" \
           --params "${testParamParams}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "${testParamGrep}" --shell ${shellParam} \
           --desc "param test - multiple arguments."
    # 35
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testParamQry}" \
           --params "${testParamParams}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "${testParamGrep}" --shell ${shellParam} \
           --desc  "param test - multiple arguments."
    # 36
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN" --qry "" \
           --params ""  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "query tests - empty cypher query"
    # 37
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE" --qry "" \
           --params ""  --outPattern ""\
           --nbrFiles  0  --grepPattern "" --shell ${shellParam} \
           "query tests - empty cypher query"
    # 38
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN" --qry "" \
           --params "-t -c --quiet"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "query tests - empty cypher query with --quiet"
    # 39
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE" --qry "" \
           --params "-t -c --quiet"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "query tests - empty cypher query with --quiet"
    # 40
  echo "${testSuccessQry}" > ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE" --qry "" \
           --params "--file ${TMP_TEST_FILE}"  --outPattern "" \
           --nbrFiles 0  --grepPattern "${testSuccessGrep}" --shell ${shellParam} \
           --desc "query / file tests - run external cypher file with valid query, validate output"
    # 41
  runShell --expectedRetCode ${RCODE_MISSING_INPUT_FILE} --type "FILE" --qry "" \
           --params "--file NoFile22432.cypher"  --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "query / file tests - run external cypher file missing file"

    # 42
  echo "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE" --qry "" \
           --params "--file ${TMP_TEST_FILE}"   --outPattern "" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "query / file tests - executing shell name at beginning of text before cypher"
  rm ${TMP_TEST_FILE}

  # SAVE FILE TESTS
  printf "\n*** Starting save file test ***\n" 
    # 43
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveAll"  --outPattern "${saveAllFilePattern}" \
           --nbrFiles 2  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save cypher query and text results files."
    # 44
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveCypher"  --outPattern "${saveQryFilePattern}" \
           --nbrFiles 1  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save cypher query file."
     # 45 
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 1  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save results file."
    # 46
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}"  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 1  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save results file."
    # 47
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testFailQry}"  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 1  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - bad query input save results file that will not exist."
    # 48
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "${testFailQry}"  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 1  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - bad query input save results file that will not exist."
    # 49
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN" --qry ""  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - empty input query input save results file that will not exist."
    # 50
  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE" --qry ""  \
           --params "--saveResults"  --outPattern "${saveResultsFilePattern}" \
           --nbrFiles 0  --grepPattern "" --shell ${shellParam} \
           --desc "file tests - empty input query input save results file that will not exist."

  # begin testing own output file names
    # 51
  chgSaveFilePattern --new "${MY_FILE_NAME}"
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveAll ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 2 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."
    # 52
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveCypher ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 1 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."
    # 53
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveResults ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 1 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."
    # 54
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveAll ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 2 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."
    # 55
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveCypher ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 1 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."
    # 56
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveResults ${MY_FILE_NAME}" --outPattern "${saveAllFilePattern}" \
           --nbrFiles 1 --grepPattern "" --shell ${shellParam} \
           --desc "file tests - save with my defined file pattern."

  printf "\nFinished using %s. %s: %d  %s: %d\n" ${shellParam} ${successMsg} ${successCnt} ${errorMsg} ${errorCnt}
}

#
# MAIN
#
setopt SH_WORD_SPLIT >/dev/null 2>&1

# vars that might need to be modified 
TEST_SHELL='../../repl-cypher-shell.sh'
CYPHER_SHELL="$(which cypher-shell)" # change  if want to use a different cypher-shell
PATH=${CYPHER_SHELL}:${PATH} # put testing cypher-shell first in PATH

# set Neo4j uid / pw to a value if env vars not set
uid="${NEO4J_USERNAME:-neo4j}"
pw="${NEO4J_PASSWORD:-admin}"
NEO4J_USERNAME=${uid}
export NEO4J_USERNAME
NEO4J_PASSWORD=${pw}
export NEO4J_PASSWORD

EXIT_ON_ERROR="Y"   # exit if runShell fails, "N" to continue
ENTER_TO_CONTINUE="N" # press enter to continue to next test

trap interruptShell SIGINT

initVars

if [[ $# -gt 0 ]]; then # any param prints shell variables 
  printf "\nError vars starting with RCODE from shell:"
  printf "\n==========\n\n"
  printf "%s\n" ${vars}
  printf "\n==========\n"
  exit 0
fi  

# ckForLeftoverOutputFiles 
for shell in 'zsh' 'bash'; do
  chgSaveFilePattern --default
  testsToRun ${shell}
done
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
