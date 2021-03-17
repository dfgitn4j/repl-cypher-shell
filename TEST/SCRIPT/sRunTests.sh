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
   
   --testErrorExit      Stop testing on error. Default is to keep running.
                        Stays enabled unless reset.     
   --returnToCont       Press <RETURN> to continue after each test. Stays 
                        enabled unless reset.           
   
   --dryRun             Print what tests would be run. 
   --startTestNbr=<nbr> Begin at test number 'nbr'. Default is ${DEF_START_TEST_NBR}.
   --endTestNbr=<nbr>   End at test number 'nbr'. Default is ${DEF_END_TEST_NBR}.
        
   --printVars          Print variables used as set in TEST_SHELL=${TEST_SHELL}. 
                        NOTE: The TEST_SHELL varible is set in the code. 

   --help               This message.

   NOTE: 
     The variables uid, pw, testErrorExit and returnToCont can all be changed
     before each test is run.  Defaults are set in function setDefaults().

     testErrorExit and returnToCont variable values are 'Y' to enable, anything 
     else to disable. Using command line flags sets the variable to 'Y', must 
     be disabled explicitly in code. 

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

      echo "${validOpts}" | grep --quiet "$paramName "
      if [[ $? -ne 0 ]]; then  # ck for invalid parameter name
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
      errorMsg="ERROR: Invalid parameter '${1}'"
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
  if [[ ${startTestNbr} -gt ${endTestNbr} ]]; then
    printf '%s\n' "ERROR for options: --startTestNbr=${startTestNbr} cannot be greater than --endTestNbr=${endTestNbr}\n"
    exit 1
  fi
  
  # set defaults for flag parameters
  dryRun="${dryRun:-N}"              # show what would be run with step #
  returnToCont="${returnToCont:-N}"  # press enter to continue to next test

  # use environment variable for uid and pw if set and not overridden, ow use defaults
  if [[ -n ${uid} ]]; then  # provide uid
    export NEO4J_USERNAME="${uid}"
  elif [[ -z ${NEO4J_USERNAME} ]]; then # NEO4J_USERNAME env var does not exist
    export NEO4J_USERNAME="${DEF_UID}"
  fi

  if [[ -n ${pw} ]]; then  # provide pw
    export NEO4J_PASSWORD="${pw}"
  elif [[ -z ${NEO4J_PASSWORD} ]]; then # NEO4J_PASSWORDenv var does not exist
    export NEO4J_PASSWORD=${DEF_PW}
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
  eval "$(grep --color=never QRY_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
  eval "$(grep --color=never DEF_SAVE_DIR= ${TEST_SHELL} | head -1)"
}

initVars () {
  extractTestingVars  # get required variables from $TEST_SHELL being tested

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
  printf "%s\n" "QRY_FILE_POSTFIX=${QRY_FILE_POSTFIX}"
  printf "%s\n" "RESULTS_FILE_POSTFIX=${RESULTS_FILE_POSTFIX}"
  printf "%s\n" "DEF_SAVE_DIR=${DEF_SAVE_DIR}" 
  printf "\n=================================\n"
  exit 0
}

exitShell () {
  # 1st param is return code, 0 if none specified
  rm ${QRY_OUTPUT_FILE} 2>/dev/null
  rm ${TEST_SHELL_OUTPUT} 2>/dev/null # remove cypher-shell output log

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
  # testGrp, testErrorExit and returnToCont stay set until expliclty changed

  for envVar in "${currentParams[@]}"; do 
    [[ ${envVar} != "testErrorExit" && ${envVar} != "returnToCont" && ${envVar} != "testGroup" ]] && unset "${envVar}"
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
    fi
    currentParams+=("${paramName}") # add to array to erase next time through
    shift
  done

  # if not provided, provide defaults for parameters that need to be set 
  expectedNbrFiles=${expectedNbrFiles:-0}  # expected number of output files
  shellToUse="${shellToUse:-zsh}"          # shell to use
  inputType="${inputType:-STDIN}"          # input types are STDIN, PIPE and FILE

  expectedRetCode="${expectedRetCode:-${RCODE_SUCCESS}}" # pulled from shell being tested
  qry="${qry:-${testSuccessQry}}" # use succesful query if no query specified

  desc="${desc:-not provided}"             # description is optional
  testGroup="${testGroup:-not provided}"   # testing group description

  # process parameters
  if [[ -z ${saveDir} ]]; then # $saveDir var exists, but it empty
    saveDir="."
  elif [[ -z ${saveDir} ]]; then # --saveDir option specified w/o a directory, use default
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
        echo "${qry}" | eval "${shellToUse}" "${TEST_SHELL}" "${params}" >"${QRY_OUTPUT_FILE}" 2>&1 >${TEST_SHELL_OUTPUT}
        actualRetCode=$?
      elif [[ ${inputType} == "FILE" ]]; then # expecting -f <filename> parameter
        ${shellToUse} "${TEST_SHELL}" -1 "${params}" >"${QRY_OUTPUT_FILE}" 2>&1 >>${TEST_SHELL_OUTPUT}
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
  # INITIAL SNIFF TEST NEO4J_USERNAME and NEO4J_PASSWORD env vars need to be valid
  testGroup="initial connection"
  oldExitOnError=${testErrorExit}  # testErrorExit can be set via command line, but need to test if db is online
  runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="STDIN" --qry="${testSuccessQry}" \
           --testGroup="${testGroup}" --desc="using NEO4J_[USERNAME PASSWORD] environment variables." \
           --testErrorExit            
  testErrorExit="${oldExitOnError}"  # put back original testErrorExit if there is one    

  while true; do

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
           --desc="query tests - empty cypher query"

  runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="PIPE"  \
           --params=""  \
           --desc="query tests - empty cypher query"

  runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="STDIN"  \
           --params="-t -c --quiet"   \
           --desc="query tests - empty cypher query with --quiet"

  runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="PIPE"  \
           --params="-t -c --quiet"   \
           --desc="query tests - empty cypher query with --quiet"
  
  runShell --expectedRetCode=${RCODE_MISSING_INPUT_FILE} --inputType="FILE"  \
           --params="--file NoFile22432.cypher"  \
           --desc="query / file tests - run external cypher file missing file"

  printf '%s' "${testSuccessQry}" > ${TMP_TEST_FILE}
  runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="FILE"  \
           --params="--file=${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}"  \
           --desc="query / file tests - run external cypher file with valid query, validate output"

  printf '%s' "${TEST_SHELL}" > ${TMP_TEST_FILE}
  printf '%s' "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode="${RCODE_SUCCESS}" --inputType="FILE"  \
           --params="--file=${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}" \
           --desc="query / file tests - executing $ at beginning of text before cypher"
   
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
