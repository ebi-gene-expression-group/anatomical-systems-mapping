all: out/ontology_ids_per_experiment.tsv out/anatomical_systems.txt

data/all-organism-parts.tsv:
	find -L "${ATLAS_EXPS}" -maxdepth 2 -name '*condensed-sdrf.tsv' \
		| xargs -n 1 grep "factor[[:space:]]organism part" \
		| cut -f 1,6,7 | sort -u > data/all-organism-parts.tsv

out/ontology_ids_per_experiment.tsv: data/all-organism-parts.tsv
	amm -s src/JoinByThirdColumn.sc data/all-organism-parts.tsv \
		> out/ontology_ids_per_experiment.tsv

data/anatomical_systems_ids.tsv: curated/anatomical_systems/atlas_systems.tsv
	cut -f 1 curated/anatomical_systems/atlas_systems.tsv \
		| xargs src/hierarchical_descendants.sh \
		> data/anatomical_systems_ids.tsv

out/anatomical_systems.txt: curated/anatomical_systems/atlas_systems.tsv curated/anatomical_systems/atlas_extra_mappings.tsv curated/anatomical_systems/header.tsv data/anatomical_systems_ids.tsv
	amm -s src/Annotate.sc curated/anatomical_systems/atlas_systems.tsv data/anatomical_systems_ids.tsv \
	| cat - curated/anatomical_systems/atlas_extra_mappings.tsv \
	| sort -u \
	| cat curated/anatomical_systems/header.tsv - \
	> out/anatomical_systems.txt
	echo

.PHONY: clean all

clean:
	rm data/*
	rm out/*
