nextflow.enable.dsl=2

process OverlapAnalysis {
        tag "{comparison_id}"
        publishDir "${params.outdir}/overlap_analysis", mode: 'copy'

        input:
        tuple val(comparison_id), path(blast_file), path(query_fasta), path(subject_fasta)

        output:
        tuple val(comparison_id), path("${comparison_id}.overlap.tsv")

        script:
        """
        python3 $projectDir/python_analysis.py $blast_file $query_fasta $subject_fasta > ${comparison_id}.overlap.tsv
        """
}
