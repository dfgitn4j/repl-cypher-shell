repl-cypher-shell.sh --time --saveAll

// Terminus package is used for output
 // send selected text to terminal and run key sequence is mapped
 // to the ctl-enter key combination

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
