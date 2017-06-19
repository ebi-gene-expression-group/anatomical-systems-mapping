PAGE_SIZE=1000

set -euo pipefail

ols_url(){
  what="$1"
  uberon_id="$2"
  pageParam="${3:+page=$3}"
  echo "http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$uberon_id/$what?size=$PAGE_SIZE&$pageParam"
}

get_terms(){
  curl $( ols_url "$@" ) \
   | jq -r '._embedded.terms // [] | map (.short_form +"\t"+ .label)[]' | grep '[^[:blank:]]'| sort -u
}

get_total_pages(){
  curl $( ols_url "$@" ) \
   | jq -r '.page.totalPages'
}

#1 : UBERON id
paged_descendants(){
  uberon_id="$1"
  >&2 echo "[$uberon_id] retrieving page count"
  PAGES=$(get_total_pages "hierarchicalDescendants" "$uberon_id" )
  if [[ $PAGES -eq 0 ]]
  then
    >&2 echo "[$uberon_id]Found no data!"
  else
    for page in $( seq 0 $[PAGES-1] ); do
      >&2 echo "[$uberon_id] retrieving page $[page+1]/$[PAGES]"
      >&1 get_terms "hierarchicalDescendants" "$uberon_id" "$page"
    done
  fi
}

get_mappings(){
  while read -r system_id_and_name; do
    read system_id system_name <<< $system_id_and_name
    paged_descendants $system_id | awk -F '\t' -v ID="$system_id" -v NAME="$system_name" '{print ID "\t" NAME "\t" $0}'
  done  < "$1"
}

if [[ $# -lt 1 ]] ; then
  echo "Fetch hierarchical descendants from OLS"
  echo "Usage: $0 id_1 id_2 ... id_n"
  exit 2
fi

for uberon_id in "$@" ; do
  paged_descendants $uberon_id | awk -F '\t' -v ID="$uberon_id" '{print ID "\t" $0}'
done
