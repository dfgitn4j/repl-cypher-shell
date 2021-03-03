#set -xv

# // good test query
# MATCH (n) 
# RETURN n, datetime() as ts
# LIMIT 1
# ;

TEST_SHELL="../../repl-cypher-shell.sh"
# get results file postfix
eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
eval "$(grep --color=never QRY_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
eval "$(grep --color=never OUTPUT_FILES_PREFIX= ${TEST_SHELL} | head -1)"

# create test files with query
file_without_cypher="${OUTPUT_FILES_PREFIX}without cypher test${QRY_FILE_POSTFIX}"
file_with_cypher="${OUTPUT_FILES_PREFIX}with cypher test${QRY_FILE_POSTFIX}"

findStr() {
  # ${1} is the string to find
  
  local _lookFor="${1}"
  local _inThis
  shift
  for arg in "$@"; do _inThis="${_inThis} ${arg}"; done
  echo "${_inThis}" | grep --extended-regexp --ignore-case --quiet -e "${_lookFor}"
  return $?
}

validFirstChar() {
   # match only the first first character of $1  
   # $2 is pattern to match, e.g. 'yqn'
  [[ $# -ne 2 ]] &&  exitShell ${RCODE_INTERNAL_ERROR}  # require 2 parameters

  printf -v _lookFor "%.1s" "${1}"
  local _inThis="${2}"
  echo "${_inThis}" | grep --extended-regexp --ignore-case --quiet -e "${_lookFor}"
  retVal=$?
}

exitShell() {
  removeOutputFiles
  exit
}

enterYesNoQuit() {
  # ${1} is valid response pattern in form of "YNQynq", <CR> defaults to Yes
  # ${2} is the  message for the user
  # a little risky since $1 and $2 can be optional
  local _ret_code
  local _option

  [[ ${is_pipe} == "Y" ]] && return # pipe, no inteactive input

  local _valid_opts="${1:-ynq}"
  local _msg=${2:-"<Enter> | y <Enter> to continue, n <Enter> to return, q <Enter> to quit."}
  printf "%s" "${_msg}"
  
  read -r _option  
  validFirstChar "${_option}" "${_valid_opts}"
  if [[ $? -ne 0 ]]; then
    printf "'${_option}' is an invalid choice."
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
    return ${_ret_code}
  fi
}

existingFileCnt () {
  # 1st param is the file pattern to test
  local ret=$(printf '%0d' $(find "${1}" -name "${2}" -type f -depth 1 | wc -l ) )
  echo ${ret}
}

outputFile () {
  local file_pattern="${1}"
  local msg="${2:-}"
  local cnt=0
  local file_cnt=$(existingFileCnt "." "${file_pattern}")
  [[ ${file_cnt} -eq 0 ]] && return
  printf '%s\n' "----- ${msg} There are ${file_cnt} file(s) with name pattern: '${file_pattern}' -----" 
  OLDIFS="$IFS"
  IFS=$'\n'
  # for file in $(find . -depth 1 -type f -name "${file_pattern}"); do
  for file in $(ls -1r ${file_pattern}); do
    (( cnt++ ))
    printf '%1d. File name: %s\n' ${cnt} "${file}"
    cat "${file}" 
    printf '\n-----\n'
  done
  IFS="${OLDIFS}"
  return ${cnt}
}

removeOutputFiles () {
  local qryFileCnt=$(existingFileCnt "." "*${QRY_FILE_POSTFIX}")
  local resFileCnt=$(existingFileCnt "." "*${RESULTS_FILE_POSTFIX}")

  if [[ $(( qryFileCnt+resFileCnt )) -gt 0 ]]; then
    printf '%s' "Press enter to delete ${qryFileCnt} qry files, and ${resFileCnt} results files to continue."
    read n
    find . -depth 1 -name "*${RESULTS_FILE_POSTFIX}" -exec rm {} \;
    find . -depth 1 -name "*${QRY_FILE_POSTFIX}" -exec rm {} \;
  fi 
  [[ -f ${current_input_file} ]] && rm "${current_input_file}"
}

runTestShell () {
  local _desc="${1:-}"
    
  printf "\n%s\n" "${_desc}Press Enter to run: ${TEST_SHELL} ${currentCmdLineParam} ${currentFileParam}"
  enterYesNoQuit "qn" "<Enter> to run test, (n) skip, (q) to exit. "
  if [[ $? -eq 1 ]]; then # skipping
    [[ ${toRun} == "loop" ]] && continue || return
  fi

  eval "${TEST_SHELL} ${currentCmdLineParam} ${currentFileParam}"
  ret_val=$?

  printf '\n%s\n' "Exit code = ${ret_val} Called with: ${TEST_SHELL} ${currentCmdLineParam} ${currentFileParam}"
  [[ ${toRun} == "one" ]] && removeOutputFiles
}

#
# Main loop
#
toRun="${1:all}"  # 1st arg should be one, loop or all.  default is all
declare -a callingParams  # command line parameter array for each test
declare -a fileParams     # file save command line parameters for each test

clear 

# Individual tests
if [[ ${toRun} == "one" || ${toRun} == "all" ]]; then
  printf '\n%s\n' "=== Individual on-and-done tests ==="
  currentCmdLineParam=""; runTestShell "No parameters, using stdin. "
  currentCmdLineParam="--one"; runTestShell "Run once then done. "
  currentCmdLineParam="--exitOnError"; runTestShell "Cypher should error and exit. "
  currentCmdLineParam="--exitOnError --saveAll"; runTestShell "one" "Cypher should error and exit. No save files on error. "
  currentCmdLineParam="--nano"; runTestShell "Cypher should error and exit. No save files on error. "
fi

[[ ${toRun} == "one" ]] && exitShell

# parameter testing scenarios
# three main file scenarios:
# 1. vi / nano with no file name should result in 0 output files
# 2. vi with supplied file name with no contents should result in 1 newly created output file
# 3. vi with supplied file name with file contents should result in 1 output file

printf '\n%s\n' "=== Starting loop through file and calling parameters ==="
#fileParams=("" "--file '${file_without_cypher}'" "--file '${file_with_cypher}'")
#callingParams=("--vi" "--vi --saveCypher" "--vi --saveResults" "--vi --saveAll")
fileParams=("--file '${file_without_cypher}'" )
callingParams=("--vi --saveCypher" "--vi --saveResults" "--vi --saveAll")
for currentFileParam in "${fileParams[@]}"; do # test without and with input file
  for currentCmdLineParam in "${callingParams[@]}"; do
    save_cypher_file="N"
    save_results_file="N" 
    min_file_cnt=0 # minimum number of output files
    qry_file_cnt=0 # number of cypher query files
    res_file_cnt=0 # number of results files

    if [[ -n ${currentFileParam} ]]; then # non blank --file parameter given
      if [[ ${currentFileParam} == *${file_with_cypher}* ]]; then # have cypher file 
        echo "MATCH (n) RETURN n LIMIT 5" > "${file_with_cypher}"
        current_input_file="${file_with_cypher}"
      else # empty file. vi should start in insert mode
        current_input_file="${file_without_cypher}"
      fi
      (( min_file_cnt++ ))
    else
      current_input_file=""
    fi
    if [[ ${currentCmdLineParam} == *"--saveCypher"* ]] || [[ ${currentCmdLineParam} == *"--saveAll"* ]]; then
      save_cypher_file="Y"
      (( min_file_cnt++ ))
    fi
  
    if [[ ${currentCmdLineParam} == *"--saveResults"* ]] || [[ ${currentCmdLineParam} == *"--saveAll"* ]]; then
      save_results_file="Y" 
      (( min_file_cnt++ ))
    fi

    runTestShell  # runtest, using $TEST_SHELL, $callingParams and $currentFileParam variables.
 
    if [[ ${save_cypher_file} == "Y" ]]; then
      outputFile "${OUTPUT_FILES_PREFIX}*${QRY_FILE_POSTFIX}" "Save cypher file"
      qry_file_cnt=$?
    else
      outputFile "${current_input_file}" "Input cypher file" 
      qry_file_cnt=$?      
    fi
    if [[ ${save_results_file} == "Y" ]]; then
      outputFile "${OUTPUT_FILES_PREFIX}*${RESULTS_FILE_POSTFIX}" "Save results file"
      res_file_cnt=$?
    fi

    total_file_cnt=$(( qry_file_cnt+res_file_cnt ))
    if [[ ${total_file_cnt} -ge ${min_file_cnt} ]]; then  # 0 = 0 is good regardless of saving files, else tot >= min means no errors
      removeOutputFiles
    else # 
      printf '%s\n%s\n' "*** Potential error - validate number of output files or non-zero return code." \
        "Return code: ${ret_code}  Minimum file count: ${min_file_cnt} actual file count: ${total_file_cnt} "
      printf '%s %1d %s\n' "  Found " ${qry_file_cnt} " query files: $(find . -depth 1 -name "${OUTPUT_FILES_PREFIX}*${QRY_FILE_POSTFIX}" -print)"
      printf '%s %1d %s\n' "  Found " ${res_file_cnt} " results files: $(find . -depth 1 -name "${OUTPUT_FILES_PREFIX}*${RESULTS_FILE_POSTFIX}" -print)"
    fi 

  done

done

