"""
Requires condensed SDRFs, available at different experiment folders, usually in $ATLAS_EXP (passed though config 'atlas_exp').
The experiments need to be according to the atlas instance used (so if using wwwdev it will expect as many accessions as available there).
"""

def get_all_outputs():
    return ['out/ontology_ids_per_experiment-human-baseline.tsv',
             'out/anatomical_systems.txt', 'out/curation/anatomical_systems_unmapped_ids.tsv',
             'out/organs.txt', 'out/curation/organs_unmapped_ids.tsv',
             'out/celltype_ids_per_experiment-human-baseline.tsv', 
             'out/cell_anatomical_systems.txt', 
             'out/curation/cell_anatomical_systems_unmapped_ids.tsv',
             'out/cell_organ.txt', 'out/curation/cell_organ_unmapped_ids.tsv']

rule all: 
    input: get_all_outputs()
    
rule public_human_baseline_experiments:
    output: "data/all-public-human-baseline-experiments.txt"
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    log: "public_human_baseline_experiments.log"
    shell:
        """
        mkdir -p $( dirname {output} )
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        curl 'https://wwwdev.ebi.ac.uk/gxa/json/experiments' \
            | jq -r '.experiments | map(select(.species | contains ("sapiens")) | select(.experimentType | contains("Baseline")) | .experimentAccession)[]' \
            | sort \
                > {output}
        """

rule organism_parts_human_baseline:
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    input: "data/all-public-human-baseline-experiments.txt"
    output: "data/all-organism-parts-human-baseline.tsv"
    params:
        atlas_exps=config['atlas_exps']
    log: "organism_parts_human_baseline.log"
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        cat {input} \
            | parallel --joblog missing_studies_{log} \
            grep "factor[[:space:]]organism part" "{params.atlas_exps}/{{}}/{{}}.condensed-sdrf.tsv" \
            | cut -f 1,6,7 \
            | sort -u \
                > {output}
        """

rule ontology_ids_per_experiment_human_baseline:
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    input: "data/all-organism-parts-human-baseline.tsv"
    output: "out/ontology_ids_per_experiment-human-baseline.tsv"
    log: "ontology_ids_per_experiment_human_baseline.log"
    shell:
        """
        mkdir -p $( dirname {output} )
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        amm -s {workflow.basedir}/src/JoinByThirdColumn.sc {input} > {output}
        """ 

rule anatomical_systems:
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    input: 
        curated_ids="curated/anatomical_systems/ids.tsv",
        curated_extra_mappings="curated/anatomical_systems/atlas_extra_mappings.tsv",
        curated_anatomical_headers="curated/anatomical_systems/header.tsv",
        ontology_ids_per_experiment="out/ontology_ids_per_experiment-human-baseline.tsv"
    output: 
        anatomical_systems="out/anatomical_systems.txt",
        mapped_anatomical_systems="data/anatomical_systems_mapped_ids.txt",
        for_curation_unmapped="out/curation/anatomical_systems_unmapped_ids.tsv"
    log: "anatomical_systems.log"
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        echo "Getting IDs..."
        cut -f 1 {input.curated_ids} \
            | parallel --joblog missing_ids_{log} {workflow.basedir}/src/hierarchical_descendants.sh \
            > data/anatomical_systems_ids.tsv
        echo "Running amm to get anatomical systems..."
        amm -s src/Annotate.sc {input.curated_ids} data/anatomical_systems_ids.tsv \
            | cat - {input.curated_extra_mappings} \
            | sort -u \
            | cat {input.curated_anatomical_headers} - \
            > {output.anatomical_systems}
        echo "Getting mapped anatomica systems..."    
        cut -f 3 {output.anatomical_systems} | sort -u > {output.mapped_anatomical_systems}
        echo "Getting unmapped anatomica systems..."
        grep -oe "UBERON.*" {input.ontology_ids_per_experiment} \
            | sort -k 1 \
            | join -t '	' -v 1 -1 1 -2 1 - {output.mapped_anatomical_systems} \
            > {output.for_curation_unmapped}
        """

rule organs:
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    log: "organs.log"
    input: 
        curated_organ_ids="curated/organs/ids.tsv",
        curated_organ_headers="curated/organs/header.tsv",
        ontology_ids_per_experiment="out/ontology_ids_per_experiment-human-baseline.tsv"
    output:
        organs="out/organs.txt",
        mapped_organs="data/organs_mapped_ids.txt",
        for_curation_unmapped="out/curation/organs_unmapped_ids.tsv"
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        echo "Getting organ_ids..."
        cut -f 1 {input.curated_organ_ids} \
            | parallel --joblog missing_ids_{log} {workflow.basedir}/src/hierarchical_descendants.sh \
            > data/organs_ids.tsv
        echo "Running amm to get tmp organs..."
        amm -s src/Annotate.sc {input.curated_organ_ids} data/organs_ids.tsv > data/organs.txt.tmp
        echo "Appending more to tmp organs..."
        cat curated/organs/atlas_extra_mappings.tsv >> data/organs.txt.tmp
        paste {input.curated_organ_ids} {input.curated_organ_ids}  >> data/organs.txt.tmp
        echo "Producing organs file..."
        sort -u data/organs.txt.tmp \
            | cat  {input.curated_organ_headers} - \
            > {output.organs}
        rm data/organs.txt.tmp
        # mapped
        echo "Producing organs mapped file..."
        cut -f 3 {output.organs} | sort -u > {output.mapped_organs}
        # unmapped
        echo "Producing organs unmapped file..."
        grep -oe "UBERON.*" {input.ontology_ids_per_experiment} \
            | sort -k 1 \
            | join -t '	' -v 1 -1 1 -2 1 - data/organs_mapped_ids.txt \
            > {output.for_curation_unmapped}
        """

rule cell_types_human_baseline:
    log: "cell_types_human_baseline.log"
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    input: "data/all-public-human-baseline-experiments.txt"
    output: 
        cell_types_human_baseline="data/all-cell-types-human-baseline.tsv",
        cell_types_ids_per_exp_human_baseline="out/celltype_ids_per_experiment-human-baseline.tsv"
    params:
        atlas_exps=config['atlas_exps']
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        echo "Producing cell types for human baseline..."
        cat {input} \
            | parallel --joblog missing_experiments_{log} grep "characteristic[[:space:]]cell type" "{params.atlas_exps}/{{}}/{{}}.condensed-sdrf.tsv" \
            | cut -f 1,6,7 \
            | sort -u \
            > {output.cell_types_human_baseline}
        echo "Producing cell types ids for human baseline..."
        amm -s {workflow.basedir}/src/JoinByThirdColumn.sc {output.cell_types_human_baseline} \
            > {output.cell_types_ids_per_exp_human_baseline}
        """ 

rule cell_types_anatomical_systems:
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    log: "cell_types_anatomical_systems.log"
    input: 
        curated_cell_type_ids="curated/cell_types/ids.tsv",
        curated_cell_type_headers="curated/cell_types/header1.tsv",
        cell_types_ids_per_exp_human_baseline="out/celltype_ids_per_experiment-human-baseline.tsv"
    output: 
        cell_anatomical_systems="out/cell_anatomical_systems.txt",
        cell_anatomical_systems_mapped="data/cell_anatomical_systems_mapped_ids.txt",
        cell_anatomical_systems_unmapped="out/curation/cell_anatomical_systems_unmapped_ids.tsv"
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        echo "Data for cell anatomical systems"
        cut -f 1 {input.curated_cell_type_ids} \
            | parallel --joblog missing_ids_{log} {workflow.basedir}/src/hierarchical_ancestors.sh | grep "UBERON_*" | grep "system" | grep -v "anatomical system" \
            > data/celltypes_anatomical_systems_ids.tsv
        echo "Producing cell anatomical systems"    
        amm -s src/Annotate.sc {input.curated_cell_type_ids} data/celltypes_anatomical_systems_ids.tsv \
            | sort -u | awk -F"\t" '{{print $$3"\t"$$4"\t"$$1"\t"$$2}}' \
            | cat {input.curated_cell_type_headers} - \
            > {output.cell_anatomical_systems}
        echo "Producing mapped cell anatomical systenms"
        cut -f 3 {output.cell_anatomical_systems} \
            | sort -u \
            > {output.cell_anatomical_systems_mapped}
        echo "Producing unmapped cell anatomical systenms"
        grep -oe "CL.*" {input.cell_types_ids_per_exp_human_baseline} \
            | sort -k 1 \
            | join -t '	' -v 1 -1 1 -2 1 - {output.cell_anatomical_systems_mapped} \
            > {output.cell_anatomical_systems_unmapped}
        """ 

rule cell_type_organs:
    log: "cell_type_organs.txt"
    container: "docker://quay.io/ebigxa/atlas-metadata-base:1.0.1"
    input: 
        curated_cell_type_ids="curated/cell_types/ids.tsv",
        curated_cell_type_headers2="curated/cell_types/header2.tsv",
        cell_types_ids_per_exp_human_baseline="out/celltype_ids_per_experiment-human-baseline.tsv"
    output: 
        cell_organs="out/cell_organ.txt",
        cell_organs_unmapped="out/curation/cell_organ_unmapped_ids.tsv"
    shell:
        """
        set -e # snakemake on the cluster doesn't stop on error when --keep-going is set
        exec &> "{log}"
        echo "Data for cell type organs"
        cut -f 1 {input.curated_cell_type_ids} \
            | parallel --joblog missing_studies_{log} {workflow.basedir}/src/hierarchical_ancestors.sh | grep "UBERON_*" |  grep -v "organism\|structure\|entity\|anatomical" \
            > data/celltypes_organs_ids.tsv
        echo "Producing cell type organs"
        amm -s src/Annotate.sc {input.curated_cell_type_ids} data/celltypes_organs_ids.tsv \
            | sort -u | awk -F"\t" '{{print $$3"\t"$$4"\t"$$1"\t"$$2}}' \
            | cat {input.curated_cell_type_headers2} - \
            > {output.cell_organs}
        echo "Producing mapped cell type organs"
        cut -f 3 {output.cell_organs} \
            | sort -u \
            > data/cell_organ_mapped_ids.txt
        echo "Producing unmapped cell type organs"
        grep -oe "CL.*" {input.cell_types_ids_per_exp_human_baseline} \
            | sort -k 1 \
            | join -t '	' -v 1 -1 1 -2 1 - data/cell_organ_mapped_ids.txt \
            > {output.cell_organs_unmapped}
        """ 


