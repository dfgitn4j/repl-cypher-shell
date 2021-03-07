# set -e  # exit on error 
# test parameters in script.  Simpler than using expect
#
# Run with one parameter will return the variables used as exit codes in the 
# script being tested by grep'n for variables that begin with the pattern 
# RCODE in the function initVars (). 
#
# runTests () contains the calls to runShell for each individual test.
# 

getVars() {
  # turn var names into an array that the variables in tue above 
  # eval statement will reference
  vars=$(cat <<EOV
  $(cat ${TEST_SHELL} | sed -E -n 's/(^.*RCODE.*=[0-9]+)(.*$)/\1/p')
EOV
  )

  errVarNames=($(echo $vars | sed -E -e 's/=\-?[0-9]+//g'))
  eval $vars   # create ret code variables names with value
}

# 
# initVars - get return code variables and values from script / set script variables
#

initVars () {
  getVars

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
  eval "$(grep --color=never DEF_SAVE_DIR= ${TEST_SHELL} | head -1)"

   # file patterns for file existence test
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
#   if [[ ${fileCnt} -ne 0 ]]; then
#     printf "%s\n\n" "Please clean up previous output files. Tests can fail when they shouldn't if left in place."
#     find * -type f -depth 0 | grep --color=never -E "${saveAllFilePattern}"
#     printf "%s\n\n" "Bye."
#     exit
#   fi
# }
exitShell () {

  rm -f ${QRY_OUTPUT_FILE} 2>/dev/null

  existingFileCnt "${saveDir}"  "${saveAllFilePattern}" "" # should be no files. error if there is
  if [[ ${fileCnt} -ne 0 ]]; then
    printf "Please clean up %d previous output files. Tests can fail when they shouldn't if left in place.\n\n" ${fileCnt} 
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
  # params:
  # 1st - directory
  # 2nd - file prefix pattern
  # 3rd - file postfix pattern  
  echo "one='$1'; two='$2'; three='$3"
  fileCnt=$(printf '%0d' $(find "${1}" -type f -depth 1 | grep --color=never -E "${2}" | grep --color=never -E "${3}" | wc -l ) )
}

# output for screen and results file
printOutput () {
 #24. PASS  Exit Code: 0  Exp Code: 0 Input: STDIN Err Msg:   Desc: uid/pw tests - using -u and and -p arguments
 # PASS  Exit Code: 0  Exp Code: 0 Input: not providedErr Msg:   Desc: 

  printf "%s  Exit Code: %d  Exp Code: %d Input: %-6s Shell: %-4s Error: %0s Desc: %s\n" \
         "${msg}" "${actualRetCode}" "${expectedRetCode}" "${type}" "${shellToUse}" "${secondErrorMsg}" "${desc}"
  printf "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
         ${msg} ${actualRetCode} ${expectedRetCode} ${type} \
         ${errVarNames[@]:${actualRetCode}:1} ${errVarNames[@]:${expectedRetCode}:1}  \
         ${usePipe} "'${params}'" "'${secondErrorMsg}'" "'${shellToUse}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}
}

exitParamError() {
  printf '\n%s\n' "${errMsg}"
  printf "Call:\n"
  printf " runShell ${callingParams}\n\n"
  exitShell 1
}

setSaveFilePatterns() {
  # $1 = use default output file patterns or new. $2 = new file pattern
  setType="${1:---default}"
  if [[ ${setType} != "--new" && ${setType} != "--default" ]]; then
    printf "\n%s\n" "*** Internal error in function setSaveFilePatterns(). Invalid 1st parameter: ${setType}"
    while (( "$#" )); do printf "%s\n" " ${1} "; shift; done 
    exitShell 1
  fi

  if [[ ${setType} == "--new" ]]; then
    shift # need at least one argument for this to make sense
    if [[ $# -eq 0 ]]; then 
      printf "\n%s\n" "*** Internal error in function setSaveFilePatterns(). Missing patterns for ${setType}"
      exitShell 1
    fi

    while [ $# -gt 0 ]; do  # must come in pairs, e.g. --saveFilePrefix myTest
      paramName="${1/--/}"
      if [[ ${paramName} != "saveFilePrefix" || ${paramName} != "saveQryFilePattern" || ${paramName} != "saveResultsFilePattern" ]] && \
         [[ ${paramName} == "saveAllFilePattern" ]]; then
        printf printf "\n%s\n" "*** Internal error in function setSaveFilePatterns(). Invalid file parameter name ${paramName}"
        exitShell 1
      fi
      declare $paramName="${2}"  # set parameter value
      shift;shift
    done
  fi

  # fill in defaults for non-supplied parameters
  saveFilePrefix="${saveFilePrefix:-${OUTPUT_FILES_PREFIX}}"
  saveQryFilePattern="${saveQryFilePattern:-${QRY_FILE_POSTFIX}}"
  saveResultsFilePattern="${saveResultsFilePattern:-${RESULTS_FILE_POSTFIX}}"
  saveAllFilePattern="${saveQryFilePattern}|${saveResultsFilePattern}"
  echo "In setSaveFilePatterns"
  echo "saveFilePrefix=$saveFilePrefix; saveQryFilePattern=$saveQryFilePattern; saveResultsFilePattern=$saveResultsFilePattern; saveAllFilePattern=$saveAllFilePattern"
  read n
}

processParams () {
    # optional defaults
  expectedNbrFiles="${expectedNbrFiles:-0}"
  grepPattern="${grepPattern:-}"
  qry="${qry:-}"
  shellToUse="${shell:-zsh}"
  desc="${desc:-not provided}"  # description is optional
  params="${params:-}"
  externalFile="${externalFile:-}"

  # validate parameters
  if [[ ! -n ${expectedRetCode+x} || ! -n ${type+x} || ! -n ${qry+x} || \
        ! -n ${params+x} || ! -n ${expectedNbrFiles+x} || ! -n ${grepPattern+x} ]]; then
    errMsg="*** ERROR *** Missing required parameter(s) to function runShell."
    exitParamError
  elif [[ ${type} != "STDIN" && ${type} != "PIPE" && ${type} != "FILE" ]]; then
    errMsg="*** ERROR *** Invalid input type option: ${type}"
    exitParamError
  fi
   
  # process parameters
  if [[ ${params} == *"--saveDir"* ]]; then # --saveDir option specified w/o a directory, use default
    saveDir="${DEF_SAVE_DIR}"
  else # directory supplied, or use cwd if not.
    saveDir="${saveDir:-.}"
  fi

  if [[ ${params} == *"--saveAll"* ]]; then   # see what we're saving
    saveCypher="Y" 
    saveResults="Y"
  else
    [[ ${params} == *"--saveCypher"* ]] && saveCypher="Y" || saveCypher="N"
    [[ ${params} == *"--saveResults"* ]] && saveResults="Y" || saveResults="N"
  fi
  echo "saveCypher=$saveCypher; saveResults=$saveResultsFilePattern"; read n
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
  # Parameters are a param / value pair, e.g. --expectedNbrFiles 0 will set expectedNbrFiles=0
  #
  # PARAMETERS
  #   REQUIRED 
  #     --expectedRetCode integer
  #     --type "FILE" | "STDIN" | "PIPE"
  #     --qry cypher query string
  #     --params parameter string for call to repl-cypher-shell.sh
  #     --outPattern output file(s) pattern string
  #     --expectedNbrFiles integer for expected number of files
  #     --grepPattern file content grep pattern string
  #  
  #     OPTIONAL
  #       --shell string representing shell to use, ksh or zsh
  #       --desc description string for testing ouput 
runShell () {
  callingParams=${@}  # save params in case missing any

   # var values have -- removed, next param is value
  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      declare $paramName="${2}"  # set parameter value
    fi
    shift;shift
  done

  processParams

  isError="N"
  saveFileCnt=0
  secondErrorMsg="" # error not triggered by an invalid return code
  updateSuccessCnt="N" # assume we're going to have successfull tests

  # start test
  printf "%02d. " $(( ++runCnt ))  # screen output count

  if [[ ${type} == "STDIN" ]]; then
    eval ${shellToUse} "${TEST_SHELL}" -1 ${params} >"${QRY_OUTPUT_FILE}" 2>/dev/null <<EOF
    ${qry}
EOF
    actualRetCode=$?
  elif [[ ${type} == "PIPE" ]]; then
    echo ${qry} | eval ${shellToUse} "${TEST_SHELL}" ${params} >"${QRY_OUTPUT_FILE}" 
    actualRetCode=$?
  elif [[ ${type} == "FILE" ]]; then # expecting -f <filename> parameter
    ${shellToUse} ${TEST_SHELL} -1 ${params} >"${QRY_OUTPUT_FILE}"
    actualRetCode=$?
  fi 

  updateSuccessCnt="N"
  if [[ ${actualRetCode} -ne ${expectedRetCode} ]]; then
    printf -v secondErrorMsg "Expected exit code = %d, got %d"  ${expectedRetCode} ${actualRetCode}
  elif [[ ${expectedNbrFiles} -eq 0 ]]; then # no output files expected.
    existingFileCnt "${saveDir}" "${saveFilePrefix}" "${saveAllFilePattern}"
    if [[ ${fileCnt} -ne 0 ]]; then
      secondErrorMsg="Output files from shell exist that should not be there."
    else
      updateSuccessCnt="Y"
    fi
  elif [[ ! -z ${grepPattern} ]] && \
         [[ $(eval "${grepPattern} ${QRY_OUTPUT_FILE}") -eq 0 ]]; then # output of grep cmd should be > 0
      printf -v secondErrorMsg "%s" "grep command '${grepPattern}' on output file: ${QRY_OUTPUT_FILE} failed."
  else # expectedNbrFiles -ne 0 
    if [[ ${saveCypher} == "Y" ]]; then # file existence and file content existence tests
      existingFileCnt "${saveDir}" "${saveFilePrefix}" "${saveQryFilePattern}"
      saveFileCnt=$(( saveFileCnt+fileCnt ))
    fi
set -xv
    if [[ ${saveResults} == "Y" ]]; then # file existence and file content existence tests
      existingFileCnt "${saveDir}" "${saveFilePrefix}" "${saveResultsFilePattern}"
      saveFileCnt=$(( saveFileCnt+fileCnt ))
    fi
    if [[ ${saveFileCnt} -ne ${expectedNbrFiles} ]]; then
      printf -v secondErrorMsg "%s" "Expected ${expectedNbrFiles} output files, got ${fileCnt}"
    else
      updateSuccessCnt="Y"
    fi
  fi
set +xv
  if [[ -n ${externalFile} ]]; then
    if [[ ! -f ${externalFile} ]]; then # external file should be around
      printf -v secondErrorMsg "File ${externalFile} should exist but was deleted"
      updateSuccessCnt="N"
    else
      rm ${externalFile}
      updateSuccessCnt="Y"
    fi
  fi

  # cleanup and return
  rm ${QRY_OUTPUT_FILE} # remove transient transient output file
  if [[ "${updateSuccessCnt}" == "Y" ]]; then  # clean up qry and results files regardless
    for rmFile in $(find * -type f -depth 0 | grep --color=never -E "${saveAllFilePattern}" ) ; do
      rm ${rmFile}
    done 
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

# someday write expect scripts for interactive input
testsToRun () {

  runCnt=0
  successCnt=0
  errorCnt=0
  EXIT_ON_ERROR="Y"
   # first and only parameter must be a shell to run
  shellParam=${1:-zsh}
  setSaveFilePatterns --default # set save file patterns

  printf "Starting using ${shellParam}\n"
  # output file header
  printf  "      \tExit\tExp \tInput\n" > ${RESULTS_OUTPUT_FILE}
  printf  "Result\tCode\tCode\tType \tShell Exit Var\tExpected Shell Exit Var\tCalling Params\tError Msg\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}

  setSaveFilePatterns --new --saveResultsFilePattern "${MY_FILE_NAME}"  
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveResults ${MY_FILE_NAME} --saveDir"  \
           --outPattern "${saveResultsFilePattern}" \
           --expectedNbrFiles 1 \
           --desc "file tests - save with my defined file pattern."
exit
  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  printf "\n*** Initial db connect test ***\n" 

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --desc "tesing connection - using NEO4J_[USERNAME PASSWORD] environment variables."
  # EXIT_ON_ERROR="N"

  # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
  printf "\n*** Invalid paramater tests ***\n"  

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN"  \
           --params "--param"   \
           --desc "invalid param test - missing parameter argument value."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN"  \
           --params "--exitOnError noOptValExpected"  \
           --desc "invalid param test - flag argument only, no option expected."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN"  \
           --params "-Nogood"   \
           --desc  "invalid param test - bad passthru argument to cypher-shell."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN"  \
           --params "--file"   \
           --desc "invalid param test - missing file argument value."

  runShell --expectedRetCode ${RCODE_INVALID_FORMAT_STR} --type "STDIN"  \
           --params "--format notgood"  \
           --desc "invalid param test - invalid format string."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "STDIN"  \
           --params "--vi --editor 'atom'"  \
           --desc "invalid param test - conflicting editor args."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE"  \
           --params "--vi"   \
           --desc "invalid param test - incompatible editor argument and pipe input"

  touch ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE"  \
           --params "--file ${TMP_TEST_FILE}"  --outPattern "${QRY_OUTPUT_FILE}" \
           --expectedNbrFiles 0 --externalFile "${TMP_TEST_FILE}" \
           --desc "invalid param test - incompatible file input and pipe input."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE"  \
           --params "--exitOnError nogood"   \
           --desc "invalid param test - flag argument only, no option expected."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE"  \
           --params "-Nogood"   \
           --desc "invalid param test - bad pass thru argument to cypher-shell."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE"  \
           --params "--file"   \
           --desc "invalid param test - missing file argument value."

  runShell --expectedRetCode ${RCODE_INVALID_FORMAT_STR} --type "PIPE"  \
           --params "--format notgood"  \
           --desc  "invalid param test - invalid format string."

  runShell --expectedRetCode ${RCODE_INVALID_CMD_LINE_OPTS} --type "PIPE"  \
           --params "--vi --editor 'atom'"   \
           --desc "invalid param test - conflicting editor args."
  
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN"  \
           --params "--invalid param"   \
           --desc "invalid param test - invalid parameter argument value."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE"  \
           --params "--invalid param"   \
           --desc "invalid param test - invalid parameter argument value."
 
  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN"  \
           --params "--address n0h0st"   \
           --desc "invalid param test - bad pass-thru argument to cypher-shell."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE"  \
           --params "--address n0h0st"  \
           --desc "invalid param test - bad pass-thru argument to cypher-shell."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_NOT_FOUND} --type "STDIN"  \
           --params "--cypher-shell /a/bad/directory/xxx"  \
           --desc "invalid param test - explicitly set cypher-shell executable with --cypher-shell."

  # VALID PARAM TESTS
  printf "\n*** Valid paramater tests ***\n"  
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--cypher-shell ${CYPHER_SHELL}"   \
           --desc "param test - explicitly set cypher-shell executable with --cypher-shell."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN"  \
           --params "--version"   \
           --desc "param test - cypher-shell one-and-done version arg."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE"  \
           --params "--version"   \
           --desc "param test - cypher-shell one-and-done version arg."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--address localhost"  \
           --desc "param test - good thru argument to cypher-shell."

  # PASSWORD TESTS
  printf "\n*** uid / pw tests ***\n" 

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid} -p ${pw}"  \
           --desc "uid/pw tests - using -u and and -p arguments"

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid}"   \
           --desc "uid/pw tests - using -u and NEO4J_PASSWORD environment variable."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}"   \
           --desc "uid/pw tests - using -p and NEO4J_USERNAME environment variable."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}"   \
           --desc "uid/pw tests - using -p and NEO4J_USERNAME environment variable."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-p ${pw}xxx"  \
           --desc "uid/pw tests - using -u bad password"

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testSuccessQry}" \
           --params "-u ${uid}xxx"  \
           --desc "uid/pw tests - using -u bad username"
  
  unset NEO4J_USERNAME
  runShell --expectedRetCode ${RCODE_NO_USER_NAME} --type "PIPE" --qry "${testSuccessQry}" \
           --params ""   \
           --desc "uid/pw tests - pipe input with no env or -u usename defined"
  export NEO4J_USERNAME=${uid}

  unset NEO4J_PASSWORD
  runShell --expectedRetCode ${RCODE_NO_PASSWORD} --type "PIPE" --qry "${testSuccessQry}" \
           --params ""   \
           --desc "uid/pw tests - pipe input with no env or -p password defined"
  export NEO4J_PASSWORD=${pw}
  
  printf "\n*** Bad query test ***\n" 

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testFailQry}" \
           --params ""   \
           --desc "query tests - bad cypher query"

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "${testFailQry}" \
           --params ""   \
           --desc "query tests - bad cypher query piped input"

  # QUERY INPUT TESTING 
  printf "\n*** Query method and param and output tests ***\n" 

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--time"   \
           --grepPattern "${testTimeParamGrep}" \
           --desc "param test - test --time parameter output."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testParamQry}" \
           --params "${testParamParams}"   \
           --grepPattern "${testParamGrep}"  \
           --desc "param test - multiple arguments."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testParamQry}" \
           --params "${testParamParams}"   \
           --grepPattern "${testParamGrep}" \
           --desc  "param test - multiple arguments."

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN" --qry "" \
           --params ""  \
           --desc "query tests - empty cypher query"

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE"  \
           --params ""  \
           --desc "query tests - empty cypher query"

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN"  \
           --params "-t -c --quiet"   \
           --desc "query tests - empty cypher query with --quiet"

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE"  \
           --params "-t -c --quiet"   \
           --desc "query tests - empty cypher query with --quiet"
  
  runShell --expectedRetCode ${RCODE_MISSING_INPUT_FILE} --type "FILE"  \
           --params "--file NoFile22432.cypher"  \
           --desc "query / file tests - run external cypher file missing file"

  echo "${testSuccessQry}" > ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE"  \
           --params "--file ${TMP_TEST_FILE}" --externalFile "${TMP_TEST_FILE}"  \
           --desc "query / file tests - run external cypher file with valid query, validate output"

  echo "${TEST_SHELL}" > ${TMP_TEST_FILE}
  echo "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "FILE"  \
           --params "--file ${TMP_TEST_FILE}" --externalFile "${TMP_TEST_FILE}" \
           --desc "query / file tests - executing $ at beginning of text before cypher"

  # SAVE FILE TESTS
  printf "\n*** Save file test ***\n" 

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveAll"  \
           --outPattern "${saveAllFilePattern}" \
           --expectedNbrFiles 2  \
           --desc "file tests - save cypher query and text results files."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveCypher"    \
           --outPattern "${saveQryFilePattern}" \
           --expectedNbrFiles 1  \
           --desc "file tests - save cypher query file."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}"  \
           --params "--saveResults"  \
           --outPattern "${saveResultsFilePattern}" \
           --expectedNbrFiles 1  \
           --desc "file tests - save results file."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}"  \
           --params "--saveResults"  \
           --outPattern "${saveResultsFilePattern}" \
           --expectedNbrFiles 1  \
           --desc "file tests - save results file."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "STDIN" --qry "${testFailQry}"  \
           --params "--saveResults"  \
           --outPattern "${saveResultsFilePattern}" \
           --desc "file tests - bad query input save results file that will not exist."

  runShell --expectedRetCode ${RCODE_CYPHER_SHELL_ERROR} --type "PIPE" --qry "${testFailQry}"  \
           --params "--saveResults"  \
           --outPattern "${saveResultsFilePattern}" \
           --desc "file tests - bad query input save results file that will not exist."

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "STDIN"   \
           --params "--saveResults"  \
           --outPattern "${saveResultsFilePattern}" \
           --desc "file tests - empty input query input save results file that will not exist."

  runShell --expectedRetCode ${RCODE_EMPTY_INPUT} --type "PIPE"   \
           --params "--saveResults"   \
           --outPattern "${saveResultsFilePattern}" \
           --desc "file tests - empty input query input save results file that will not exist."

  # begin testing own output file names
  printf "\n*** Defined ouput file names ***\n"
  setSaveFilePatterns --new "${MY_FILE_NAME}"
  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveAll ${MY_FILE_NAME}"  \
           --outPattern "${saveAllFilePattern}" \
           --expectedNbrFiles 2 \
           --desc "file tests - save with my defined file pattern."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveCypher ${MY_FILE_NAME}"  \
           --outPattern "${saveQryFilePattern}" \
           --expectedNbrFiles 1 \
           --desc "file tests - save with my defined file pattern."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "STDIN" --qry "${testSuccessQry}" \
           --params "--saveResults ${MY_FILE_NAME}"  \
           --outPattern "${saveResultsFilePattern}" \
           --expectedNbrFiles 1 \
           --desc "file tests - save with my defined file pattern."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveAll ${MY_FILE_NAME}"  \
           --outPattern "${saveAllFilePattern}" \
           --expectedNbrFiles 2 \
           --desc "file tests - save with my defined file pattern."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveCypher ${MY_FILE_NAME}"  \
           --outPattern "${saveQryFilePattern}" \
           --expectedNbrFiles 1 \
           --desc "file tests - save with my defined file pattern."

  runShell --expectedRetCode ${RCODE_SUCCESS} --type "PIPE" --qry "${testSuccessQry}" \
           --params "--saveResults ${MY_FILE_NAME}"  \
           --outPattern "${saveResultsFilePattern}" \
           --expectedNbrFiles 1 \
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
  printf "\nFrom ${TEST_SHELL}:\n"
  printf "\n==== Error Code Vars =====\n\n"
  printf "%s\n" ${vars}
  printf "\n==========\n"
  printf "\n==== Directory Vars =====\n\n"
  printf "%s\n" "OUTPUT_FILES_PREFIX=${OUTPUT_FILES_PREFIX}" 
  printf "%s\n" "QRY_FILE_POSTFIX=${QRY_FILE_POSTFIX}"
  printf "%s\n" "RESULTS_FILE_POSTFIX=${RESULTS_FILE_POSTFIX}"
  printf "%s\n" "DEF_SAVE_DIR=${DEF_SAVE_DIR}" 
  printf "\n==========\n"

  exit 0
fi  

# ckForLeftoverOutputFiles 
# for shell in 'zsh' 'bash'; do
for shell in 'zsh' ; do
  testsToRun ${shell}
  [[ ${errorCnt} -ne 0 ]] && break || continue # error zsh means bash likely have errors
done
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
