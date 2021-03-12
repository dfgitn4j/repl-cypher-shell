# runShell fragments

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
           --params="--exitOnError noOptValExpected"  \
           --desc="invalid param test - flag argument only, no option expected."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
           --params="-Nogood"   \
           --desc="invalid param test - bad passthru argument to cypher-shell."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
           --params="--file"   \
           --desc="invalid param test - missing file argument value."

  runShell --expectedRetCode=${RCODE_INVALID_FORMAT_STR} --inputType="STDIN"  \
           --params="--format notgood"  \
           --desc="invalid param test - invalid format string."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="STDIN"  \
           --params="--vi --editor 'atom'"  \
           --desc="invalid param test - conflicting editor args."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
           --params="--vi"   \
           --desc="invalid param test - incompatible editor argument and pipe input"

  touch ${TMP_TEST_FILE}
  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
           --params="--file=${TMP_TEST_FILE}"  \
           --expectedNbrFiles=0 --externalFile="${TMP_TEST_FILE}" \
           --desc="invalid param test - incompatible file input and pipe input."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
           --params="--exitOnError nogood"   \
           --desc="invalid param test - flag argument only, no option expected."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
           --params="-Nogood"   \
           --desc="invalid param test - bad pass thru argument to cypher-shell."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
           --params="--file"   \
           --desc="invalid param test - missing file argument value."

  runShell --expectedRetCode=${RCODE_INVALID_FORMAT_STR} --inputType="PIPE"  \
           --params="--format notgood"  \
           --desc="invalid param test - invalid format string."

  runShell --expectedRetCode=${RCODE_INVALID_CMD_LINE_OPTS} --inputType="PIPE"  \
           --params="--vi --editor 'atom'"   \
           --desc="invalid param test - conflicting editor args."
  
  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
           --params="--invalid param"   \
           --desc="invalid param test - invalid parameter argument value."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
           --params="--invalid param"   \
           --desc="invalid param test - invalid parameter argument value."
 
  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN"  \
           --params="--address n0h0st"   \
           --desc="invalid param test - bad pass-thru argument to cypher-shell."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE"  \
           --params="--address n0h0st"  \
           --desc="invalid param test - bad pass-thru argument to cypher-shell."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_NOT_FOUND} --inputType="STDIN"  \
           --params="--cypher-shell /a/bad/directory/xxx"  \
           --desc="invalid param test - explicitly set cypher-shell executable with --cypher-shell."

  # VALID PARAM TESTS
  printf "\n*** Valid paramater tests ***\n"  
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="--cypher-shell ${CYPHER_SHELL}"   \
           --desc="param test - explicitly set cypher-shell executable with --cypher-shell."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN"  \
           --params="--version"   \
           --desc="param test - cypher-shell one-and-done version arg."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE"  \
           --params="--version"   \
           --desc="param test - cypher-shell one-and-done version arg."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params="--address localhost"  \
           --desc="param test - good thru argument to cypher-shell."

  # PASSWORD TESTS
  printf "\n*** uid / pw tests ***\n" 

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-u ${uid} -p ${pw}"  \
           --desc="uid/pw tests - using -u and and -p arguments"

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-u ${uid}"   \
           --desc="uid/pw tests - using -u and NEO4J_PASSWORD environment variable."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-p ${pw}"   \
           --desc="uid/pw tests - using -p and NEO4J_USERNAME environment variable."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-p ${pw}"   \
           --desc="uid/pw tests - using -p and NEO4J_USERNAME environment variable."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-p ${pw}xxx"  \
           --desc="uid/pw tests - using -u bad password"

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="-u ${uid}xxx"  \
           --desc="uid/pw tests - using -u bad username"
  
  unset NEO4J_USERNAME
  runShell --expectedRetCode=${RCODE_NO_USER_NAME} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params=""   \
           --desc="uid/pw tests - pipe input with no env or -u usename defined"
  export NEO4J_USERNAME=${uid}

  unset NEO4J_PASSWORD
  runShell --expectedRetCode=${RCODE_NO_PASSWORD} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params=""   \
           --desc="uid/pw tests - pipe input with no env or -p password defined"
  export NEO4J_PASSWORD=${pw}
  
  printf "\n*** Bad query test ***\n" 

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testFailQry}" \
           --params=""   \
           --desc="query tests - bad cypher query"

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE" --qry="${testFailQry}" \
           --params=""   \
           --desc="query tests - bad cypher query piped input"

  # QUERY INPUT TESTING 
  printf "\n*** Query method and param and output tests ***\n" 

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="--time"   \
           --grepPattern="${testTimeParamGrep}" \
           --desc="param test - test --time parameter output."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testParamQry}" \
           --params="${testParamParams}"   \
           --grepPattern="${testParamGrep}"  \
           --desc="param test - multiple arguments."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testParamQry}" \
           --params="${testParamParams}"   \
           --grepPattern="${testParamGrep}" \
           --desc="param test - multiple arguments."

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

  printf "${testSuccessQry}" > ${TMP_TEST_FILE}
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="FILE"  \
           --params="--file=${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}"  \
           --desc="query / file tests - run external cypher file with valid query, validate output"

  printf "${TEST_SHELL}" > ${TMP_TEST_FILE}
  printf "${testSuccessQry}" >> ${TMP_TEST_FILE}
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="FILE"  \
           --params="--file=${TMP_TEST_FILE}" --externalFile="${TMP_TEST_FILE}" \
           --desc="query / file tests - executing $ at beginning of text before cypher"

  # SAVE FILE TESTS
  #  --expectedNbrFiles
  #  --saveFilePrefix        
  printf "\n*** Save file test ***\n" 

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
           --params="--saveAll"  \
           --expectedNbrFiles=2  \
           --desc="file tests - save cypher query and text results default pre- and postfix."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
           --params="--saveCypher"  \
           --expectedNbrFiles=1  \
           --desc="file tests - save cypher query only file default postfix."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}"  \
           --params="--saveResults"  \
           --expectedNbrFiles=1  \
           --desc="file tests - save results file only default postfix."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}"  \
           --params="--saveResults"  \
           --expectedNbrFiles=1  \
           --desc="file tests - save results file only default postfix."

  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="STDIN" --qry="${testFailQry}"  \
           --params="--saveResults"  \
           --expectedNbrFiles=0 \
           --desc="file tests - bad query input save results file that will not exist."

   # query failed run w/ no files saved
  testType="file failed query test ${sep}"
  runShell --expectedRetCode=${RCODE_CYPHER_SHELL_ERROR} --inputType="PIPE" --qry="${testFailQry}"  \
           --params="--saveAll"  \
           --expectedNbrFiles=0 \
           --desc="${testType} bad query input save query and results files should not exist."

  runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="STDIN" --qry='' \
           --params="--saveResults"  \
           --desc="${testType} empty input query input save results file that will not exist."

  runShell --expectedRetCode=${RCODE_EMPTY_INPUT} --inputType="PIPE" --qry=''  \
           --params="--saveResults" \
           --desc="${testType} empty input query input save results file that will not exist."

  # begin testing own output file names
  printf "\n*** Defined ouput file names ***\n"
  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="--saveAll=${MY_FILE_NAME}"  \
           --expectedNbrFiles=2 \
           --desc="file tests - save with my defined file pattern."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="--saveCypher=${MY_FILE_NAME}"  \
           --outPattern="${saveQryFilePostfix}" \
           --expectedNbrFiles=1 \
           --desc="file tests - save with my defined file pattern."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="STDIN" --qry="${testSuccessQry}" \
           --params="--saveResults=${MY_FILE_NAME}"  \
           --outPattern="${saveUserDefFilePrefix}" \
           --expectedNbrFiles=1 \
           --desc="file tests - save with my defined file pattern."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params="--saveAll=${MY_FILE_NAME}"  \
           --outPattern="${saveAllFilePattern}" \
           --expectedNbrFiles=2 \
           --desc="file tests - save with my defined file pattern."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params="--saveCypher=${MY_FILE_NAME}"  \
           --outPattern="${saveQryFilePostfix}" \
           --expectedNbrFiles=1 \
           --desc="file tests - save with my defined file pattern."

  runShell --expectedRetCode=${RCODE_SUCCESS} --inputType="PIPE" --qry="${testSuccessQry}" \
           --params="--saveResults=${MY_FILE_NAME}"  \
           --outPattern="${saveUserDefFilePrefix}" \
           --expectedNbrFiles=1 \
           --desc="file tests - save with my defined file pattern."