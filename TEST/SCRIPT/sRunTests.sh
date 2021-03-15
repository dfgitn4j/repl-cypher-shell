# set -e  # exit on error 
# test parameters in script.  Simpler than using expect
#
# --printVars command line option will return the variables used as exit codes in the 
# script being tested by grep'n for variables that begin with the pattern 
# RCODE in the function initVars (). 
#
# runTests () contains the calls to runShell for each individual test.
# 

help() {
        cat << USAGE

        Valid command line options:

          --uid=<string>       Neo4j user login. Default is ${DEF_UID}.  
          --pw=<string>        Neo4j user password. Default is ${DEF_PW}.    
                   
          --exitOnError        Stop testing on error. Default is to keep running.
          --startTestNbr=<nbr> Begin at test number 'nbr'. Default is 1.
          --endTestNbr=<nbr>   End at test number 'nbr'. Default is 1000.
            
          --returnToCont       Press <RETURN> to continue after each test.
          --dryRun             Print what tests would be run.  --printVars           
          --printVars          Print variables used as set in ${TEST_SHELL}. 
                               NOTE: The TEST_SHELL varible is set in the code. 

          --help               This message.

          NOTE: The variables uid, pw, exitOnError and returnToCont can all be 
          changed before each test is run.
USAGE
}

getCmdLineArgs () {
  validOpts="exitOnError startTestNbr endTestNbr dryRun printVars help "  # need space at end
  local errorMsg=""
  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"

      if [[ ${paramName} == *"="* ]]; then
        paramVal=${paramName#*=}
        paramName=${paramName%=*}
        eval "$paramName=\"${paramVal}\""  # set parameter value
      else # just setting flag
        eval "${paramName}='Y'"
      fi

      echo "${validOpts}" | grep --quiet "$paramName "
      if [[ $? -ne 0 ]]; then
        errorMsg="ERROR: Bad command line argument '${paramName}'. Valid values are ${validOpts}, passed in: ${@}"
      elif [[ ${paramName} == "help" ]]; then
        errorMsg="help"
      elif [[ -n ${startTestNbr} ]] && [[ ${startTestNbr} == 'Y' ||  ${startTestNbr} -lt 1 ]]; then
        errorMsg="ERROR For option: --startTestNbr '${1}'"
      elif [[ -n ${endTestNbr} ]] && [[ ${endTestNbr} == 'Y' ||  ${endTestNbr} -lt 1 ]]; then
        errorMsg="ERROR for option: --endTestNbr '${1}'"
      fi
    else
      errorMsg="ERROR: Invalid parameter '${1}'"
    fi

    # validate command line args
    if [[ ! -z ${errorMsg} ]]; then
      printf "%s\n" "${errorMsg}"
      help
      [[ ${errorMsg} == "help" ]] && exit 0 || exit 1
    fi
    shift
  done

  if [[ ${startTestNbr} -gt ${endTestNbr} ]]; then
    printf "ERROR for options: --startTestNbr=${startTestNbr} cannot be greater than --endTestNbr=${endTestNbr}"
    exit 1
  fi
   
  # set defaults for flag parameters
  exitOnError="${exitOnError:-N}"    # default is not to stop on error
  dryRun="${dryRun:-N}"
  printVars="${printVars:-N}"
}

extractTestingVars() {
  # turn var names into an array that the variables in tue above 
  # eval statement will reference
  vars=$(cat <<EOV
  $(cat ${TEST_SHELL} | sed -E -n 's/(^.*RCODE.*=[0-9]+)(.*$)/\1/p')
EOV
  )

  errVarNames=($(echo $vars | sed -E -e 's/=\-?[0-9]+//g'))
  eval $vars   # create ret code variables names with value

  # get output file patterns, assumes variable definition in script is the first pattern that matches
  eval "$(grep --color=never OUTPUT_FILES_PREFIX= ${TEST_SHELL} | head -1)" 
  eval "$(grep --color=never QRY_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never DEF_SAVE_DIR= ${TEST_SHELL} | head -1)"
}

# 
# initVars - get return code variables and values from script / set script variables
#
initVars () {

  # testing shell and default uid / pw. 
  TEST_SHELL='../../repl-cypher-shell.sh'  # shell to test!
  DEF_UID="neo4j"
  DEF_PW="admin"
  declare -a currentParams # array to hold parameters set for each run. reset in setEnvParams
  # Constants / defaults
  successMsg="PASS"  # output msgs
  errorMsg="FAIL"

   # file patterns for file existence test
  TMP_TEST_FILE=aFile_${RANDOM}${QRY_FILE_POSTFIX}
  QRY_OUTPUT_FILE="qryResults_${RANDOM}.tmpQryOutputFile"
  # RESULTS_OUTPUT_FILE="resultsTestRun-$(date '+%Y-%m-%d_%H:%M:%S')".txt
  RESULTS_OUTPUT_FILE="resultsTestRun.out"

  # cypher-shell output for keeping output on ERROR
  local _tmp=${RANDOM}
  TEST_SHELL_OUTPUT="current-cypher-shell-output-${_tmp}.tmp"
  TEST_SHELL_ERR_LOG="cypher-shell-error-${_tmp}.log"
  rm "${TEST_SHELL_ERR_LOG}" 2>/dev/null # should not exist, but just to be safe
 
  # testing queries and grep for success
  testSuccessQry="WITH 1 AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;"
  testFailQry="WITH 1 AS CYPHER_SUCCESS RETURN gibberish;"
  testParamQry='WITH $strParam AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;'
  testSuccessGrep="grep -c --color=never CYPHER_SUCCESS"

  # parameter tests
  testParamParams="--param 'x => 2' --param 'strParam => \"goodParam\"'"
  testParamGrep="grep -c --color=never goodParam"

  MY_FILE_NAME="myFileName" # for testing defining input name

  testTimeParamGrep="grep -c --color=never '${TIME_OUTPUT_HEADER}'"
}

exitShell () {
  # 1st param is return code, 0 if none specified
  rm ${QRY_OUTPUT_FILE} 2>/dev/null
  rm ${TEST_SHELL_OUTPUT} 2>/dev/null # remove cypher-shell output log

  existingFileCnt ""  "${saveAllPostfix}" # should be no files. error if there is
  if [[ ${fileCnt} -ne 0 ]]; then
    printf "Please clean up %d previous output files. Tests can fail when they shouldn't if left in place.\n\n" ${fileCnt} 
    find * -type f -depth 0 | grep  -E "${1}" 
    printf "%s\n\n" "Bye."
  fi
  rm ${TEST_SHELL_OUTPUT} 2>/dev/null  # remove cypher-shell output log
  exit ${1:-0}
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
    printf "%s\n" "Encountered a testing error and exitOnError = '${exitOnError}'." 
    [[ -f ${TEST_SHELL_ERR_LOG} ]] && printf "%s\n" "Error output in file: ${TEST_SHELL_ERR_LOG}"
    exitShell 1
  fi 
}

exitInternalError () {
  outputMsg="${1:-Internal script logic error somewhare}"
  printf '%s\n\n' "$outputMsg"
  exit 1
}

enterToContinue () {
  if [[ ${ENTER_TO_CONTINUE} == "Y" ]]; then
    printf 'Enter to continue.'
    read n
  fi
}

existingFileCnt () {
  # params:
  #   1st is the save file prefix pattern 
  #   2nd is the save file postfix pattern 
  # Error if not enough params because this function can be part of delete file logic
  [[ $# -ne 2 ]] && exitInternalError "Not enough parameters to function existingFileCnt. sent ${@}"
  fileCnt=$(printf '%0d' $(find "${saveDir}" -type f -depth 1 | grep --color=never -E "${1}" | grep --color=never -E "${2}" | wc -l ) )
}

printExtractedVars () {
  if [[ ${printVars} == "Y" ]]; then # can't print extracted vars until here
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
}

# output for screen and results file
printOutput () {
  # output to RESULTS_OUTPUT_FILE is tab delimited for use with column command
  if [[ ${dryRun} == "Y" ]]; then
    if [[ ${runCnt} -eq 1 ]]; then
      #printf  "Test Exp  Input\n" > ${RESULTS_OUTPUT_FILE}
      #printf  "Nbr  Code Type \tExpected Shell Exit Var\t\tCalling Params\tTesting Group\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
      printf  "Test\t            \tExp\tInput \tExpected\n" > ${RESULTS_OUTPUT_FILE}
      printf  "Nbr\tTesting Group\tCode\tType \tShell Exit Var\t\tCalling Params\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
    fi

    printf "%02d\t%s\t%d\t%s\t%s\t\t%s\t%s\t%s\t%s\n" \
           ${runCnt} "'${testGroup}'" ${expectedRetCode} ${inputType} \
           ${errVarNames[@]:${expectedRetCode}:1}  \
           "'${params}'"  "'${shellToUse}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}
  else # runnning test print to screen and detail file
    if [[ ${runCnt} -eq 1 ]]; then
      printf  "Test\tTest  \tExit\tExp \tInput\t              \tExpected\n" > ${RESULTS_OUTPUT_FILE}
      printf  "Nbr \tResult\tCode\tCode\tType \tShell Exit Var\tShell Exit Var\tCalling Params\tTesting Group\tError Msg\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
    fi
    printf "%s  Exit Code: %d  Exp Code: %d Input: %-6s Shell: %-4s Error: %0s Desc: %s\n" \
           "${outputMsg}" "${actualRetCode}" "${expectedRetCode}" "${inputType}" "${shellToUse}" "${secondErrorMsg}" "${desc}"
    printf "%02d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
           ${runCnt} ${outputMsg} ${actualRetCode} ${expectedRetCode} ${inputType} \
           ${errVarNames[@]:${actualRetCode}:1} ${errVarNames[@]:${expectedRetCode}:1}  \
           "'${params}'" "'${testGroup}'" "'${secondErrorMsg}'" "'${shellToUse}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}
  fi
}

# Handle file parameters:
 #  [-f | --file]                           File containing query.
 #  [-A | --saveAll]     [allFilesPrefix]   Save cypher query and output results 
 #                                          files with optional user set prefix.
 #  [-R | --saveResults] [resultFilePrefix] Save each results output in to a file 
 #                                          with optional user set prefix.
 #  [-S | --saveCypher]  [cypherFilePrefix] Save each query statement in a file
 #                                          with optional user set prefix.
 #  [-D | --saveDir]     [dirPath]          Directory to save files to.  Default 
 #                                          is ${DEF_SAVE_DIR} if dirPath is not provided. 
 # Scenarios are
 # 1. file containing query. should stay intaact
 # 2. save all / query / results files with:
 #  a. default prefix / postfix
 #  b. user defined prefix / postfix
 # 3. Save to default / user defined sub-directory
 #
setEnvParams () {
  # unsest previous environment vars
#set -xv
  for envVar in "${currentParams[@]}"; do unset "${envVar}"; done
  currentParams=() # blank set parameter array

  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      
      if [[ ${paramName} == *"="* ]]; then
        paramVal=${paramName#*=}
        paramName=${paramName%%=*}  # %% to remove longest string w/ =
        eval "$paramName=\"${paramVal}\""  # set parameter value
      else
        eval "${paramName}='Y'"
      fi
    fi
    currentParams+=("${paramName}") # add to array to erase next time through
    shift
  done

  # if not provided, provide defaults for parameters that need to be set 
    # set Neo4j uid / pw to a value if env vars not set. Easier testing if
    # done with environment variables. 
  uid="${uid:-${DEF_UID}}"
  pw="${pw:-${DEF_PW}}"
  NEO4J_USERNAME="${uid}"
  export NEO4J_USERNAME
  NEO4J_PASSWORD="${pw}"
  export NEO4J_PASSWORD
  
  exitOnError="${exitOnError:-N}"          # exit if runShell fails, "N" to continue
  returnToCont="${returnToCont:-N}"        # press enter to continue to next test
  expectedNbrFiles=${expectedNbrFiles:-0}  # expected number of output files
  shellToUse="${shellToUse:-zsh}"          # shell to use
  inputType="${inputType:-STDIN}"          # input types are STDIN, PIPE and FILE

  expectedRetCode="${expectedRetCode:-${RCODE_SUCCESS}}" # pulled from shell being tested

  desc="${desc:-not provided}"             # description is optional
  testGroup="${testGroup:-not provided}"   # testing group description

  # process parameters
  if [[ -z ${saveDir} ]]; then # $saveDir var exists, but it empty
    saveDir="."
  elif [[ ! -n ${saveDir} ]]; then # --saveDir option specified w/o a directory, use default
    saveDir="${DEF_SAVE_DIR}"
  fi # directory supplied

  if [[ ${saveAll} == "Y" ]]; then   # see what we're saving - vars show explicit intent 
    saveCypher="Y" 
    saveResults="Y"
  else
    [[ -n ${saveCypher} ]] && saveCypher="Y" || saveCypher="N"
    [[ -n ${saveResults} ]] && saveResults="Y" || saveResults="N"
  fi

  # fill in defaults for non-supplied parameters
  # used in grep to determine file existence 
  # save file tests can set invidual save[Qry|Results]FilePrefix 
  if [[ -n ${saveUserDefFilePrefix} ]]; then # user defined prefix, override query and results file prefix
    saveQryFilePrefix="${saveUserDefFilePrefix}"
    saveResultsFilePrefix="${saveUserDefFilePrefix}"
  else # use set value or defaults
    saveQryFilePrefix="${saveResultsFilePrefix:-${OUTPUT_FILES_PREFIX}}"
    saveResultsFilePrefix="${saveResultsFilePrefix:-${OUTPUT_FILES_PREFIX}}"
  fi 

  # all qry and results files have fixed postfix
  saveQryFilePostfix="${QRY_FILE_POSTFIX}}"  # no longer user defined
  saveResultsFilePostfix="${RESULTS_FILE_POSTFIX}}" # no longer user defined
  saveAllPostfix="${saveQryFilePostfix}|${saveResultsFilePostfix}" # used for cleanup file count
}

addToErrorFile () {
  # remove ctl characters from cypher output file
  printf -v errStr '==================== ERROR on run number: %02d ====================' ${runCnt}
  printf '%s\n\n' "${errStr}" >> ${TEST_SHELL_ERR_LOG}

  # remove inserted less control characters / extrainous blank lines
  grep --color=never -o "[[:print:][:space:]]*" ${TEST_SHELL_OUTPUT} | sed -e '/^$/d' >> ${TEST_SHELL_ERR_LOG}

  printf '\n' >> ${TEST_SHELL_ERR_LOG}
  eval "printf '=%.0s' {1..${#errStr}} >> ${TEST_SHELL_ERR_LOG}"  # '=' same length as header
  printf '\n\n'  >> ${TEST_SHELL_ERR_LOG}
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
  #   Typical parameters, with variable values or defaults set in function setEnvParams
  #     --expectedRetCode integer
  #     --inputType="FILE" | "STDIN" | "PIPE"
  #     --qry cypher query string
  #     --params parameter string for call to repl-cypher-shell.sh
  #     --outPattern output file(s) pattern string
  #     --grepPattern file content grep pattern string
  #     --shell string representing shell to use, ksh or zsh
  #     --desc description string for testing ouput 
  #   
  #   File saving / test parameters
  #     --expectedNbrFiles       integer for expected number of files, default is 0
  #     --saveFilePrefix         if not specified the default is ${OUTPUT_FILES_PREFIX}}"
  #     --saveQryFilePostfix     Cannot be user defined - set to ${QRY_FILE_POSTFIX}}" / changing was removed
  #     --saveResultsFilePostfix Cannot be user defined - set to ${RESULTS_FILE_POSTFIX}}" / changing was removed
  #
  #     --saveAll                Save results and query output
runShell () {

  setEnvParams "${@}"

  isError="N"
  saveFileCnt=0
  secondErrorMsg="" # error not triggered by an invalid return code
  updateSuccessCnt="N" # assume we're going to have successfull tests

  runCnt=${runCnt:-0}
  (( runCnt++ ))

  if [[ -n ${startTestNbr} || -n ${endTestNbr} ]] && [[ ${runCnt} -lt ${startTestNbr} || ${runCnt} -gt ${endTestNbr} ]]; then
    break
  elif [[ ${dryRun} == 'Y' ]]; then
    printOutput
  else # run test
    # start test
    printf "%02d. " ${runCnt}  # screen output count
  
    if [[ ${inputType} == "STDIN" ]]; then
      eval ${shellToUse} "${TEST_SHELL}" -1 ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >${TEST_SHELL_OUTPUT} <<EOF
      ${qry}
EOF
      actualRetCode=$?
    elif [[ ${inputType} == "PIPE" ]]; then
      echo ${qry} | eval ${shellToUse} "${TEST_SHELL}" ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >${TEST_SHELL_OUTPUT}
      actualRetCode=$?
    elif [[ ${inputType} == "FILE" ]]; then # expecting -f <filename> parameter
      ${shellToUse} ${TEST_SHELL} -1 ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >>${TEST_SHELL_OUTPUT}
      actualRetCode=$?
    fi 
  
    # if-then-else test pattern instead of collectively because errors can chain. 
    updateSuccessCnt="N"
    if [[ ${actualRetCode} -ne ${expectedRetCode} ]]; then
      printf -v secondErrorMsg "Expected exit code = %d, got %d"  ${expectedRetCode} ${actualRetCode}
    elif [[ ${expectedNbrFiles} -eq 0 ]]; then # no output files expected.
      existingFileCnt  "${saveFilePrefix}" "${saveAllPostfix}"
      if [[ ${fileCnt} -ne 0 ]]; then
        secondErrorMsg="Output files from shell exist that should not be there."
      else
        updateSuccessCnt="Y"
      fi
    elif [[ ! -z ${grepPattern} ]] && [[ $(eval "${grepPattern} ${QRY_OUTPUT_FILE}") -eq 0 ]]; then # output of grep cmd should be > 0
        printf -v secondErrorMsg "%s" "grep command '${grepPattern}' on output file: ${QRY_OUTPUT_FILE} failed."
    else
      if [[ ${saveCypher} == "Y" ]]; then # file existence and file content existence tests
        existingFileCnt "${saveFilePrefix}" "${saveQryFilePostfix}"
        saveFileCnt=$(( saveFileCnt+fileCnt ))
      fi
  
      if [[ ${saveResults} == "Y" ]]; then # file existence and file content existence tests
        existingFileCnt "${saveFilePrefix}" "${saveUserDefFilePrefix}"
        saveFileCnt=$(( saveFileCnt+fileCnt ))
      fi
      if [[ ${saveFileCnt} -ne ${expectedNbrFiles} ]]; then
        printf -v secondErrorMsg "%s" "Expected ${expectedNbrFiles} output files, got ${fileCnt}"
      else
        updateSuccessCnt="Y"
      fi
    fi
  
    if [[ -n ${externalFile} ]]; then
      if [[ ! -f ${externalFile} ]]; then # external file should be around
        printf -v secondErrorMsg "File ${externalFile} should exist but was deleted"
        updateSuccessCnt="N"
      else
        updateSuccessCnt="Y"
      fi
    fi
  
    # cleanup and return
    rm ${QRY_OUTPUT_FILE} # remove transient transient output file
    if [[ "${updateSuccessCnt}" == "Y" ]]; then  # clean up qry and results files regardless
      for rmFile in $(find "${saveDir}" -type f -depth 1 | grep --color=never -E "${saveAllPostfix}" ) ; do
        rm ${rmFile}
      done 
      outputMsg="${successMsg}"
      (( ++successCnt ))
      printOutput
    else # error
      outputMsg="${errorMsg}" # for screen and runtime log output
      (( ++errorCnt ))
      addToErrorFile  # create ouput error file from shell ouput
      printOutput
      exitOnError 
    fi
  
    enterToContinue
  fi # if ! dryRun
}

testsToRun () {
  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  testGroup="initial connection testing"
  oldExitOnError=${exitOnError}  # exitOnError can be set via command line, but need to test if db is online
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --testGroup="${testGroup}" --desc="using NEO4J_[USERNAME PASSWORD] environment variables." \
           --exitOnError            
  exitOnError="${oldExitOnError}"  # put back original exitOnError if there is one    

  while true; do

    # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
    testGroup="Invalid parameter tests"
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN" \
             --params="--param" \
             --desc="missing cypher-shell parameter argument value."

    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--exitOnError noOptValExpected"  \
             --desc="flag argument only, no option expected."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="-Nogood" \
             --desc="bad passthru argument to cypher-shell."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--file" \
             --desc="missing file argument value."
  
    runShell --expectedRetCode=${RCODE_INVALID_FORMAT_STR} --inputType="STDIN"  \
             --params="--format notgood" \
             --desc="invalid format string."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--vi --editor 'atom'"  \
             --desc="conflicting editor args."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--vi"   \
             --desc="incompatible editor argument and pipe input"
  
    touch ${TMP_TEST_FILE}
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--file=${TMP_TEST_FILE}"  \
             --expectedNbrFiles=0 --externalFile="${TMP_TEST_FILE}" \
             --desc="incompatible file input and pipe input."
    
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
             --params="-Nogood"   \
             --desc="bad pass thru argument to cypher-shell."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--file"   \
             --desc="missing file argument value."
  
    runShell --expectedRetCode=${RCODE_INVALID_FORMAT_STR} --inputType="PIPE"  \
             --params="--format notgood"  \
             --desc="invalid format string."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--vi --editor 'atom'"   \
             --desc="conflicting editor args."
    
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="--invalid param"   \
             --desc="invalid parameter argument value."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
             --params="--invalid param"   \
             --desc="invalid parameter argument value."
   
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="--address n0h0st"   \
             --desc="bad pass-thru argument to cypher-shell."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
             --params="--address n0h0st"  \
             --desc="bad pass-thru argument to cypher-shell."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_NOT_FOUND} --inputType="STDIN"  \
             --params="--cypher-shell /a/bad/directory/xxx"  \
             --desc="explicitly set cypher-shell executable with --cypher-shell."

    break # made it to end, exit loop
  done


}


#
# MAIN
#
setopt SH_WORD_SPLIT >/dev/null 2>&1

trap interruptShell SIGINT

getCmdLineArgs "${@}"
initVars
extractTestingVars  # get required variables from $TEST_SHELL being tested

printExtractedVars  # print extracted vars and exit if --printVars cmd line option

# ckForLeftoverOutputFiles 
# for shellToUse in 'zsh' 'bash'; do
for shellToUse in 'zsh'; do
  runCnt=0        # nbr of tests run
  successCnt=0    # testing success count
  errorCnt=0      # testing error count
  printf "\n+++ Starting using %s\n" "${shellToUse}"
  testsToRun 
  if [[ ${dryRun} == 'Y' ]]; then
    cat ${RESULTS_OUTPUT_FILE} | tr '\t' '|' | column -t -s '|'
  else
    printf "+++ Finished using %s. %s: %d  %s: %d\n" ${shellToUse} ${successMsg} ${successCnt} ${errorMsg} ${errorCnt}
    [[ ${errorCnt} -gt 0 ]]  && printf "Look in ${TEST_SHELL_ERR_LOG} for cypher-shell errors\n"
  fi

  [[ ${errorCnt} -ne 0 || ${dryRun} == 'Y' ]] && break || continue # 1st shell fails then 2nd likely will also
done
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
