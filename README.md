### Anatomical systems from OLS

The script queries OLS's webservice and builds a flattened out collection of tissues per anatomical system.

####Requires:
  `bash`
  [jq](https://stedolan.github.io/jq/download/)

Takes about ten minutes (in October used to be like: an hour) to refresh. You should be able to kill it and have it resume from where it started.
Clear the log directory to have the script continue.

#### Expression Atlas workflow
Run index.sh to get the new systems
Commit and run something like `git diff HEAD~ HEAD out/anatomical_systems.txt` to see the changes look like they can be attributed to progress of science and not bad code
Push the new file to repo
On the cluster, do something like `curl https://raw.githubusercontent.com/wbazant/anatomicalsystems/master/out/anatomical_systems.txt > /ebi/ftp/pub/databases/microarray/data/atlas/ontology/anatomical_systems.txt`
