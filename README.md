Anatomical systems from OLS
-------------------

The script queries OLS's webservice and builds a flattened out collection of tissues per anatomical system.

#### Requires:
  `bash`
  [jq](https://stedolan.github.io/jq/download/)

Takes about ten minutes (in October used to be like: an hour) to refresh. You should be able to kill it and have it resume from where it started.
Clear the log directory to have the script continue.


#### Expression Atlas per-release workflow
Run main.sh to get the new systems
Commit and run something like `git diff HEAD~ HEAD out/anatomical_systems.txt` to see the changes look like they can be attributed to progress of science and not bad code
Push the new file to repo
On the cluster, do something like `curl https://raw.githubusercontent.com/wbazant/anatomicalsystems/master/out/anatomical_systems.txt > /ebi/ftp/pub/databases/microarray/data/atlas/ontology/anatomical_systems.txt`


#### Curation workflow
The file to curate is called **all_systems**.
We should strive to reduce the number of unmapped tissues that show up in the UI while keeping the list of anatomical systems manageable for the users.
The systems we use are children of `UBERON_0000467` - "anatomical system" in OLS - that are being trimmed down manually.
Laura gives the following rules of curating this list:

1. If one anatomical system only contains another system as children term -> just import the children term.
  *Example: instead of importing entire sense organ system, import sensory system.*
2. If one anatomical system is the children of others just import the parent term
  *Example: instead of importing lacrimal apparatus just import its parent sensory system.*
3. If one anatomical system contains no children, don’t import the anatomical system.
  *Example: don’t import dermatological-muscosal system*
4. If one anatomical system is not applicable to human, don’t import it.
  *Example: don’t import water vascular system*

#### Curation notes
Gustatory System: For now in Atlas we just have tongue mapped to gustatory system. Tongue is also mapped to digestive system and sensory system. We kept it out but if we have more experiments for gustatory system tissues we shall include it back.
