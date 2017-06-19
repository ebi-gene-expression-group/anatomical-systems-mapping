
data/all-organism-parts.tsv:
	find -L "${ATLAS_EXPS}" -maxdepth 2 -name '*condensed-sdrf.tsv' \
		| xargs -n 1 grep "factor[[:space:]]organism part" \
		| cut -f 1,6,7 | sort -u > data/all-organism-parts.tsv

out/ontology-ids-per-experiment.tsv: data/all-organism-parts.tsv
	amm -s src/JoinByThirdColumn.sc data/all-organism-parts.tsv > out/ontology-ids-per-experiment.tsv

.PHONY: clean

clean:
	rm data/*
	rm out/*

all: out/ontology-ids-per-experiment.tsv
