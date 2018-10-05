PAGE_SIZE=1000

set -euo pipefail

ols_url(){
  what="$1"
  cell_id="$2"
  pageParam="${3:+page=$3}"
  echo "https://www.ebi.ac.uk/ols/api/ontologies/cl/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$cell_id/$what?size=$PAGE_SIZE&$pageParam"
}

get_terms(){
  curl $( ols_url "$@" ) \
   | jq -r '._embedded.terms // [] | map (.short_form +"\t"+ .label)[]' | grep '[^[:blank:]]'| sort -u
}

get_total_pages(){
  curl $( ols_url "$@" ) \
   | jq -r '.page.totalPages'
}

#1 : cell id
paged_ancestors(){
  cell_id="$1"
  >&2 echo "[$cell_id] retrieving page count"
  PAGES=$(get_total_pages "hierarchicalAncestors" "$cell_id" )
  if [[ $PAGES -eq 0 ]] 
    then
    >&2 echo "[$cell_id]Found no data"
  else
    for page in $( seq 0 $[PAGES-1] ); do
      >&2 echo "[$cell_id] retrieving page $[page+1]/$[PAGES]"
      >&1 get_terms "hierarchicalAncestors" "$cell_id" "$page"
    done
  fi
}

if [[ $# -lt 1 ]] ; then
  echo "Fetch hierarchical ancestors from OLS"
  echo "Usage: $0 id_1 id_2 ... id_n"
  exit 2
fi

for cell_id in "$@" ; do
  paged_ancestors $cell_id | awk -F '\t' -v ID="$cell_id" '{print ID "\t" $0}'
done
