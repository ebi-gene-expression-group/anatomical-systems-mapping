PAGE_SIZE=1000

descendants(){
curl -s "http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$1/hierarchicalDescendants?size=$PAGE_SIZE&page=$2"  \
 | jq -r '._embedded.terms | map (.short_form +"|"+ .label+"\n") | add' | grep '[^[:blank:]]'| sort -u
}

# $1: log location
# $2: UBERONid of anatomical system
# $3: page to retrieve
task(){
  descendants $2 $3 2> >(xargs -0  printf "Error| $2 | $3 | %s\n"  >> $1 ) | tee -a >(wc -l | xargs printf "Out| $2 | $3 | %s\n"  >> $1)
}

#1 : UBERON id
paged_descendants(){
  LOG="./log/$1"
  OUT="./out/$1"
  TMP=".tmp~$1"
  PAGES=$(curl -s http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252F$1/hierarchicalDescendants?size=$PAGE_SIZE \
    | jq -r '.page.totalPages')
  if [ $PAGES -eq 0 ]
  then
    echo "Found no data for for $1"
  else
    printf "Pages | $1 | $PAGES\n" >> $LOG
    for page in $(seq 0 $[PAGES-1]); do
      task $LOG $1 $page
    done >> $TMP
    sort -u $TMP > $OUT
    echo "Retrieved $(cat $OUT | wc -l ) descendants for $1"
    rm $TMP
  fi
}

one_system(){
if [[ -f log/$1 ]] && [[ $(grep -c Error log/$1) -eq 0 ]] && [[ -f out/$1 ]] && [[ $(cat out/$1 | wc -l ) -gt 0 ]]
then
   echo "Skipping $1  ...                               "
else
  echo  -ne "Refreshing $1 ...                         \r"
  rm out/$1 2> /dev/null
  rm log/$1 2> /dev/null
  paged_descendants $1
fi

}

mkdir -p log out
pushd $(dirname $0)

for SYSTEM in $(cat ./all_systems | cut -f1 -d '|')
  do one_system $SYSTEM
done

echo -ne "Done! Errors: \n"
find ./log -type f | xargs grep Error

echo "Generating anatomical_systems.txt ..."
./join_files.py

echo "Appending extra mappings ..."
cat './extra_mappings.txt' >> './out/anatomical_systems.txt'

sort -u './out/anatomical_systems.txt' -o './out/anatomical_systems.txt'

popd
