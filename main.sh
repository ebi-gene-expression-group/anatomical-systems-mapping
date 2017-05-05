mkdir -p log out
pushd $(dirname $0)


one_system()
{
if [ -f log/$1 ] && [ $(grep -c Error log/$1) -eq 0 ] && [ -f out/$1 ] && [ $(cat out/$1 | wc -l ) -gt 0 ]
then
   echo "Skipping $1  ...                               "
else
  echo  -ne "Refreshing $1 ...                         \r"
  rm out/$1 2> /dev/null
   ./paged_descendants.sh $1
fi

}

for SYSTEM in $(cat ./all_systems | cut -f1 -d '|')
  do one_system $SYSTEM
done

echo -ne "Done! Errors: "
find ./log -type f | xargs grep Error

echo "Generating anatomical_systems.txt ..."
./join_files.py

echo "Appending extra mappings ..."
cat './extra_mappings.txt' >> './out/anatomical_systems.txt'

sort -u './out/anatomical_systems.txt' -o './out/anatomical_systems.txt'

popd
