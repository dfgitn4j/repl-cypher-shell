# set -e  # exit on error 
# test parameters in script.  Simpler than using expect
#
# Run with one parameter will return the variables used as exit codes in the 
# script being tested by grep'n for variables that begin with the pattern 
# RCODE in the function initVars (). 
#
# runTests () contains the calls to runShell for each individual test.
# 

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
  declare -a currentParams # array to hold parameters set for each run. reset in setEnvParams
  runCnt=0
  successCnt=0
  errorCnt=0

  exitOnError="Y"
  successMsg="PASS"
  errorMsg="FAIL"

   # file patterns for file existence test
  TMP_TEST_FILE=aFile_${RANDOM}${QRY_FILE_POSTFIX}
  QRY_OUTPUT_FILE="qryResults_${RANDOM}.tmpQryOutputFile"
  # RESULTS_OUTPUT_FILE="resultsTestRun-$(date '+%Y-%m-%d_%H:%M:%S')".txt
  RESULTS_OUTPUT_FILE="resultsTestRun.out"

  # cypher-shell output for keeping output on ERROR
  CYPHER_SHELL_OUTPUT="current-cypher-shell-output-${RANDOM}.tmp"
  CYPHER_SHELL_ERR_LOG="cypher-shell-error.log"
  cat /dev/null > ${CYPHER_SHELL_ERR_LOG}  # blank error log for run

    # vars specific to environment
  TEST_SHELL='../../repl-cypher-shell.sh'
  CYPHER_SHELL="$(which cypher-shell)" # change  if want to use a different cypher-shell
  PATH=${CYPHER_SHELL}:${PATH} # put testing cypher-shell first in PATH
  DEF_UID="neo4j"
  DEF_PW="admin"
  
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

# ckForLeftoverOutputFiles () {
#   existingFileCnt "${QRY_OUTPUT_FILE}" # should be no files. error if there is
#   if [[ ${fileCnt} -ne 0 ]]; then
#     printf "%s\n\n" "Please clean up previous output files. Tests can fail when they shouldn't if left in place."
#     find * -type f -depth 0 | grep --color=never -E "${saveAllPostfix}"
#     printf "%s\n\n" "Bye."
#     exit
#   fi
# }
exitShell () {
  # 1st param is return code, 0 if none specified
  rm ${QRY_OUTPUT_FILE} 2>/dev/null
  rm ${CYPHER_SHELL_OUTPUT} 2>/dev/null # remove cypher-shell output log

  existingFileCnt ""  "${saveAllPostfix}" # should be no files. error if there is
  if [[ ${fileCnt} -ne 0 ]]; then
    printf "Please clean up %d previous output files. Tests can fail when they shouldn't if left in place.\n\n" ${fileCnt} 
    find * -type f -depth 0 | grep  -E "${1}" 
    printf "%s\n\n" "Bye."
  fi
  [[ ! -s ${CYPHER_SHELL_ERR_LOG} ]] && rm ${CYPHER_SHELL_ERR_LOG}
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
  # remove cypher-shell output log
  rm ${CYPHER_SHELL_OUTPUT} 2>/dev/null 
  if [[ ${exitOnError} == "Y" ]]; then
    printf "%s\n\n" "Encountered a testing error and exitOnError = '${exitOnError}'." "Error output in file: ${CYPHER_SHELL_ERR_LOG}"
    exitShell 1
  fi 
}

exitInternalError () {
  msg="${1:-Internal script logic error somewhare}"
  printf '%s\n\n' "$msg"
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

# output for screen and results file
printOutput () {
  if [[ ${dryRun} == "Y" ]]; then
    if [[ ${runCnt} -eq 1 ]]; then
      printf  "Test\tExp\tInput\n" > ${RESULTS_OUTPUT_FILE}
      printf  "Nbr\tCode\tType \tExpected Shell Exit Var\tTesting Group\tCalling Params\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
    fi
    printf "%02d.\tExp Code: %d\tInput: %-6s\tShell: %-4s\tDesc: %s\n" \
           "${runCnt}" "${expectedRetCode}" "${inputType}" "${errVarNames[@]:${expectedRetCode}:1}" "${testGroup}" "'${params}'" "${shellToUse}" "${desc}" >> ${RESULTS_OUTPUT_FILE}
  else # runnning test print to screen and detail file
    if [[ ${runCnt} -eq 1 ]]; then
      printf  "      \tExit\tExp \tInput\n" > ${RESULTS_OUTPUT_FILE}
      printf  "Result\tCode\tCode\tType \tShell Exit Var\tExpected Shell Exit Var\tCalling Params\tTesting Group\tError Msg\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
    fi
    printf "%s  Exit Code: %d  Exp Code: %d Input: %-6s Shell: %-4s Error: %0s Desc: %s\n" \
           "${msg}" "${actualRetCode}" "${expectedRetCode}" "${inputType}" "${shellToUse}" "${secondErrorMsg}" "${desc}"
    printf "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
           ${msg} ${actualRetCode} ${expectedRetCode} ${inputType} \
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

  for envVar in "${currentParams[@]}"; do unset "${envVar}"; done
  currentParams=() # blank set parameter array

  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      currentParams+=("${paramName}") # add to array to erase next time through
      if [[ ${paramName} == *"="* ]]; then
        paramVal=${paramName#*=}
        paramName=${paramName%=*}
        eval "$paramName=\"${paramVal}\""  # set parameter value
      else
        eval "${paramName}='Y'"
      fi
    fi
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
  printf '%s\n\n' "${errStr}" >> ${CYPHER_SHELL_ERR_LOG}

  # remove inserted less control characters / extrainous blank lines
  grep --color=never -o "[[:print:][:space:]]*" ${CYPHER_SHELL_OUTPUT} | sed -e '/^$/d' >> ${CYPHER_SHELL_ERR_LOG}

  printf '\n' >> ${CYPHER_SHELL_ERR_LOG}
  eval "printf '=%.0s' {1..${#errStr}} >> ${CYPHER_SHELL_ERR_LOG}"
  printf '\n\n'  >> ${CYPHER_SHELL_ERR_LOG}
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
  # return 0 means continue, 1 means stop
  # if -n beginTestNbr || -n endTestNbr then
  #    if runCnt > endTestNbr; then
  #      return 1
  #    elif runcnt < startTestNbr 
  #      return 0 # 0 means continue loop
  #    fi 
  #   if # --printDesc
  #     print $desc
  #     return 0

  # else  # run tests

  # start test
  printf "%02d. " ${runCnt}  # screen output count

  if [[ ${inputType} == "STDIN" ]]; then
    eval ${shellToUse} "${TEST_SHELL}" -1 ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >${CYPHER_SHELL_OUTPUT} <<EOF
    ${qry}
EOF
    actualRetCode=$?
  elif [[ ${inputType} == "PIPE" ]]; then
    echo ${qry} | eval ${shellToUse} "${TEST_SHELL}" ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >${CYPHER_SHELL_OUTPUT}
    actualRetCode=$?
  elif [[ ${inputType} == "FILE" ]]; then # expecting -f <filename> parameter
    ${shellToUse} ${TEST_SHELL} -1 ${params} >"${QRY_OUTPUT_FILE}" 2>&1 >>${CYPHER_SHELL_OUTPUT}
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
    msg="${successMsg}"
    (( ++successCnt ))
    printOutput
  else # error
    msg="${errorMsg}" # for screen and runtime log output
    (( ++errorCnt ))
    addToErrorFile  # only log failed cypher-shell calls
    printOutput
    exitOnError 
  fi

  enterToContinue
}

testsToRun () {
  sep="-" # used as seperator after $testType in --desc flag for excel parsing

  # output file header
  printf  "      \tExit\tExp \tInput\n" > ${RESULTS_OUTPUT_FILE}
  printf  "Result\tCode\tCode\tType \tShell Exit Var\tExpected Shell Exit Var\tCalling Params\tError Msg\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}

  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  printf "\n*** Initial db connect test ***\n" 

  testType="connection testing ${sep}"
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --desc="${testType} using NEO4J_[USERNAME PASSWORD] environment variables."
exit
  # exitOnError="N"

  # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
  printf "\n*** Invalid paramater tests ***\n"  

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
           --params="--param"   \
           --testGroup="Invalid Parameter"
           --desc="invalid param test - missing parameter argument value."

  
  printf "\nFinished using %s. %s: %d  %s: %d\n" ${shellParam} ${successMsg} ${successCnt} ${errorMsg} ${errorCnt}
}

getCmdLineArgs () {
  validOpts="exitOnError beginTestNbr endTestNbr dryRun printVars help "  # need space at end
  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      echo "${validOpts}" | grep --quiet "$paramName "
      if [[ $? -ne 0 ]]; then
        printf "OPTIONS ERROR: Bad command line argument '${paramName}'. Valid values are ${validOpts}, passed in: ${@}\n"
        exit 1
      fi

      if [[ ${paramName} == "help" ]]; then
        cat << USAGE
        Valid command line options:

          --uid=<string>       Neo4j user login. Default is ${DEF_UID}.  
          --pw=<string>        Neo4j user password. Default is ${DEF_PW}.    
                   
          --exitOnError         Stop testing on error. Default is to keep running.
          --beginTestNbr=<nbr>  Begin at test number 'nbr'.
          --endTestNbr=<nbr>    End at test number 'nbr'.
            
          --returnToCont        Press <RETURN> to continue after each test.
          --dryRun              Print what tests would be run.
          --printVars           Print variables used as set in ${TEST_SHELL}. 
                                NOTE: The TEST_SHELL varible is set in the code. 

          --help                This message.

          NOTE: The variables uid, pw, exitOnError and returnToCont can all be 
          changed before each test is run
USAGE
        exit 0
      fi

      if [[ ${paramName} == *"="* ]]; then
        paramVal=${paramName#*=}
        paramName=${paramName%=*}
        eval "$paramName=\"${paramVal}\""  # set parameter value
      else # just setting flag
        eval "${paramName}='Y'"
      fi
    fi

    # validate command line args
    if [[ -n ${startNbr} && -n ${endNbr} ]] && [[ ${startNbr} -gt ${endNbr} ]]; then
      printf "OPTIONS ERROR: --startNbr=${startNbr} cannot be greater than --endNbr=${endNbr}"
      exit 1
    fi

    shift
  done

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
# for shell in 'zsh' 'bash'; do
for shell in 'zsh' ; do
  testsToRun ${shell}
  [[ ${errorCnt} -ne 0 ]] && break || continue # error zsh means bash likely have errors
done
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
