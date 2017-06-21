# Atlas Metadata
Aggregated information about the (Expression Atlas)[www.ebi.ac.uk/gxa] dataset.
(Get the dataset here)[http://www.ebi.ac.uk/gxa/download.html]

#### Requires:
  `make`
  [jq](https://stedolan.github.io/jq/download/)
  [ammonite](ammonite.io)

### Setup
Add an environmental variable ATLAS_EXPS to wherever you have Expression Atlas experiments.
```
export ATLAS_EXPS=~/ATLAS3.TEST/integration-test-data/magetab/
```


## Anatomical systems and organs mapping from OLS

We curate a list of anatomical systems and organs in human.

#### Expression Atlas per-release workflow
- `make data/all-organism-parts.tsv && git commit -m "New organism part stats"` if any human baseline organism part experiments added and we want to have up-to-date aggregation of unmapped ids
- `make clean && make`
- Commit and run something like `git diff HEAD~ HEAD out/anatomical_systems.txt` to see the changes look like they can be attributed to progress of science and not bad code
- Push the new files to repo
- On the cluster, do something like
```
curl https://raw.githubusercontent.com/gxa/atlas-metadata/master/out/anatomical_systems.txt > /ebi/ftp/pub/databases/microarray/data/atlas/ontology/anatomical_systems.txt
curl https://raw.githubusercontent.com/gxa/atlas-metadata/master/out/organs.txt > /ebi/ftp/pub/databases/microarray/data/atlas/ontology/organs.txt
```
This workflow could be made more convenient.

#### Curation workflow
The files to curate are **curated/anatomical_systems/ids.tsv** and  **curated/organs/ids.tsv** .
We strive to not have any unmapped tissues show up in the UI while keeping the lists manageable for the users.
1. Change the mapping as needed
2. Run `make` to regenerate files
3. Run `git diff` to look at consequences of the change
4. `git commit` your change

##### Anatomical systems
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

##### Organs
Children of `organ` in UBERON are abstract kinds of organs e.g. `cavitated compound organ`.
We have instead chosen concrete and recognisable leaves in the ontology e.g. `kidney`.

#### Curation notes
Gustatory System: For now in Atlas we just have tongue mapped to gustatory system. Tongue is also mapped to digestive system and sensory system. We kept it out but if we have more experiments for gustatory system tissues we shall include it back.
