# format output from testing shell into columns
if [[ $# -ne 1 ]]; then
  printf "Need an input file produced by testing script. Bye.\n"
elif [[ ! -f ${1}  ]] ; then
  printf "File \'${1}\' does not exist. Bye. \n"
else 
  cat ${1} | tr '\t' '|' | column -t -s '|'
fi
