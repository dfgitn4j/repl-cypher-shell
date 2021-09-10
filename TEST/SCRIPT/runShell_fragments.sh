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