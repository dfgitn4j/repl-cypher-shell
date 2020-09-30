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
TESTSHELL='../../sTrp-cypher-shell.sh'
initVars () {
  vars=$(cat <<EOV
  $(cat ${TESTSHELL} | sed -E -n 's/(^.*RCODE.*=[0-9]+)(.*$)/\1/p')
EOV
  )

  # turn var names into an array that the variables in tue above 
  #   eval statement will reference
  errVarNames=($(echo $vars | sed -E -e 's/=\-?[0-9]+//g'))

  # create ret code variables names with value
  eval $vars 
  
   # get output file patterns
  eval "$(grep --color=never OUTPUT_FILES_PREFIX= ${TESTSHELL})" 
  eval "$(grep --color=never QRY_FILE_POSTFIX= ${TESTSHELL})"
  eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TESTSHELL})"

   # file patterns for file existence test
  saveAllFilePattern="${OUTPUT_FILES_PREFIX}.*(${QRY_FILE_POSTFIX}|${RESULTS_FILE_POSTFIX})"
  saveQryFilePattern="${OUTPUT_FILES_PREFIX}.*${QRY_FILE_POSTFIX}"
  saveResultsFilePattern="${OUTPUT_FILES_PREFIX}.*${RESULTS_FILE_POSTFIX}"

  successMsg="PASS"
  errorMsg="FAIL"

   # outFile="resultsTestRun-$(date '+%Y-%m-%d_%H:%M:%S')".txt
  outFile=resultsTestRun.txt
   # output file header
  printf "Result\tExit Code\tExp Code\tInput Type\tshell Exit Var\tshell Exp Var\tPipe\tCalling Params\tDescription\n" > ${outFile}

  qryOutputFile="qryResults.txt"

  testSuccessQry="WITH 1 AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;"
  testSuccessGrep="grep -c --color=never CYPHER_SUCCESS"

  testFailQry="WITH 1 AS CYPHER_SUCCESS RETURN gibberish;"

  testParamQry='WITH $strParam AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;'
  testParamParams="--param 'x => 2' --param 'strParam => \"goodParam\"'"
  testParamGrep="grep -c --color=never goodParam"

  runCnt=0
  successCnt=0
  errorCnt=0
  exitOnError="N" # set to Y to stop if any runShell tests fail.
}

exitShell () {
  printf "\nCtl-C pressed. Bye.\n\n"
  exec <&- # close stdin
  cat ${qryOutputFile}
  exit 1
}

exitOnError () {
  if [[ ${exitOnError} == "Y" ]]; then
    printf "Encountered a testing error and stopOnError = '${exitOnError}'.  Bye."
    exit
  fi 
}

# runShell ()
# meant to test the various parameter combinations at a surface level, bit of a hack
#
# Behavior control parameters:
#
# outputFilePattern  - the grep pattern used to validate a file exists. Easiest and most portable
# grepFileContentCmd - full grep command to validate a string exists in the ${qryOutputFile}
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
#  4b.   If grep-ing for content in ${qryOutputFile} and no error triggered by 4a, then run grep cmd 
#         ${grepFileContentCmd} to validate content in ${qryOutputFile}
#  4c.   If no error, ${updateSuccessCnt} == Y, increment ${successCnt}, else increment ${errorCnt}

runShell () {
  if [[ $# -lt 7 ]] ; then
    printf "Exiting. Invalid # params to ${0}. Sent:\n(${@})\n Need at least 7, got: $#. Bye.\n"
    printf "Parameters:\n"
    while (( "$#" )); do printf " '$1'\n"; shift; done 
    exit 1
  fi
  expectedExitCode=${1}
  testType=${2}
  testQry="${3}"
  callingParams="${4}"
  outputFilePattern="${5}"
  expectedNbrFiles=${6}
  grepFileContentCmd="${7}"
  desc="${8:-not provided}"

  printf "%02d. " $(( ++runCnt ))

  if [[ ${testType} == "STDIN" ]]; then
    eval ${TESTSHELL} -1 ${callingParams} >${qryOutputFile} 2>/dev/null <<EOF
    ${testQry}
EOF
    exitCode=$?
  elif [[ ${testType} == "PIPE" ]]; then
    echo ${testQry} | eval ${TESTSHELL} ${callingParams} >${qryOutputFile} 
    exitCode=$?
  elif [[ ${testType} == "FILE" ]]; then # expecting -f <filename> parameter
    ${TESTSHELL} -1 ${callingParams} >${qryOutputFile} 
    exitCode=$?
  else
    # printf "Exiting. Invalid testType specification: '${testType}' Valid entries are STDIN, PIPE, FILE.\n"
    # printf "Parameters:\n"
    while (( "$#" )); do printf " '$1'\n"; shift; done 
    exit 1
  fi 

   # test results
  if [[ ${exitCode} -ne ${expectedExitCode} ]]; then
    msg="${errorMsg}"
    (( ++errorCnt ))
    exitOnError 
  elif [[ -z ${outputFilePattern} && -z ${grepFileContentCmd} ]]; then # no output files expected.
    msg="${successMsg}"
    (( ++successCnt ))
  else # file existence and file content existence tests
    updateSuccessCnt="Y" # assume we're going to have successfull tests
    if [[ ! -z ${outputFilePattern} ]]; then # file existence checks and count tests
      fileCnt=$(find * -type f -depth 0 | grep --color=never -E "${outputFilePattern}" | wc -l ) 
      if [[ ${fileCnt} -eq ${expectedNbrFiles} ]]; then
        # not using find regex for portability
        for rmFile in $(find * -type f -depth 0 | grep --color=never -E "${outputFilePattern}" ) ; do
          rm -f ${rmFile}
        done 
      else # error, did not find the number of expected files
        updateSuccessCnt="N"
      fi
    fi # validate existence and number of files

    if [[ ! -z ${grepFileContentCmd} && ${updateSuccessCnt} == "Y" ]]; then # have file, validate text in output. 
      if [[ $(eval "${grepFileContentCmd} ${qryOutputFile}") -eq 0 ]]; then 
        updateSuccessCnt="N"
      fi
    fi
    if [[ ${updateSuccessCnt} == "Y" ]]; then
      msg="${successMsg}"
      (( ++successCnt ))
    else
      msg="${errorMsg}"
      (( ++errorCnt ))
      exitOnError
    fi 
  fi

  printf "%s  Exit Code: %d  Exp Code: %d  Input: %s\tDesc: %s\n" \
         ${msg} ${exitCode} ${expectedExitCode} ${testType} "${desc}"
  printf "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n" \
         ${msg} ${exitCode} ${expectedExitCode} ${testType} \
         ${errVarNames[@]:${exitCode}:1} ${errVarNames[@]:${expectedExitCode}:1}  \
         ${usePipe} "'${callingParams}'" "'${desc}'" >> ${outFile}
}


# someday write expect scripts for interactive input
testsToRun () {

  #  RCODE_SUCCESS=0
  #  RCODE_INVALID_CMD_LINE_OPTS=1
  #  RCODE_CYPHER_SHELL_NOT_FOUND=2
  #  RCODE_CYPHER_SHELL_ERROR=3
  #  RCODE_INVALID_FORMAT_STR=4
  #  RCODE_NO_USER_NAME=5
  #  RCODE_NO_PASSWORD=6
  #  RCODE_EMPTY_INPUT=7
  #  RCODE_MISSING_INPUT_FILE=8

  # PASSWORD TESTS
  printf "\n*** Starting uid / pw tests ***\n"

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
           "uid/pw tests - using NEO4J_[USERNAME PASSWORD] environment variables."
  exitOnError="N" # continue if runShell fails
  
  # INVALID PARAMETER TESTS 
  # none of these test should ever get to executing a query
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

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "STDIN" "" "-t -c --quiet" "" 0 "" \
           "invalid param test - cypher-shell conflicting extra info and quiet args."

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--vi" "" 0 "" \
           "invalid param test - incompatible editor argument and pipe input"

  touch aFile.txt  
  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "--file aFile.txt" "" 0 "" \
           "invalid param test - incompatible file input and pipe input."
  rm aFile.txt

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

  runShell ${RCODE_INVALID_CMD_LINE_OPTS} "PIPE" "" "-t -c --quiet" "" 0 "" \
           "invalid param test - cypher-shell conflicting extra info and quiet args."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "" "--address n0h0st" "" 0 "" \
           "param test - bad pass-thru argument to cypher-shell."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "" "--address n0h0st" "" 0 "" \
           "param test - bad pass-thru argument to cypher-shell."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "STDIN" "" "--invalid param" "" 0 "" \
           "invalid param test - invalid parameter argument value."

  runShell ${RCODE_CYPHER_SHELL_ERROR} "PIPE" "" "--invalid param" "" 0 "" \
           "invalid param test - invalid parameter argument value."

  # VALID PARAM TESTS
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
  printf "\n*** Starting query / input method and param tests ***\n" 

  runShell ${RCODE_SUCCESS} "STDIN" "${testParamQry}" "${testParamParams}" "" 0 "${testParamGrep}" \
           "param test - multiple arguments."

  runShell ${RCODE_SUCCESS} "PIPE" "${testParamQry}" "${testParamParams}" "" 0 "${testParamGrep}" \
           "param test - multiple arguments."

  runShell ${RCODE_EMPTY_INPUT} "STDIN" "" "" "" 0 "" \
           "query tests - empty cypher query"

  runShell ${RCODE_EMPTY_INPUT} "PIPE" "" "" "" 0 "" \
           "query tests - empty cypher query"

  echo "${testSuccessQry}" > runMe.cypher
  runShell ${RCODE_SUCCESS} "FILE" "" "--file runMe.cypher" "" 0 "${testSuccessGrep}" \
           "query / file tests - run external cypher file with valid query, validate output"

  runShell ${RCODE_MISSING_INPUT_FILE} "FILE" "" "--file NoFile.cypher" "" 0 "" \
           "query / file tests - run external cypher file missing file"

  echo "${TESTSHELL}" > runMe.cypher
  echo "${testSuccessQry}" >> runMe.cypher
  runShell ${RCODE_SUCCESS} "FILE" "" "--file runMe.cypher" "" 0 "" \
           "query / file tests - executing shell name at beginning of text before cypher"
  rm runMe.cypher

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

  rm ${qryOutputFile}  # remove last output file

  printf "\nFinished. %s: %d  %s: %d\n" ${successMsg} ${successCnt} ${errorMsg} ${errorCnt}
  
}

#
# MAIN
#
trap exitShell SIGINT

initVars

if [[ $# -gt 0 ]]; then # any param prints shell variables 
  printf "\nError vars starting with RCODE from shell:"
  printf "\n==========\n\n"
  printf "%s\n" ${vars}
  printf "\n==========\n"
  exit 0
fi  

testsToRun
./formatOutput.sh ${outFile}
