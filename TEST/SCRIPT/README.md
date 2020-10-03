## `runTest.sh` a testing script for *`repl-cypher-shell.sh`*

### runTests.sh
 - Executes the `repl-cypher-shell.sh` target using different parameter options, input and output tests. Tests validate results by:
   - Return code validation
   - Contents of query results
   - Existence of saved query and results file


 - If `repl-cypher-shell.sh` is started with one parameter it will print out the return code values and exit.

 - There is no testing for interactive scenarios, e.g. using an external editor.

 - Script is dependent `repl-cypher-shell.sh` on variable names for return codes and file name patterns.


 #### Dependencies and requirements to run *runTest.sh*
 1. The environment variables `NEO4J_USERNAME` and `NEO4J_PASSWORD` need to be set, or the script needs to be modified to set the script variables `uid` and `pw` to set a default.

 2. `repl-cypher-shell.sh` variables:
   - `RCODE_*` return codes
   - `OUTPUT_FILES_PREFIX`, `QRY_FILE_POSTFIX`, `RESULTS_FILE_POSTFIX`, `TIME_OUTPUT_HEADER` results file variables

3. The `runShell ()` function executes the tests and requires at least 7 parameters.


#### CAVEAT
One sad workaround to avoid having skip having to deal with user interaction is using the `-1` parameter (e.g. `repl-cypher-shell.sh -1`).  The `-1`  parameter runs one query and then will exit.  So I guess this parameter is tested by default.
