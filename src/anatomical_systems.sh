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
  cat "./curated/anatomical-systems-atlas.tsv" \
  | while read -r system_id_and_name; do
    read system_id system_name <<< $system_id_and_name
    paged_descendants $system_id | awk -F '\t' -v ID="$system_id" -v NAME="$system_name" '{print ID "\t" NAME "\t" $0}'
  done \
  | cat - "./curated/anatomical-systems-atlas-extra-mappings.tsv" \
  | sort -u
}


mappings=""
usageMessage="Usage: $0"
while getopts ":m" opt; do
  case $opt in
    m)
      atlasUrl=$OPTARG;
      ;;
    p)
      urlParams=$OPTARG;
      ;;
    d)
      destination=$OPTARG;
      ;;
    ?)
      echo "Unknown option: $OPTARG"
      echo $usageMessage
      exit 2
      ;;
  esac
done

main(){
  tmp="./out/anatomical_systems.tsv.tmp"
  >&2 echo "Getting the mappings"
  get_mappings > $tmp
  sort -u $tmp > "./out/anatomical_systems.tsv"
}

main2(){
  for system_id in $(cat $(dirname "${BASH_SOURCE[0]}" )/all_systems | cut -f1 -d '|') ; do
    target="$(dirname "${BASH_SOURCE[0]}" )/out/$system_id"
    if [[ -s "$target" ]]; then
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
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
