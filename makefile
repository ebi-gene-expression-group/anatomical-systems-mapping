
out/all-organism-parts.tsv:
	find -L "${ATLAS_EXPS}" -maxdepth 2 -name '*condensed-sdrf.tsv' \
		| xargs -n 1 grep "factor[[:space:]]organism part" \
		| cut -f 1,6,7 | sort -u > out/all-organism-parts.tsv

out/ontology-ids-per-experiment.tsv: out/all-organism-parts.tsv
	amm -s src/JoinByThirdColumn.sc out/all-organism-parts.tsv > out/ontology-ids-per-experiment.tsv

.PHONY: clean

clean:
	rm out/*

all: out/all-organism-parts.tsv out/ontology-ids-per-experiment.tsv
