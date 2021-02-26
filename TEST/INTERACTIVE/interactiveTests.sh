#set -xv 
# command line options to test that require keyboard input

# get results file postfix
TEST_SHELL="../../repl-cypher-shell.sh"
eval "$(grep --color=never RESULTS_FILE_POSTFIX= ${TEST_SHELL} | head -1)"
eval "$(grep --color=never QRY_FILE_POSTFIX= ${TEST_SHELL} | head -1)"

# create test files with query
file_without_cypher="without cypher test${QRY_FILE_POSTFIX}"
file_with_cypher="with cypher test${QRY_FILE_POSTFIX}"



outputFile () {
  local file_pattern="${1}"
  local msg="${2}"
  local cnt=0
   printf '%s\n\n' "----- ${msg} file pattern: '${current_input_file}' -----" 
  for f in "$(find . -depth 1 -name "${file_pattern}" -print)"; do
    (( cnt++ ))
    printf '%1d. File name: %s\n' ${cnt} "${f}"
    cat "${f}"
    printf '\n'
  done
}

# three file scenarios:
# 1. vi with no file name should result in 0 output files
# 2. vi with supplied file name with no contents should result in 1 newly created output file
# 3. vi with supplied file name with file contents should result in 1 output file

# parameter testing scenarios
# declare -a params=("--vi" "--nano" "--vi --saveCypher" "--vi --saveResults" "--vi saveAll")
declare -a params=("--vi")
#for file_param in "" "--file '${file_without_cypher}'" "--file '${file_with_cypher}'"; do # test without and with input file
for file_param in "--file '${file_with_cypher}'"; do # test without and with input file
  for param in "${params[@]}"; do
    save_cypher_file="N"
    save_results_file="N" 
    min_file_cnt=0 # minimum number of output files
    qry_file_cnt=0 # number of cypher query files
    res_file_cnt=0 # number of results files
  
    if [[ -n ${file_param} ]]; then # non blank --file parameter given
      if [[ ${file_param} == *${file_with_cypher}* ]]; then # have cypher file 
        echo "MATCH (n) RETURN n LIMIT 5" > "${file_with_cypher}"
        current_input_file="${file_with_cypher}"
      else # empty file. vi should start in insert mode
        current_input_file="${file_without_cypher}"
      fi
      if [[ "--saveCypher" == *${params}* || "--saveAll" == *${params}* ]]; then
        save_cypher_file="Y"
        (( min_file_cnt++ ))
      fi
    
      if [[ "--saveResults" == *${params}* || "--saveAll" == *${params}* ]]; then
        save_results_file="Y" 
        (( min_file_cnt++ ))
      fi
    else
      current_input_file=""
    fi

    eval "${TEST_SHELL} ${param} ${file_param}"
    ret_val=$?

    printf '%s\n' "Exit code = ${ret_val} for test parameters '${param}' file parameters '${file_param}'. ( Called with: ${TEST_SHELL} ${param} ${file_param} )"

    if [[ -n ${current_input_file} ]]; then
      outputFile "${current_input_file}" "Input cypher file"
    fi

    if [[ ${save_cypher_file} == "Y" ]]; then
      outputFile "*${QRY_FILE_POSTFIX}" "Save cypher file"
    fi
    if [[ ${save_results_file} == "Y" ]]; then
      outputFile "*${RESULTS_FILE_POSTFIX}" "Save results file"
    fi

    qry_file_cnt=$(printf '%1d' $(ls *${QRY_FILE_POSTFIX} 2>/dev/null | wc -l) )
    res_file_cnt=$(printf '%1d' $(ls *${RESULTS_FILE_POSTFIX} 2>/dev/null | wc -l) )
    total_file_cnt=$(( qry_file_cnt+res_file_cnt ))
    if [[ ${total_file_cnt} -ge ${min_file_cnt} ]]; then  # 0 = 0 is good regardless of saving files, else tot >= min means no errors
      if [[ ${save_cypher_file} == "Y" ]]; then
        printf '%s %1d %s\n' "Found " ${qry_file_cnt} " query files: $(find . -depth 1 -name "*${QRY_FILE_POSTFIX}" -print)"
      fi
      if [[ ${save_results_file} == "Y" ]]; then
        printf '%s %1d %s\n' "Found " ${res_file_cnt} " results files: $(find . -depth 1 -name "*${RESULTS_FILE_POSTFIX}" -print)"
      fi
    else # 
      printf '%s\n%s\n' "*** ERROR: Wrong # output files or non-zero return code." \
        "Return code: ${ret_code}  Minimum file count: ${min_file_cnt} actual file count: ${total_file_cnt} "
      printf '%s %1d %s\n' "  Found " ${qry_file_cnt} " query files: $(find . -depth 1 -name "*${QRY_FILE_POSTFIX}" -print)"
      printf '%s %1d %s\n' "  Found " ${res_file_cnt} " results files: $(find . -depth 1 -name "*${RESULTS_FILE_POSTFIX}" -print)"
    fi 
    printf '%s' "Press enter delete output files and to continue."
    read n
    find . -depth 1 -name "*${RESULTS_FILE_POSTFIX}" -exec rm {} \;
    find . -depth 1 -name "*${QRY_FILE_POSTFIX}" -exec rm {} \;
    [[ -n ${current_input_file} ]] && rm "${current_input_file}"
  done

done

