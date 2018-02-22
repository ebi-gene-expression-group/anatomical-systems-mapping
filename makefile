all: out/ontology_ids_per_experiment-human-baseline.tsv out/anatomical_systems.txt out/curation/anatomical_systems_unmapped_ids.tsv out/organs.txt out/curation/organs_unmapped_ids.tsv \
	out/celltype_ids_per_experiment-human-baseline.tsv out/cell_anatomical_systems.txt out/curation/anatomical_systems_unmapped_ids.tsv \
	out/cell_organ.txt out/curation/cell_organ_unmapped_ids.tsv

# get all human basline experiments from gxa/API call and sort experiment accessions.
data/all-public-human-baseline-experiments.txt:
	curl 'https://wwwdev.ebi.ac.uk/gxa/json/experiments' \
		| jq -r '.aaData | map(select(.species | contains ("sapiens")) | select(.experimentType | contains("BASELINE")) | .experimentAccession)[]' \
		| sort \
		> data/all-public-human-baseline-experiments.txt

# map public human expAcc ids with organism part and UERON-ID url from condensed.sdrf
data/all-organism-parts-human-baseline.tsv: data/all-public-human-baseline-experiments.txt
	cat data/all-public-human-baseline-experiments.txt \
	| xargs -I {} grep "factor[[:space:]]organism part" "${ATLAS_EXPS}/{}/{}.condensed-sdrf.tsv" \
	| cut -f 1,6,7 \
	| sort -u \
	> data/all-organism-parts-human-baseline.tsv

# all-organism-parts-human-baseline.tsv is reordered to join by the ontology ids associated with  organsim part and associate experiement accession
out/ontology_ids_per_experiment-human-baseline.tsv: data/all-organism-parts-human-baseline.tsv
	amm -s src/JoinByThirdColumn.sc data/all-organism-parts-human-baseline.tsv \
		> out/ontology_ids_per_experiment-human-baseline.tsv

### anatomical systems specific
# anatomical_systems/ids.tsv is passed by the curator. 
# hierarchical_descendants script uses the UBERON ID from ids.tsv for each anatomcial system to map organs below the hierarchical tree and get associated UBERON ids.
data/anatomical_systems_ids.tsv: curated/anatomical_systems/ids.tsv
	cut -f 1 curated/anatomical_systems/ids.tsv \
		| xargs src/hierarchical_descendants.sh \
		> data/anatomical_systems_ids.tsv

# annotating each UBERON ID from anatomical ids.tsv against anatomical_systems_ids.tsv and extra ids (atlas_extra_mappings.tsv) to map fields
# system id      system name     tissue id       tissue name
out/anatomical_systems.txt: curated/anatomical_systems/ids.tsv curated/anatomical_systems/atlas_extra_mappings.tsv curated/anatomical_systems/header.tsv data/anatomical_systems_ids.tsv
	amm -s src/Annotate.sc curated/anatomical_systems/ids.tsv data/anatomical_systems_ids.tsv \
	| cat - curated/anatomical_systems/atlas_extra_mappings.tsv \
	| sort -u \
	| cat curated/anatomical_systems/header.tsv - \
	> out/anatomical_systems.txt
	echo

# extracting mapped tissue ids from anatomical_systems.txt and sorting uniquely
data/anatomical_systems_mapped_ids.txt: out/anatomical_systems.txt
	cut -f 3 out/anatomical_systems.txt | sort -u > data/anatomical_systems_mapped_ids.txt

# filtering unmapped UBERON ids from ontology_ids_per_experiment-human-baseline.tsv that does not exist in anatomical_systems_mapped_ids.txt
out/curation/anatomical_systems_unmapped_ids.tsv: data/anatomical_systems_mapped_ids.txt out/ontology_ids_per_experiment-human-baseline.tsv
	grep -oe "UBERON.*" out/ontology_ids_per_experiment-human-baseline.tsv \
	| sort -k 1 \
	| join -t '	' -v 1 -1 1 -2 1 - data/anatomical_systems_mapped_ids.txt \
	> out/curation/anatomical_systems_unmapped_ids.tsv

### organs specific
### Keep it in sync with above! s/anatomical_systems/organs/g
data/organs_ids.tsv: curated/organs/ids.tsv
	cut -f 1 curated/organs/ids.tsv \
		| xargs src/hierarchical_descendants.sh \
		> data/organs_ids.tsv

out/organs.txt: curated/organs/ids.tsv curated/organs/atlas_extra_mappings.tsv curated/organs/header.tsv data/organs_ids.tsv
	amm -s src/Annotate.sc curated/organs/ids.tsv data/organs_ids.tsv > data/organs.txt.tmp
	cat curated/organs/atlas_extra_mappings.tsv >> data/organs.txt.tmp
	paste curated/organs/ids.tsv curated/organs/ids.tsv  >> data/organs.txt.tmp
	sort -u data/organs.txt.tmp \
		| cat curated/organs/header.tsv - \
		> out/organs.txt
	rm data/organs.txt.tmp

data/organs_mapped_ids.txt: out/organs.txt
	cut -f 3 out/organs.txt | sort -u > data/organs_mapped_ids.txt

out/curation/organs_unmapped_ids.tsv: data/organs_mapped_ids.txt out/ontology_ids_per_experiment-human-baseline.tsv
	grep -oe "UBERON.*" out/ontology_ids_per_experiment-human-baseline.tsv \
	| sort -k 1 \
	| join -t '	' -v 1 -1 1 -2 1 - data/organs_mapped_ids.txt \
	> out/curation/organs_unmapped_ids.tsv

#############################################################

### cell type mapping for anatomical systems and organs
# map public human expAcc ids with cell types and UERON-ID url from condensed.sdrf
data/all-cell-types-human-baseline.tsv: data/all-public-human-baseline-experiments.txt
	cat data/all-public-human-baseline-experiments.txt \
	| xargs -I {} grep "characteristic[[:space:]]cell type" "${ATLAS_EXPS}/{}/{}.condensed-sdrf.tsv" \
	| cut -f 1,6,7 \
	| sort -u \
	> data/all-cell-types-human-baseline.tsv

# all-cell-types-human-baseline.tsv is reordered to join by the ontology ids associated with cell types and associate experiement accession
out/celltype_ids_per_experiment-human-baseline.tsv: data/all-cell-types-human-baseline.tsv
	amm -s src/JoinByThirdColumn.sc data/all-cell-types-human-baseline.tsv \
		> out/celltype_ids_per_experiment-human-baseline.tsv


## anatomical systems specific
# anatomical_systems/ids.tsv is passed by the curator.
# hierarchical_ancestor script uses the UBERON ID from ids.tsv for each anatomcial system to map organs below the hierarchical tree and get associated UBERON ids.
data/celltypes_anatomical_systems_ids.tsv: curated/cell_types/ids.tsv
	cut -f 1 curated/cell_types/ids.tsv \
		| xargs src/hierarchical_ancestors.sh | grep "UBERON_*" | grep "system" | grep -v "anatomical system" \
		> data/celltypes_anatomical_systems_ids.tsv


# annotating each cell ID from ids.tsv against celltypes_anatomical_systems_ids.tsv and extra ids (atlas_extra_mappings.tsv) to map fields
# system id      system name     cell id       cell name
out/cell_anatomical_systems.txt: curated/cell_types/ids.tsv curated/cell_types/header1.tsv data/celltypes_anatomical_systems_ids.tsv
	amm -s src/Annotate.sc curated/cell_types/ids.tsv data/celltypes_anatomical_systems_ids.tsv \
		| sort -u | awk -F"\t" '{print $$3"\t"$$4"\t"$$1"\t"$$2}' \
		| cat curated/cell_types/header1.tsv - \
		> out/cell_anatomical_systems.txt

## extracting mapped cell ids to anatomical system
data/cell_anatomical_systems_mapped_ids.txt: out/cell_anatomical_systems.txt
	    cut -f 3 out/cell_anatomical_systems.txt i\
		| sort -u \
		> data/cell_anatomical_systems_mapped_ids.txt

# filtering unmapped UBERON ids from ontology_ids_per_experiment-human-baseline.tsv that does not exist in anatomical_systems_mapped_ids.txt
out/curation/cell_anatomical_systems_unmapped_ids.tsv: data/cell_anatomical_systems_mapped_ids.txt out/celltype_ids_per_experiment-human-baseline.tsv
	grep -oe "CL.*" out/celltype_ids_per_experiment-human-baseline.tsv \
		| sort -k 1 \
		| join -t '	' -v 1 -1 1 -2 1 - data/cell_anatomical_systems_mapped_ids.txt \
		> out/curation/cell_anatomical_systems_unmapped_ids.tsv

 ## organ specific mapping for cell types
data/celltypes_organs_ids.tsv: curated/cell_types/ids.tsv
	cut -f 1 curated/cell_types/ids.tsv \
		| xargs src/hierarchical_ancestors.sh | grep "UBERON_*" |  grep -v "organism\|structure\|entity\|anatomical" \
		> data/celltypes_organs_ids.tsv

# annotating each cell ID from ids.tsv against ccelltypes_organs_ids.tsv and if extra ids (atlas_extra_mappings.tsv) to map fields
# organ id      organ name     cell id       cell name
out/cell_organ.txt: curated/cell_types/ids.tsv curated/cell_types/header2.tsv data/celltypes_organs_ids.tsv
	amm -s src/Annotate.sc curated/cell_types/ids.tsv data/celltypes_organs_ids.tsv \
		| sort -u | awk -F"\t" '{print $$3"\t"$$4"\t"$$1"\t"$$2}' \
		| cat curated/cell_types/header2.tsv - \
		> out/cell_organ.txt

## extracting mapped cell ids to anatomical system
data/cell_organ_mapped_ids.txt: out/cell_organ.txt
	cut -f 3 out/cell_organ.txt \
		| sort -u \
		> data/cell_organ_mapped_ids.txt


out/curation/cell_organ_unmapped_ids.tsv: data/cell_organ_mapped_ids.txt out/celltype_ids_per_experiment-human-baseline.tsv
	grep -oe "CL.*" out/celltype_ids_per_experiment-human-baseline.tsv \
		| sort -k 1 \
		| join -t '	' -v 1 -1 1 -2 1 - data/cell_organ_mapped_ids.txt \
		> out/curation/cell_organ_unmapped_ids.tsv


.PHONY: clean all

clean:
	rm -rf data/*
	rm -rf out/*
	mkdir -p data
	mkdir -p out/curation
