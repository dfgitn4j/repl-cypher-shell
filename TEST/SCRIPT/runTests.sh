#set -xv
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

# vars that might need to be modified 
TEST_SHELL='../../repl-cypher-shell.sh'
CYPHER_SHELL="$(which cypher-shell)" # change  if want to use a different cypher-shell
PATH=${CYPHER_SHELL}:${PATH} # put testing cypher-shell first in PATH


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

  testSuccessQry="WITH 1 AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;"
  testSuccessGrep="grep -c --color=never CYPHER_SUCCESS"

  testFailQry="WITH 1 AS CYPHER_SUCCESS RETURN gibberish;"

  testParamQry='WITH $strParam AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;'
  testParamParams="--param 'x => 2' --param 'strParam => \"goodParam\"'"
  testParamGrep="grep -c --color=never goodParam"
  testTimeParamGrep="grep -c --color=never '${TIME_OUTPUT_HEADER}'"

  runCnt=0
  successCnt=0
  errorCnt=0
  exitOnError="N" # set to Y to stop if any runShell tests fail.
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
    printf "%s\n\n" "Please clean up ${_fileCnt} previous output files. Tests can fail when they shouldn't if left in place."
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
  if [[ ${exitOnError} == "Y" ]]; then
    printf "%s\n\n" "Encountered a testing error and stopOnError = '${exitOnError}'.  Bye."
    rm ${QRY_OUTPUT_FILE} 
    exit
  fi 
}

existingFileCnt () {
  # 1st param is the file pattern to test
  _fileCnt=$(find * -type f -depth 0 | grep --color=never -E "${1}" | wc -l ) 
}


# output for screen and results file
printOutput () {

  printf "%s  Exit Code: %d  Exp Code: %d Input: %-6sErr Msg: %s\tDesc: %s\n" \
         ${msg} ${exitCode} ${expectedExitCode} ${testType} "${secondErrorMsg}" "${desc}"
  printf "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
         ${msg} ${exitCode} ${expectedExitCode} ${testType} \
         ${errVarNames[@]:${exitCode}:1} ${errVarNames[@]:${expectedExitCode}:1}  \
         ${usePipe} "'${callingParams}'" "'${secondErrorMsg}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}

}

paramErrorExit () {
  msg="${1}"
  printf "Parameters:\n"
  while (( "$#" )); do printf " '$1'\n"; shift; done 
  exit 1
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
# 2.  If exitCode is not zero, update error count
# 3.  Else if not checking for file existence (outputFilePattern is ""), and not check for 
#     a pattern in an output file (grepFileContentCmd is ""), then update success count.
# 4.  Else have file existence and file content existence tests
#  4a.   If outputFilePattern then validate file with ${outputFilePattern} exists and ${expectedNbrFiles} 
#         of them exist.  Valid ${expectedNbrFiles} is 0 and 1
#  4b.   If grep-ing for content in ${QRY_OUTPUT_FILE} and no error triggered by 4a, then run grep cmd 
#         ${grepFileContentCmd} to validate content in ${QRY_OUTPUT_FILE}
#  4c.   If no error, ${updateSuccessCnt} == Y, increment ${successCnt}, else increment ${errorCnt}
runShell () {

  expectedExitCode=${1}
  testType=${2}
  testQry="${3}"
  callingParams="${4}"
  outputFilePattern="${5}"
  expectedNbrFiles=${6}
  grepFileContentCmd="${7}"
  desc="${8:-not provided}"

  if [[ $# -lt 7 ]] ; then
    paramErrorExit "Exiting. Invalid # params to ${0}. Sent:\n(${@})\n Need at least 7, got: $#. Bye.\n"
  #elif [[ -z "${outputFilePattern}" && -n "${grepFileContentCmd}" ]]; then 
  #  paramErrorExit "${outputFilePattern} needs to exist if ${grepFileContentCmd} exists."
  fi

  secondErrorMsg="" # error not triggered by an invalid return code
  updateSuccessCnt="Y" # assume we're going to have successfull tests

  printf "%02d. " $(( ++runCnt ))  # screen output count

  if [[ ${testType} == "STDIN" ]]; then
    eval ${TEST_SHELL} -1 ${callingParams} >${QRY_OUTPUT_FILE} 2>/dev/null <<EOF
    ${testQry}
EOF
  exitCode=$?
  elif [[ ${testType} == "PIPE" ]]; then
    echo ${testQry} | eval ${TEST_SHELL} ${callingParams} >${QRY_OUTPUT_FILE} 
    exitCode=$?
  elif [[ ${testType} == "FILE" ]]; then # expecting -f <filename> parameter
    ${TEST_SHELL} -1 ${callingParams} >${QRY_OUTPUT_FILE} 
    exitCode=$?
  else
    # printf "Exiting. Invalid testType specification: '${testType}' Valid entries are STDIN, PIPE, FILE.\n"
    # printf "Parameters:\n"
    while (( "$#" )); do printf " '$1'\n"; shift; done 
    exit 1
  fi 

  rm ${QRY_OUTPUT_FILE} # remove transient transient output file
  updateSuccessCnt="N"
  if [[ ${exitCode} -ne ${expectedExitCode} ]]; then
    printf -v secondErrorMsg "%s" "Expected exit code = ${expectedExitCode}, got ${exitCode}"
  elif [[ -z ${outputFilePattern} ]]; then # no output files expected.
    existingFileCnt "${saveAllFilePattern}" # should be no files. error if there is
    if [[ ${_fileCnt} -ne 0 ]]; then
      secondErrorMsg="Output files from shell exist that should not be there."
    else
      updateSuccessCnt="Y"
    fi
  elif [[ -n ${outputFilePattern} ]]; then # file existence and file content existence tests
      # fileCnt=$(find * -type f -depth 0 | grep --color=never -E "${outputFilePattern}" | wc -l ) 
    existingFileCnt "${outputFilePattern}"
    if [[ ${_fileCnt} -ne ${expectedNbrFiles} ]]; then
        printf -v secondErrorMsg "%s" "Expected ${expectedNbrFiles} output files, got ${_fileCnt}"
        # clean up output files. not using find regex for portability
    elif [[ ! -z ${grepFileContentCmd} ]] && \
         [[ $(eval "${grepFileContentCmd} ${QRY_OUTPUT_FILE}") -eq 0 ]]; then # output of grep cmd should be > 0
      printf -v secondErrorMsg "%s" "grep command '${grepFileContentCmd}' on output file: ${QRY_OUTPUT_FILE} failed."
    else
      updateSuccessCnt="Y"
    fi
  else
    updateSuccessCnt="Y"
  fi

  if [[ "${updateSuccessCnt}" == "Y" && -n ${outputFilePattern} ]]; then  # clean up files
    for rmFile in $(find * -type f -depth 0 | grep --color=never -E "${outputFilePattern}" ) ; do
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
}


# someday write expect scripts for interactive input
testsToRun () {

    # output file header
  printf "Result\tExit Code\tExp Code\tInput Type\tshell Exit Var\tshell Expected Exit Var\tCalling Params\tError Message\tDescription\n" > ${RESULTS_OUTPUT_FILE}

  # set Neo4j uid / pw to a value if env vars not set
  uid="${NEO4J_USERNAME:-neo4j}"
  pw="${NEO4J_PASSWORD:-admin}"

  NEO4J_USERNAME=${uid}
  export NEO4J_USERNAME
  NEO4J_PASSWORD=${pw}
  export NEO4J_PASSWORD


  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  exitOnError="Y" # exit if runShell fails

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "" "" 0 "" \
           "tesing connection - using NEO4J_[USERNAME PASSWORD] environment variables."
  # exitOnError="N" # continue if runShell fails
  

  # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
  printf "\n*** Invalid paramater tests ***\n"  
  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "STDIN" "" "--param" "" 0 "" \
           "invalid param test - missing parameter argument value."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "STDIN" "" "--exitOnError noOptValExpected" "" 0 "" \
           "invalid param test - flag argument only, no option expected."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "" "-Nogood" "" 0 "" \
           "invalid param test - bad passthru argument to cypher-shell."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "STDIN" "" "--file" "" 0 "" \
           "invalid param test - missing file argument value."

  runShell ${RCODE_INVALID_FORMAT_STR} "STDIN" "" "--format notgood" "" 0 "" \
           "invalid param test - invalid format string."
 
  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "STDIN" "" "--vi --editor 'atom'" "" 0 "" \
           "invalid param test - conflicting editor args."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--vi" "" 0 "" \
           "invalid param test - incompatible editor argument and pipe input"

  touch ${TMP_TEST_FILE}
  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--file ${TMP_TEST_FILE}" "${QRY_OUTPUT_FILE}" 0 "" \
           "invalid param test - incompatible file input and pipe input."
  rm ${TMP_TEST_FILE}

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--exitOnError nogood" "" 0 "" \
           "invalid param test - flag argument only, no option expected."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "" "-Nogood" "" 0 "" \
           "invalid param test - bad pass thru argument to cypher-shell."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--file" "" 0 "" \
           "invalid param test - missing file argument value."

  runShell ${RCODE_INVALID_FORMAT_STR} "PIPE" "" "--format notgood" "" 0 "" \
           "invalid param test - invalid format string."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--vi --editor 'atom'" "" 0 "" \
           "invalid param test - conflicting editor args."
  
  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "" "--invalid param" "" 0 "" \
           "invalid param test - invalid parameter argument value."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "" "--invalid param" "" 0 "" \
           "invalid param test - invalid parameter argument value."
  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "" "--address n0h0st" "" 0 "" \
           "invalid param test - bad pass-thru argument to cypher-shell."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "" "--address n0h0st" "" 0 "" \
           "invalid param test - bad pass-thru argument to cypher-shell."

  runShell ${RCODE_CYPHER_SHELL_NOT_FOUND} "STDIN" "" "--cypher-shell /a/bad/directory/xxx" "" 0 "" \
           "invalid param test - explicitly set cypher-shell executable with --cypher-shell."

  # VALID PARAM TESTS
  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "--cypher-shell ${CYPHER_SHELL}" "" 0 "" \
           "param test - explicitly set cypher-shell executable with --cypher-shell."

  runShell ${RCODE_SUCCESS} "STDIN" "" "--version" "" 0 "" \
           "param test - cypher-shell one-and-done version arg."

  runShell ${RCODE_SUCCESS} "PIPE" "" "--version" "" 0 "" \
           "param test - cypher-shell one-and-done version arg."

  runShell ${RCODE_SUCCESS} "PIPE" "${testSuccessQry}" "--address localhost" "" 0 "" \
           "param test - good thru argument to cypher-shell."

  # PASSWORD TESTS
  printf "\n*** Starting uid / pw tests ***\n"  
  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "-u ${uid} -p ${pw}" "" 0 "" \
           "uid/pw tests - using -u and and -p arguments"

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "-u ${uid}" "" 0 "" \
           "uid/pw tests - using -u and NEO4J_PASSWORD environment variable."

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "-p ${pw}" "" 0 "" \
           "uid/pw tests - using -p and NEO4J_USERNAME environment variable."
  
  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "-p ${pw}" "" 0 "" \
           "uid/pw tests - using -p and NEO4J_USERNAME environment variable."
  
  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "${testSuccessQry}" "-p ${pw}xxx" "" 0 "" \
           "uid/pw tests - using -u bad password"

  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "${testSuccessQry}" "-u ${uid}xxx" "" 0 "" \
           "uid/pw tests - using -u bad username"
  
  unset NEO4J_USERNAME
  runShell ${RCODE_NO_USER_NAME} "PIPE" "${testSuccessQry}" "" "" 0 "" \
           "uid/pw tests - pipe input with no env or -u usename defined"
  export NEO4J_USERNAME=${uid}

  unset NEO4J_PASSWORD
  runShell ${RCODE_NO_PASSWORD} "PIPE" "${testSuccessQry}" "" "" 0 "" \
           "uid/pw tests - pipe input with no env or -p password defined"
  export NEO4J_PASSWORD=${pw}
  
  printf "\n*** Starting bad query test ***\n" 
  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "${testFailQry}" "" "" 0 "" \
           "query tests - bad cypher query"

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "${testFailQry}" "" "" 0 "" \
           "query tests - bad cypher query piped input"

  # QUERY INPUT TESTING 
  printf "\n*** Starting query method and param and output tests ***\n" 

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "--time" "" 0 "${testTimeParamGrep}" \
           "param test - test --time parameter output."

  runShell ${RCODE_SUCCESS} "STDIN" "${testParamQry}" "${testParamParams}" "" 0 "${testParamGrep}" \
           "param test - multiple arguments."

  runShell ${RCODE_SUCCESS} "PIPE" "${testParamQry}" "${testParamParams}" "" 0 "${testParamGrep}" \
           "param test - multiple arguments."

  runShell ${RCODE_EMPTY_INPUT} "STDIN" "" "" "" 0 "" \
           "query tests - empty cypher query"

  runShell ${RCODE_EMPTY_INPUT} "PIPE" "" "" "" 0 "" \
           "query tests - empty cypher query"

  runShell ${RCODE_EMPTY_INPUT} "STDIN" "" "-t -c --quiet" "" 0 "" \
           "query tests - empty cypher query with --quiet"

  runShell ${RCODE_EMPTY_INPUT} "PIPE" "" "-t -c --quiet" "" 0 "" \
           "query tests - empty cypher query with --quiet"

  echo "${testSuccessQry}" > ${TMP_TEST_FILE}
  runShell ${RCODE_SUCCESS} "FILE" "" "--file ${TMP_TEST_FILE}" "" 0 "${testSuccessGrep}" \
           "query / file tests - run external cypher file with valid query, validate output"

  runShell ${RCODE_MISSING_INPUT_FILE} "FILE" "" "--file NoFile22432.cypher" "" 0 "" \
           "query / file tests - run external cypher file missing file"

  echo "${TEST_SHELL}" > ${TMP_TEST_FILE}
  echo "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell ${RCODE_SUCCESS} "FILE" "" "--file ${TMP_TEST_FILE}" "" 0 "" \
           "query / file tests - executing shell name at beginning of text before cypher"
  rm ${TMP_TEST_FILE}

  # SAVE FILE TESTS
  printf "\n*** Starting save file test ***\n" 

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "--saveAll" "${saveAllFilePattern}" 2 "" \
           "file tests - save cypher query and text results files."

  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "--saveCypher" "${saveQryFilePattern}" 1 "" \
           "file tests - save cypher query file."
  
  runShell ${RCODE_SUCCESS} "STDIN" "${testSuccessQry}" "--saveResults" "${saveResultsFilePattern}" 1 "" \
           "file tests - save results file."

  runShell ${RCODE_SUCCESS} "PIPE" "${testSuccessQry}" "--saveResults" "${saveResultsFilePattern}" 1 "" \
           "file tests - save results file."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "${testFailQry}" "--saveResults" "${saveResultsFilePattern}" 1 "" \
           "file tests - bad query input save results file that will not exist."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "${testFailQry}" "--saveResults" "${saveResultsFilePattern}" 1 "" \
           "file tests - bad query input save results file that will not exist."

  runShell ${RCODE_EMPTY_INPUT} "STDIN" "" "--saveResults" "${saveResultsFilePattern}" 0 "" \
           "file tests - empty input query input save results file that will not exist."

  runShell ${RCODE_EMPTY_INPUT} "PIPE" "" "--saveResults" "${saveResultsFilePattern}" 0 "" \
           "file tests - empty input query input save results file that will not exist."

  printf "\nFinished. %s: %d  %s: %d\n" ${successMsg} ${successCnt} ${errorMsg} ${errorCnt}
}

#
# MAIN
#
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

testsToRun
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
