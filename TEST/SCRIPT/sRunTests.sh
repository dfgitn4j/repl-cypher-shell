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
   --uid=<string>       Neo4j user login. Default is ${DEF_UID}. Stays 
                        enabled unless reset.            
   --pw=<string>        Neo4j user password. Default is ${DEF_PW}. Stays 
                        enabled unless reset.              
   
   --testErrorExit      Stop testing on error. Default is 'N'. Will stay set 
                        across tests until changed.      
   --returnToCont       Press <RETURN> to continue after each test. Default 
                        is 'N'. Will stay set across tests until changed.  
   
   --dryRun             Print what tests would be run. 
   --startTestNbr=<nbr> Begin at test number 'nbr'. Default is ${DEF_START_TEST_NBR}.
   --endTestNbr=<nbr>   End at test number 'nbr'. Default is ${DEF_END_TEST_NBR}.
        
   --printVars          Print variables used as set in TEST_SHELL=${TEST_SHELL}. 
                        NOTE: The TEST_SHELL varible is set in the code. 

   --help               This message.

   NOTE: 
    The variables uid, pw, testErrorExit, returnToCont and testGroup can all be changed
    before each test is run. Once set these variables they stay set. 

    --testErrorExit, --returnToCont 
      - Defaults are set in function setDefaults().
      - using flag sets value to "Y", or can be explicitly set using = pattern, e.g.
          --testErrorExit="N"

    --uid, --pw
      - If defined then the environment variables NEO4J_USERNAME and NEO4J_PASSWORD
        are also set.  This avoids having to provide a uid and pw parameter to every 
        testing call.
      - If not defined, then the environment variables are used. 
      - If the environment variables are not set then the script variable values 
        DEF_UID and DEF_PW are used and are set in function setDefaults()
      - Values stay set until reset. 
USAGE
}

getCmdLineArgs () {
  validOpts="testErrorExit startTestNbr endTestNbr uid pw returnToCont dryRun printVars help "  # need space at end
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
      
      if ! echo "${validOpts}" | grep --quiet "$paramName " ; then  # ck for invalid parameter name
        errorMsg="ERROR: Bad command line argument '${paramName}'. Valid values are ${validOpts}, passed in: ${@}"
      elif [[ ${paramName} == "printVars" ]]; then # print extracted vars and exit if --printVars cmd line option
        printExtractedVars  
        exitShell 0 # printing extracted vars, no need to continue on
      elif [[ ${paramName} == "help" ]]; then
        errorMsg="help"
      elif [[ -n ${startTestNbr} ]] && [[ ${startTestNbr} == 'Y' ||  ${startTestNbr} -lt 1 ]]; then
        errorMsg="ERROR For option: --startTestNbr '${1}'"
      elif [[ -n ${endTestNbr} ]] && [[ ${endTestNbr} == 'Y' ||  ${endTestNbr} -lt 1 ]]; then
        errorMsg="ERROR for option: --endTestNbr '${1}'"
      fi
    else
      errorMsg="ERROR: Invalid command line parameter '${1}'"
    fi

    # validate command line args
    if [[ -n ${errorMsg} ]]; then
      printf "%s\n" "${errorMsg}"
      help
      [[ ${errorMsg} == "help" ]] && exit 0 || exit 1
    fi
    shift
  done

  # test number to start and end at
  if [[ -n ${startTestNbr} && -n ${endTestNbr} ]] && [[ ${startTestNbr} -gt ${endTestNbr} ]]; then
    printf '%s\n' "ERROR for options: --startTestNbr=${startTestNbr} cannot be greater than --endTestNbr=${endTestNbr}"
    exit 1
  fi
  
  # set defaults for flag parameters
  dryRun="${dryRun:-N}"              # show what would be run with step #
  returnToCont="${returnToCont:-N}"  # press enter to continue to next test

  # use environment variable for uid and pw if set and not overridden, ow use defaults.
  # setting env vars avoids having to pass uid and pw to script every time.
  if [[ -n ${uid} ]]; then  # uid defined, override environment variable
    export NEO4J_USERNAME="${uid}"
  else 
    if [[ -n ${NEO4J_USERNAME} ]]; then # enviroment variable set
      uid="${NEO4J_USERNAME}"
    else
      uid="${DEF_UID}"
      export NEO4J_USERNAME="${DEF_UID}"
    fi
  fi
  
  if [[ -n ${pw} ]]; then  # pw defined, override environment variable
    export NEO4J_PASSWORD="${pw}"
  else 
    if [[ -n ${NEO4J_PASSWORD} ]]; then # enviroment variable set
      pw="${NEO4J_PASSWORD}"
    else
      pw="${DEF_UID}"
      export NEO4J_PASSWORD="${DEF_UID}"
    fi
  fi
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
  eval "$(grep --color=never DEF_QRY_FILE_EXTSN= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never DEF_RESULTS_FILE_EXTSN= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never DEF_SAVE_DIR= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never DEF_OUTPUT_PREFIX= ${TEST_SHELL} | head -1)"
}

initVars () {
  extractTestingVars  # get required variables from $TEST_SHELL being tested

  declare -a currentParams # array to hold parameters set for each run. reset in setEnvParams
  # Constants / defaults
  successMsg="PASS"  # output msgs
  errorMsg="FAIL"

  # file patterns for file existence test
  TMP_TEST_FILE=aFile_${RANDOM}${DEF_QRY_FILE_EXTSN}
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

  testSuccessGrep="grep -c --color=never CYPHER_SUCCESS"

  # parameter tests
  # \" to escape double quotes. will have to manipulate again in setEnv to dodge expansion
  testParamParams="--param 'x => 2' --param 'strParam => \""goodParamVal"\"'"
  testParamGrep="grep -c --color=never goodParamVal"
  # testParamGrep="grep -c --color=never x"
  testParamQry='WITH \$strParam AS CYPHER_SUCCESS RETURN CYPHER_SUCCESS ;'

  MY_FILE_NAME="myFileName" # for testing defining input name

  testTimeParamGrep="grep -c --color=never '${TIME_OUTPUT_HEADER}'"
}

printExtractedVars () {
  printf "\nFrom ${TEST_SHELL}:\n"
  printf "\n======== Error Code Vars =======\n\n"
  printf "%s\n" ${vars}
  printf "\n=================================\n"
  printf "\n==== Directory / File Vars ======\n\n"
  printf "%s\n" "OUTPUT_FILES_PREFIX=${OUTPUT_FILES_PREFIX}" 
  printf "%s\n" "DEF_QRY_FILE_EXTSN=${DEF_QRY_FILE_EXTSN}"
  printf "%s\n" "DEF_RESULTS_FILE_EXTSN=${DEF_RESULTS_FILE_EXTSN}"
  printf "%s\n" "DEF_SAVE_DIR=${DEF_SAVE_DIR}" 
  printf "\n=================================\n"
  exit 0
}

exitShell () {
  # 1"st param is return code, 0 if none specified
  # rm per run query, tmp input qry and output files
  rm "${QRY_OUTPUT_FILE}" "${TMP_TEST_FILE}" "${TEST_SHELL_OUTPUT}" 2>/dev/null

  [[ -f ${TEST_SHELL_ERR_LOG} ]] && printf "%s\n" "Error output in file: ${TEST_SHELL_ERR_LOG}"

  existingFileCnt ""  "${saveAllPostfix}" # should be no files. error if there is
  if [[ ${fileCnt} -ne 0 ]]; then
    printf "Please clean up %d previous output files. Tests can fail when they shouldn't if left in place.\n\n" ${fileCnt} 
    find * -type f -depth 0 | grep  -E "${1}" 
    printf "%s\n\n" "Bye."
  fi
  # rm ${TEST_SHELL_OUTPUT} 2>/dev/null  # remove cypher-shell output log
  exit ${1:-0}
}

interruptShell () {
  printf "\nCtl-C pressed. Bye.\n\n"
  exec <&- # close stdin
  exitShell 1
}

doExitOnError () {
  if [[ ${testErrorExit} == "Y" ]]; then
    printf "%s\n" "Encountered a testing error and testErrorExit = '${testErrorExit}'." 
    exitShell 1
  fi 
}

exitInternalError () {
  outputMsg="${1:-Internal script logic error somewhare}"
  printf '%s\n\n' "$outputMsg"
  exit 1
}

finalOutput () {
  if [[ ${dryRun} == 'Y' ]]; then  # output formated dry run
    cat ${RESULTS_OUTPUT_FILE} | tr '\t' '|' | column -t -s '|'
  else
    printf "+++ Finished using %s. %s: %d  %s: %d\n" "${shellToUse}" "${successMsg}" "${successCnt}" "${errorMsg}" "${errorCnt}"
    [[ ${errorCnt} -gt 0 && ! -s ${TEST_SHELL_ERR_LOG} ]]  && printf "Look in ${TEST_SHELL_ERR_LOG} for cypher-shell errors\n"
  fi
  exitShell 0
}

doContinue () {
  if [[ -n ${endTestNbr} && ${runCnt} -eq ${endTestNbr} ]]; then # ran last test
    finalOutput
  elif [[ ${returnToCont} == "Y" ]]; then
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
  # output to RESULTS_OUTPUT_FILE is tab delimited for use with column command
  if [[ ${dryRun} == "Y" ]]; then
    if [[ ${runCnt} -eq ${startTestNbr}  ]]; then
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
    if [[ ${runCnt} -eq ${startTestNbr} ]]; then
      printf  "Test\tTest  \tExit\tExp \tInput\t              \tExpected\n" > ${RESULTS_OUTPUT_FILE}
      printf  "Nbr \tResult\tCode\tCode\tType \tShell Exit Var\tShell Exit Var\tCalling Params\tTesting Group\tError Msg\tShell\tDescription\n" >> ${RESULTS_OUTPUT_FILE}
    fi
    # truncating $testGroup string to 20 characters
    printf "%s  Grp: %.20s  Exit Code: %d  Exp Code: %d Input: %-6s Shell: %-4s Desc: %s" \
           "${outputMsg}" "${testGroup}                    " "${actualRetCode}" "${expectedRetCode}" "${inputType}" "${shellToUse}"  "${desc}"
    [[ -n ${secondErrorMsg} ]] && printf "%s\n" " **ERROR: ${secondErrorMsg}" || printf "\n"

    printf "%02d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
           ${runCnt} ${outputMsg} ${actualRetCode} ${expectedRetCode} ${inputType} \
           ${errVarNames[@]:${actualRetCode}:1} ${errVarNames[@]:${expectedRetCode}:1}  \
           "'${params}'" "'${testGroup}'" "'${secondErrorMsg}'" "'${shellToUse}'" "'${desc}'" >> ${RESULTS_OUTPUT_FILE}
  fi
}



addToErrorFile () {
  # remove ctl characters from cypher output 
  [[ ! -s ${TEST_SHELL_OUTPUT} ]] && return  # nothing to print
  printf -v errStr '==================== ERROR on run number: %02d ====================' "${runCnt}"
  printf '%s\n\n' "${errStr}" >> "${TEST_SHELL_ERR_LOG}"

  # remove inserted less control characters / extrainous blank lines
  grep --color=never -o "[[:print:][:space:]]*" ${TEST_SHELL_OUTPUT} | sed -e '/^$/d' >> ${TEST_SHELL_ERR_LOG}

  printf '\n' >> ${TEST_SHELL_ERR_LOG}
  eval "printf '=%.0s' {1..${#errStr}} >> ${TEST_SHELL_ERR_LOG}"  # '=' same length as header
  printf '\n\n'  >> ${TEST_SHELL_ERR_LOG}
}

# Handle file parameters:
 # [-f | --file]     <filename>           File containing query.
 # 
 # [-A | --saveAll]     [all_file_name]     Save cypher query and output results 
 #                                          files with optional user set prefix.
 # [-R | --saveResults] [results_file_name] Save each results output in to a file 
 #                                          with optional user set prefix.
 # [-S | --saveCypher]  [cypher_file_name]  Save each query statement in a file
 #                                          with optional user set prefix.
 # [-D | --saveDir]     [save_dir]          Path to directory to save files to.  Default 
 #                                          is ${DEF_SAVE_DIR} if dirPath is not provided. 
 # Scenarios are
 # 1. file containing query. should stay intaact
 # 2. save all / query / results files with:
 #  a. default prefix / postfix
 #  b. user defined prefix / postfix
 # 3. Save to default / user defined sub-directory
 #
setEnvParams () {
  # unsest previous environment vars unless they persist between runTest calls
  persistParams="testErrorExit returnToCont testGroup allFilesPrefix resultFilePrefix cypherFilePrefix saveDir shellToUse "
  for envVar in "${currentParams[@]}"; do 
    if ! echo "$persistParams" | grep --quiet "${envVar}"; then
      unset "${envVar}"
    fi
  done
  currentParams=() # blank set parameter array

  while [ $# -gt 0 ]; do
    if [[ ${1} == *"--"* ]]; then
      paramName="${1/--/}"
      paramName="$(echo $paramName | sed -e 's/"/\\"/g')" # escape double quotes!
      if [[ ${paramName} == *"="* ]]; then
        paramVal="${paramName#*=}"
        paramName="${paramName%%=*}" # %% to remove longest string w/ =
        eval "$paramName=\"${paramVal}\""  # set parameter value
      else
        eval "${paramName}='Y'"
      fi
    else 
      printf "%s %0d.\n" "ERROR: Invalid runtime testing option '${1}' on test nbr: " $(( ++runCnt ))
      exit 1
    fi

    currentParams+=("${paramName}") # add to array to erase next time through
    shift
  done

  # if not provided, provide defaults for parameters that need to be set 
  expectedNbrFiles=${expectedNbrFiles:-0}  # expected number of output files
  shellToUse="${shellToUse:-zsh}"          # shell to use
  inputType="${inputType:-STDIN}"          # input types are STDIN, PIPE and FILE

  expectedRetCode="${expectedRetCode:-${RCODE_SUCCESS}}" # pulled from shell being tested

  desc="${desc:-not provided}"             # description is optional
  testGroup="${testGroup:-not provided}"   # testing group description

  if [[ -n ${saveDir} ]]; then # --saveDir option 
    if [[ -z ${dirPath} ]]; then # no directory path option for --saveDir set
      dirPath="${DEF_SAVE_DIR}"
    fi
  else # specified w/o a directory, use current
    dirPath="."
  fi 

  if [[ -n ${saveAll} ]]; then   # see what we're saving - vars show explicit intent 
    saveCypher="Y" 
    saveResults="Y"
    # if [[ -z ${all_file_name} ]]; then # no file name provided, use default
  else
    [[ ${params} == *"saveCypher"* ]] && saveCypher="Y" || saveCypher="N"
    [[ ${params} == *"saveResults"* ]] && saveResults="Y" || saveResults="N"
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
  saveQryFilePostfix="${DEF_QRY_FILE_EXTSN}"  # no longer user defined
  saveResultsFilePostfix="${DEF_RESULTS_FILE_EXTSN}" # no longer user defined
  saveAllPostfix="${saveQryFilePrefix}*${saveQryFilePostfix}|${saveQryFilePrefix}*${saveResultsFilePostfix}" # used for cleanup file count
}
Nx25j6pq7axTnS#pfWrAZDFb$d
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
  #     --saveFilePrefix         if not specified the default is ${OUTPUT_FILES_PREFIX}"
  #     --saveQryFilePostfix     Cannot be user defined - set to ${DEF_QRY_FILE_EXTSN}" / changing was removed
  #     --saveResultsFilePostfix Cannot be user defined - set to ${DEF_RESULTS_FILE_EXTSN}" / changing was removed
  #
  #     --saveAll                Save results and query output
runShell () {
  saveFileCnt=0
  secondErrorMsg="" # error not triggered by an invalid return code
  updateSuccessCnt="N" # assume we're going to have successfull tests

  runCnt=${runCnt:-0}
  (( runCnt++ ))

  # print screen output run number parameters
  if [[ ${runCnt} -eq 1 ]] && [[ -n ${startTestNbr} || -n ${endTestNbr} ]]; then
    [[ -n ${startTestNbr} ]] && printf "%s" "Starting test at run number: ${startTestNbr}"
    [[ -n ${endTestNbr} ]] && printf "%s" " and ending test at run number: ${endTestNbr}"
    [[ ${runCnt} -eq 1 ]] && printf "\n"
  fi

  if [[ -n ${startTestNbr} && ${runCnt} -lt ${startTestNbr} ]]; then
    return
  else
    setEnvParams "${@}"
    if [[ ${dryRun} == 'Y' ]]; then
      printOutput
    else # run test
      printf "%02d. " "${runCnt}"  # screen output count
  
      if [[ ${inputType} == "STDIN" ]]; then
        # need the -1 "run once" flag to avoid input loop. makes life much easier
        eval "${shellToUse}" "${TEST_SHELL}" -1 "${params}" >"${QRY_OUTPUT_FILE}"  2>&1 >"${TEST_SHELL_OUTPUT}"<<EOF
        ${qry}
EOF
        actualRetCode=$?
      elif [[ ${inputType} == "PIPE" ]]; then
        echo "${qry}" | eval "${shellToUse}" "${TEST_SHELL}" "${params}" >"${QRY_OUTPUT_FILE}" 2>&1 >"${TEST_SHELL_OUTPUT}"
        actualRetCode=$?
      elif [[ ${inputType} == "FILE" ]]; then # expecting -f <filename> parameter
        eval ${shellToUse} "${TEST_SHELL}" -1 "${params}" >"${QRY_OUTPUT_FILE}" 2>&1 >>"${TEST_SHELL_OUTPUT}"
        actualRetCode=$?
      fi 
  
      # if-then-else test pattern instead of collectively because errors can chain. 
      updateSuccessCnt="N"
      if [[ ${actualRetCode} -ne ${expectedRetCode} ]]; then
        printf -v secondErrorMsg "Expected exit code = %d, got %d"  "${expectedRetCode}" "${actualRetCode}"
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
        if [[ -n ${externalFile} ]]; then
          if [[ ! -f ${externalFile} ]]; then # external file should be around
            printf '%s' -v secondErrorMsg "File ${externalFile} should exist but was deleted"
            updateSuccessCnt="N"
          else
            updateSuccessCnt="Y"
          fi
        fi
      fi
    fi
  
    # cleanup 
    if [[ "${updateSuccessCnt}" == "Y" ]]; then  # clean up qry and results files regardless
      for rmFile in $(find "${saveDir}" -type f -depth 1 | grep --color=never -E "${saveAllPostfix}" ) ; do
        rm ${rmFile}
      done 
      outputMsg="${successMsg}"
      (( ++successCnt ))
      printOutput
      rm ${QRY_OUTPUT_FILE} # remove transient transient output file
    else # error
      outputMsg="${errorMsg}" # for screen and runtime log output
      (( ++errorCnt ))
      addToErrorFile  # create ouput error file from shell ouput
      printOutput
      doExitOnError 
    fi
  
    doContinue
  fi # if runCnt < startTestNbr
}

testsToRun () {
  while true; do

    # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
    testGroup="initial connection"
    oldExitOnError=${testErrorExit}  # testErrorExit can be set via command line, but need to test if db is online
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --testGroup="${testGroup}" --desc="using NEO4J_[USERNAME PASSWORD] environment variables." \
             --testErrorExit            
    testErrorExit="${oldExitOnError}"  # put back original testErrorExit if there is one    

    # INVALID PARAMETER TESTS -  none of these test should ever get to executing a query
    testGroup="invalid parameters"
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN" \
             --params="--param" \
             --desc="missing cypher-shell parameter argument value."

    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--exitOnError noOptValExpected"  \
             --desc="flag argument only, no option expected."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="-Nogood" \
             --desc="bad passthru argument to cypher-shell."

    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="--invalid param"   \
             --desc="invalid parameter argument value."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--file" \
             --desc="missing file argument value."
  
    runShell --expectedRetCode=${RCODE_INVALID_FORMAT_STR} --inputType="STDIN"  \
             --params="--format notgood" \
             --desc="invalid format string."
  
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
             --params="--vi --editor 'atom'"  \
             --desc="conflicting editor args."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_NOT_FOUND} --inputType="STDIN"  \
             --params="--cypher-shell /a/bad/directory/xxx"  \
             --desc="explicit bad cypher-shell executable with --cypher-shell."

    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--vi"   \
             --desc="incompatible editor argument and pipe input"

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
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
             --params="--invalid param"   \
             --desc="invalid parameter argument value."
   
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
             --params="--address n0h0st"   \
             --desc="bad pass-thru argument to cypher-shell."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
             --params="--address n0h0st"  \
             --desc="bad pass-thru argument to cypher-shell."

    touch ${TMP_TEST_FILE}
    runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
             --params="--file ${TMP_TEST_FILE}"  \
             --expectedNbrFiles=0 --externalFile="${TMP_TEST_FILE}" \
             --desc="incompatible file input and pipe input."
    rm ${TMP_TEST_FILE}

    testGroup="valid parameters"
    CYPHER_SHELL="$(which cypher-shell)" # change  if want to use a different cypher-shell  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="--cypher-shell ${CYPHER_SHELL}"   \
             --desc="explicitly set cypher-shell executable with --cypher-shell."
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN"  \
             --params="--version"   \
             --desc="cypher-shell one-and-done version arg."
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="PIPE"  \
             --params="--version"   \
             --desc="param test - cypher-shell one-and-done version arg."
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="PIPE" --qry="${testSuccessQry}" \
             --params="--address localhost"  \
             --desc="connect localhost."

    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testParamQry}" \
             --params="${testParamParams}"  \
             --grepPattern="${testParamGrep}" \
             --desc="multiple valid args."

    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="PIPE" --qry="${testParamQry}" \
           --params="${testParamParams}"  \
           --grepPattern="${testParamGrep}" \
           --desc="multiple valid args."
  
    testGroup="uid / pwd"
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-u ${uid} -p ${pw}"  \
             --desc="using -u and and -p arguments"
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-u ${uid}"   \
             --desc="using -u and NEO4J_PASSWORD environment variable."
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-p ${pw}"   \
             --desc="using -p and NEO4J_USERNAME environment variable."
  
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-p ${pw}"   \
             --desc="using -p and NEO4J_USERNAME environment variable."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-p ${pw}xxx"  \
             --desc="using -u bad password"
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="-u ${uid}xxx"  \
             --desc="using -u bad username"
    
    unset NEO4J_USERNAME
    runShell --expectedRetCode=${RCODE_NO_USER_NAME} --inputType="PIPE" --qry="${testSuccessQry}" \
             --params=""   \
             --desc="pipe input with no env or -u usename defined"
    export NEO4J_USERNAME=${uid}
  
    unset NEO4J_PASSWORD
    runShell --expectedRetCode=${RCODE_NO_PASSWORD} --inputType="PIPE" --qry="${testSuccessQry}" \
             --params=""   \
             --desc="pipe input with no env or -p password defined"
    export NEO4J_PASSWORD=${pw}

    testGroup="bad query" 
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testFailQry}" \
             --params=""   \
             --desc="bad cypher query"
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE" --qry="${testFailQry}" \
             --params=""  \
             --desc="bad cypher query piped input"

    testGroup="query scenarios" 
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
             --params="--time"   \
             --grepPattern="${testTimeParamGrep}" \
             --desc="--time parameter output."
  
    runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="STDIN" --qry="" \
             --params=""  \
             --desc="empty cypher query"
  
    runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="PIPE"  \
             --params=""  \
             --desc="empty cypher query"
  
    runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="STDIN"  \
             --params="-t -c --quiet"   \
             --desc="empty cypher query with --quiet"
  
    runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="PIPE"  \
             --params="-t -c --quiet"   \
             --desc="empty cypher query with --quiet"
    
    runShell --expectedRetCode=${RCODE_MISSING_INPUT_FILE} --inputType="FILE"  \
             --params="--file NoFile22432.cypher"  \
             --desc="run external cypher file missing file"
  
    printf '%s' "${testSuccessQry}" > ${TMP_TEST_FILE}
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="FILE"  \
             --params="--file ${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}"  \
             --desc="run external cypher file with valid query, validate output"
  
    # add path to shell to begining of file. used when in text with editor executing cut-paste-run
    printf '%s\n' "${TEST_SHELL}" > ${TMP_TEST_FILE}
    printf '%s' "${testSuccessQry}" >> ${TMP_TEST_FILE}
    runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="FILE"  \
             --params="--file ${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}" \
             --desc="executing ${TEST_SHELL} at beginning of text before cypher"

    # SAVE FILE TESTS
    #  --expectedNbrFiles
    #  --saveFilePrefix        
    testGroup="save file test" 
    runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
             --params="--saveAll"  \
             --expectedNbrFiles=2  \
             --desc="save cypher query and text results default pre- and postfix."
  
    runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
             --params="--saveCypher"  \
             --expectedNbrFiles=1  \
             --desc="save cypher query only file default postfix."
  
    runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
             --params="--saveResults"  \
             --expectedNbrFiles=1  \
             --desc="save results file only default postfix."
  
    runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}"  \
             --params="--saveResults"  \
             --expectedNbrFiles=1  \
             --desc="file tests - save results file only default postfix."
  
    runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testFailQry}"  \
             --params="--saveResults"  \
             --expectedNbrFiles=0 \
             --desc="bad query input save results file that will not exist."
   
    break # made it to end, exit loop
  done
}

setDefaults () {
  # SET THESE VARIABLES
  TEST_SHELL='../../repl-cypher-shell.sh'  # shell to test! Needs to be set
  if [[ ! -x ${TEST_SHELL} ]]; then
    printf '%s' "ERROR ${TEST_SHELL} script to be tested does not exist or is not executable.  Bye.\n"
    exit 1
  fi
  DEF_UID="neo4j"  # use if env var NEO4J_USERNAME is not set
  DEF_PW="admin"   # use if env var NEO4J_PASSWORD is not set
  DEF_START_TEST_NBR=1   # default test number to start at
  DEF_END_TEST_NBR=1000  # default test number to end at (some huge #)
  testErrorExit="N"      # default is not to stop on error
}

#
# MAIN
#
setopt SH_WORD_SPLIT >/dev/null 2>&1

trap interruptShell SIGINT

setDefaults
initVars
getCmdLineArgs "${@}"

# ckForLeftoverOutputFiles 
# for shellToUse in 'zsh' 'bash'; do
for shellToUse in 'zsh'; do
  runCnt=0        # nbr of tests run
  successCnt=0    # testing success count
  errorCnt=0      # testing error count
  printf "\n+++ Starting using %s\n" "${shellToUse}"
  testsToRun # run the darn tests already!
  finalOutput

  [[ ${errorCnt} -ne 0 || ${dryRun} == 'Y' ]] && break || continue # 1st shell fails then 2nd likely will also
done
exitShell 0
#./formatOutput.sh ${RESULTS_OUTPUT_FILE}
