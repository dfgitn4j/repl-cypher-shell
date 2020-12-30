./repl-cypher-shell.sh --time  -u  neo4j

// Terminus package is used for output
 // send selected text to terminal and run key sequence is mapped
 // to the ctl-enter key combination

// Some comment that explains what this query does
 // can...
 // ... be
 // ......very
 // .........long
MATCH path=(:Person)-[:ACTED_IN]->()<-[:DIRECTED]-(:Person) RETURN path

// Get label frequencies
CALL db.labels() YIELD label
  CALL apoc.cypher.run('MATCH (:`'+label+'`) RETURN count(*) as label_count',{})
  YIELD value
  WITH label,value.label_count AS label_count
    CALL apoc.meta.stats() YIELD nodeCount
    WITH *, 3 AS presicion
    WITH *, 10^presicion AS factor,toFloat(label_count)/toFloat(nodeCount) AS relFreq
      RETURN label AS nodeLabel, label_count AS count,
      round(relFreq*factor)/factor AS relativeFrequency 
      ORDER BY label_count DESC;