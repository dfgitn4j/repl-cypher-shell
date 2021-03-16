## Scripted Testing

 Scripts used to test repl-cypher-shell.sh script

### Testing Files

 sRunTests.sh    Testing shell that calls repl-cypher-shell.sh with 
                 different scenarios. Munctions in sRunTest.sh are:
                  
                   * testsToRun(): Runs individual tests by calling runShell()
                   * runShell(): Executes individual tests

 outputFormat.sh   Formats the testing results output file resultsTestRun.out. 
                   More verbose than what is printed on the screen.
 
 resultsTestRun.out Testing output file. More info than what is printed on
                    the screen.

### Command line parameters

 Valid command line options:
   --uid=<string>       Neo4j user login. Default is neo4j.  
   --pw=<string>        Neo4j user password. Default is admin.    
   
   --testErrorExit      Stop testing on error. Default is to keep running.
                        Stays enabled unless reset.     
   --returnToCont       Press <RETURN> to continue after each test. Stays 
                        enabled unless reset.           
   
   --dryRun             Print what tests would be run. 
   --startTestNbr=<nbr> Begin at test number 'nbr'. Default is 1.
   --endTestNbr=<nbr>   End at test number 'nbr'. Default is 1000.
        
   --printVars          Print variables used as set in TEST_SHELL=../../repl-cypher-shell.sh. 
                        NOTE: The TEST_SHELL varible is set in the code. 

   --help               This message.

   NOTE: 
     The variables uid, pw, testErrorExit and returnToCont can all be 
     changed before each test is run.

     testErrorExit and returnToCont variable values are 'Y' to enable, anything 
     else to disable. Using command line flags sets the variable to 'Y', must 
     be disabled explicitly in code. 

