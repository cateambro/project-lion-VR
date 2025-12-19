#!/usr/bin/env nextflow

params.input = "/dataA/lion/ONT/fq"
params.sr_input = "/dataA/lion/short-reads/"
params.output_qc = "work/qc"
params.quality = 13
params.output_assembly = "work/flye_output"
params.output_spades = "work/spades_output"
params.output_opera = "work/opera_output"

process qc {
    input:
    tuple val(name), path(long_reads)

    output:
    tuple val(name), path("qc/${long_reads.baseName}_clean.fq.gz"), emit: clean_lr

    script:
    """
    mkdir -p qc
    fastplong -i ${long_reads} \
              -q 0 \
              -u 0 \
              -m ${params.quality} \
              -o qc/${long_reads.baseName}_clean.fq.gz
    """
}

process qc_sr {
    input:
    tuple val(id), path(read1), path(read2)

    output:
    tuple val(id), path("qc/${id}_R1_clean.fastq.gz"), path("qc/${id}_R2_clean.fastq.gz"), emit: clean_sr

    script:
    """
    mkdir -p qc
    fastp -i ${read1} -I ${read2} \
          -q 20 \
          -o qc/${id}_R1_clean.fastq.gz \
          -O qc/${id}_R2_clean.fastq.gz
    """
}

process assembleFlye {
        cpus 18
        memory '95G'

        input:
        tuple val(name), path(long_reads)

        output:
        tuple val(name), path("flye/${name}_assembly"), emit: assembly_flye

        script:
        """
        mkdir -p flye/${name}_assembly
        flye --nano-raw ${long_reads} \
             --out-dir flye/${name}_assembly \
             --threads ${task.cpus}
        """
}

process assembleSpades {
    cpus 18
    memory '90G'

    input:
    tuple val(sample_id), path(long_reads), path(short_reads_R1), path(short_reads_R2)

    output:
    tuple val(sample_id), path("spades/${sample_id}_assembly"), emit: assembly_spades

    script:
    """
    mkdir -p spades/${sample_id}_assembly
    spades.py --nanopore ${long_reads} \
              --pe1-1 ${short_reads_R1} \
              --pe1-2 ${short_reads_R2} \
              --meta \
              -o spades/${sample_id}_assembly \
              --threads ${task.cpus}
    """
}

process assembleOperaMS{
        cpus 24
        memory '80G'

        input:
        tuple val(sample_id), path(long_reads), path(short_reads_R1), path(short_reads_R2)

        output:
        tuple val(sample_id), path("opera/${sample_id}_assembly"), emit: opera_assembly

        errorStrategy 'finish'

        script:
        """
        mkdir -p opera/${sample_id}_assembly
        gunzip -c ${long_reads} > ${sample_id}_long.fq

        OPERA-MS.pl --short-read1 ${short_reads_R1} \
                    --short-read2 ${short_reads_R2} \
                    --long-read ${sample_id}_long.fq \
                    --out-dir opera/${sample_id}_assembly \
                    --num-processors ${task.cpus} \
                    --no-ref-clustering
        """
}

workflow {
         Channel.fromPath("${params.lr_input}/*.fq.gz")\
                .map { fname -> [fname.simpleName, fname] }\
                .set { long_reads }

        Channel.fromFilePairs("${params.sr_input}/*{R1,R2}*.fastq.gz")\
            { fname -> fname.name.replaceAll("_.*","") }\
            .map { elt -> [elt[0], elt[1][0], elt[1][1]] }\
            .set { short_reads }

     qc(long_reads).set { qc_results }
     qc_sr(short_reads).set { qc_sr_results }
     qc_results.clean_lr.join(qc_sr_results.clean_sr).set { combined_reads }

     assembleFlye(qc_results.clean_lr).set{assembly_flye}
     assembleSpades(combined_reads).set{assembly_spades}


}
