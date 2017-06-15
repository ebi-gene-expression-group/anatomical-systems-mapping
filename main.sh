PAGE_SIZE=1000

set -euo pipefail

descendants(){ curl -s "http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$1/hierarchicalDescendants?size=$PAGE_SIZE&page=$2"  \
 | jq -r '._embedded.terms // [] | map (.short_form +"|"+ .label)[]' | grep '[^[:blank:]]'| sort -u
}

# $1: log location
# $2: UBERONid of anatomical system
# $3: page to retrieve
task(){
  descendants $2 $3 2> >( xargs -0  printf "Error: $2 page $3 | %s\n" ) | tee -a >(wc -l | xargs printf "Out| $2 | $3 | %s\n"  >> $1)
}

#1 : UBERON id
paged_descendants(){
  uberon_id="$1"
  PAGES=$(curl -s http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$1/hierarchicalDescendants?size=$PAGE_SIZE \
    | jq -r '.page.totalPages')
  if [[ $PAGES -eq 0 ]]
  then
    >&2 echo "[$uberon_id]Found no data!"
  else
    for page in $( seq 0 $[PAGES-1] ); do
      >&2 echo "[$uberon_id] retrieving page $[page+1]/$[PAGES]"
      >&1 descendants $uberon_id $page
    done
  fi
}

for system_id in $(cat $(dirname "${BASH_SOURCE[0]}" )/all_systems | cut -f1 -d '|') ; do
  target="$(dirname "${BASH_SOURCE[0]}" )/out/$system_id"
  if [[ -e "$target" ]]; then
    >&2 echo "[$system_id] Found, skipping"
  else
    paged_descendants $system_id > $target
    sort -u $target -o $target
    >&2 echo "[$system_id] Retrieved $(cat $target | wc -l) descendants"
  fi
done

echo "Generating anatomical_systems.txt"
$(dirname "${BASH_SOURCE[0]}" )/join_files.py

echo "Appending extra mappings"
cat "$(dirname "${BASH_SOURCE[0]}" )/extra_mappings.txt" >> "$(dirname "${BASH_SOURCE[0]}" )/out/anatomical_systems.txt"

sort -u $(dirname "${BASH_SOURCE[0]}" )/out/anatomical_systems.txt -o "$(dirname "${BASH_SOURCE[0]}" )/out/anatomical_systems.txt"
