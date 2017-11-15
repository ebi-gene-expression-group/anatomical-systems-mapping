all: out/ontology_ids_per_experiment.tsv out/ontology_ids_per_experiment-human-baseline.tsv out/anatomical_systems.txt out/curation/anatomical_systems_unmapped_ids.tsv out/organs.txt out/curation/organs_unmapped_ids.tsv

data/all-organism-parts.tsv.unsorted:
	find -L "${ATLAS_EXPS}" -maxdepth 2 -name '*condensed-sdrf.tsv' \
		| xargs -n 1 grep "factor[[:space:]]organism part" \
		| cut -f 1,6,7 > data/all-organism-parts.tsv.unsorted
		
data/all-organism-parts.tsv: data/all-organism-parts.tsv.unsorted
		 sort -u data/all-organism-parts.tsv.unsorted -o data/all-organism-parts.tsv

out/ontology_ids_per_experiment.tsv: data/all-organism-parts.tsv
	amm -s src/JoinByThirdColumn.sc data/all-organism-parts.tsv \
		> out/ontology_ids_per_experiment.tsv

data/all-public-human-baseline-experiments.txt:
	curl 'https://www.ebi.ac.uk/gxa/json/experiments' \
		| jq -r '.aaData | map(select(.species | contains ("sapiens")) | select(.experimentType | contains("BASELINE")) | .experimentAccession)[]' \
		| sort \
		> data/all-public-human-baseline-experiments.txt

data/all-organism-parts-human-baseline.tsv: data/all-organism-parts.tsv data/all-public-human-baseline-experiments.txt
	join -o '1.1 1.2 1.3' -t '	' -1 1 -2 1 data/all-organism-parts.tsv data/all-public-human-baseline-experiments.txt \
	> data/all-organism-parts-human-baseline.tsv

out/ontology_ids_per_experiment-human-baseline.tsv: data/all-organism-parts-human-baseline.tsv
	amm -s src/JoinByThirdColumn.sc data/all-organism-parts-human-baseline.tsv \
		> out/ontology_ids_per_experiment-human-baseline.tsv

### anatomical systems specific
data/anatomical_systems_ids.tsv: curated/anatomical_systems/ids.tsv
	cut -f 1 curated/anatomical_systems/ids.tsv \
		| xargs src/hierarchical_descendants.sh \
		> data/anatomical_systems_ids.tsv

out/anatomical_systems.txt: curated/anatomical_systems/ids.tsv curated/anatomical_systems/atlas_extra_mappings.tsv curated/anatomical_systems/header.tsv data/anatomical_systems_ids.tsv
	amm -s src/Annotate.sc curated/anatomical_systems/ids.tsv data/anatomical_systems_ids.tsv \
	| cat - curated/anatomical_systems/atlas_extra_mappings.tsv \
	| sort -u \
	| cat curated/anatomical_systems/header.tsv - \
	> out/anatomical_systems.txt
	echo

data/anatomical_systems_mapped_ids.txt: out/anatomical_systems.txt
	cut -f 3 out/anatomical_systems.txt | sort -u > data/anatomical_systems_mapped_ids.txt

out/curation/anatomical_systems_unmapped_ids.tsv: data/anatomical_systems_mapped_ids.txt out/ontology_ids_per_experiment-human-baseline.tsv
	grep -oe "UBERON.*" out/ontology_ids_per_experiment-human-baseline.tsv \
	| sort -k 1 \
	| join -t '	' -v 1 -1 1 -2 1 - data/anatomical_systems_mapped_ids.txt \
	> out/curation/anatomical_systems_unmapped_ids.tsv


### s/anatomical_systems/organs/g
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

.PHONY: clean all

clean:
	rm -rf data/*
	git checkout data
	rm -rf out/*
	mkdir out/curation
