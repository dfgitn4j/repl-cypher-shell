repl-cypher-shell.sh

// platformio-ide-terminal package is used for output
// send selected text to terminal and run key sequence is mapped to the
// ctl-1 key combination.  Have to hit enter ctl-D to run command
// Some comment that explains what this query does
// can...
// ... be
// ......very
// .........long
MATCH (n)
  RETURN n
  LIMIT 10

MATCH (n:Person)
 RETURN count(n)
