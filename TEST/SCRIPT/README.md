## Scripted Testing

 Scripts used to test repl-cypher-shell.sh script

### Testing Files

#### sRunTests.sh

  Testing shell that calls repl-cypher-shell.sh with different scenarios. 
  Functions in sRunTest.sh are:
                  
  * testsToRun(): Runs individual tests by calling runShell()
  * runShell(): Executes individual tests

 #### outputFormat.sh

  Formats the testing results output file resultsTestRun.out. 
 
 #### resultsTestRun.out 
  
  Testing output file. More info than what is printed on the screen.

### Command line parameters

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

