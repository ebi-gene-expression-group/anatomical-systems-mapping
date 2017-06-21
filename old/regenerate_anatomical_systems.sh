pushd $(dirname $0)
echo -ne "Retrieving anatomical systems...\r"
curl -s http://www.ebi.ac.uk/ols/api/ontologies/uberon/terms/http%253A%252F%252Fpurl.obolibrary.org%252Fobo%252FUBERON_0000467/children?size=1000 \
| jq -r '._embedded.terms | map (.short_form +"|"+ .label+"\n") | add' | grep '[^[:blank:]]'| sort | uniq \
 > ./all_systems_uncurated
echo "Retrieved $(cat ./all_systems_uncurated | wc -l) systems             "
popd
