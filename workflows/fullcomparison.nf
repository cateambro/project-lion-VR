#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.opera = "/home/cambrosi/opera"
params.flye = "/home/cambrosi/flye"
params.spades = "/home/cambrosi/spades"
params.outdir = "results"

include { BlastDB as BlastDB_opera } from './modules/blastdb'
include { BlastDB as BlastDB_flye } from './modules/blastdb'
include { BlastDB as BlastDB_spades } from './modules/blastdb'
include { BlastComparison as Compare_opera_flye } from './modules/blastcomparison'
include { BlastComparison as Compare_opera_spades } from './modules/blastcomparison'
include { BlastComparison as Compare_flye_spades } from './modules/blastcomparison'
include { OverlapAnalysis as OverlapAnalysis_opera_flye } from './modules/overlapanalysis'
include { OverlapAnalysis as OverlapAnalysis_opera_spades } from './modules/overlapanalysis'
include { OverlapAnalysis as OverlapAnalysis_flye_spades } from './modules/overlapanalysis'

workflow{
Channel.fromPath("${params.opera}/*/opera/*_assembly/contigs.polished.fasta")
        .map { f -> [f.parent.parent.parent.name, f ] }
        .set { opera_ch }
Channel.fromPath("${params.flye}/*/assembly.fasta")
        .map { f -> [ f.parent.name, f ] }
        .set { flye_ch }
Channel.fromPath("${params.spades}/*")
        .map { f -> [ f.simpleName.replace('.fasta', ''), f ] }
        .set { spades_ch }

opera_ch
        .join(flye_ch)
        .join(spades_ch)
        .set { contigs }
BlastDB_opera(contigs.map { id, opera_file, flye_file, spades_file -> tuple("${id}_opera", opera_file) })
BlastDB_flye(contigs.map { id, opera_file, flye_file, spades_file -> tuple("${id}_flye", flye_file) })
BlastDB_spades(contigs.map { id, opera_file, flye_file, spades_file -> tuple("${id}_spades", spades_file) })

contigs.map { id, opera_file, flye_file, spades_file ->
        tuple("${id}_flye", "${id}_opera_vs_flye", opera_file)
}.join(BlastDB_flye.out.dbfiles)
.map { db_id, comparison_id, query_file, db_files ->
        tuple(comparison_id, query_file, db_files)
}.set { opera_flye_input }

contigs.map { id, opera_file, flye_file, spades_file ->
        tuple("${id}_spades", "${id}_opera_vs_spades", opera_file)
}.join(BlastDB_spades.out.dbfiles)
.map { db_id, comparison_id, query_file, db_files ->
        tuple(comparison_id, query_file, db_files)
}.set { opera_spades_input }

contigs.map { id, opera_file, flye_file, spades_file ->
        tuple("${id}_spades", "${id}_flye_vs_spades", flye_file)
}.join(BlastDB_spades.out.dbfiles)
.map { db_id, comparison_id, query_file, db_files ->
        tuple(comparison_id, query_file, db_files)
}.set { flye_spades_input }

Compare_opera_flye(opera_flye_input)
Compare_opera_spades(opera_spades_input)
Compare_flye_spades(flye_spades_input)

Compare_opera_flye.out
        .join(contigs.map { id, opera_file, flye_file, spades_file ->
              tuple("${id}_opera_vs_flye", opera_file, flye_file)
        })
        .map { comparison_id, blast_file, query_fasta, subject_fasta ->
             tuple(comparison_id, blast_file, query_fasta, subject_fasta)
        }
        .set { opera_flye_overlap_input }

Compare_opera_spades.out
        .join(contigs.map { id, opera_file, flye_file, spades_file ->
              tuple("${id}_opera_vs_spades", opera_file, spades_file)
        })
        .map { comparison_id, blast_file, query_fasta, subject_fasta ->
              tuple(comparison_id, blast_file, query_fasta, subject_fasta)
        }
        .set { opera_spades_overlap_input }

Compare_flye_spades.out
        .join(contigs.map { id, opera_file, flye_file, spades_file ->
              tuple("${id}_flye_vs_spades", flye_file, spades_file)
        })
        .map { comparison_id, blast_file, query_fasta, subject_fasta ->
        tuple(comparison_id, blast_file, query_fasta, subject_fasta)
        }
        .set { flye_spades_overlap_input }

OverlapAnalysis_opera_flye(opera_flye_overlap_input)
OverlapAnalysis_opera_spades(opera_spades_overlap_input)
OverlapAnalysis_flye_spades(flye_spades_overlap_input)
emit:
        opera_vs_flye_results = Compare_opera_flye.out
        opera_vs_spades_results = Compare_opera_spades.out
        flye_vs_spades_results = Compare_flye_spades.out
        all_comparison_results =Compare_opera_flye.out
                               .mix(Compare_opera_spades.out)
                               .mix(Compare_flye_spades.out)
        overlap_opera_flye_results = OverlapAnalysis_opera_flye.out
        overlap_opera_spades_results = OverlapAnalysis_opera_spades.out
        overlap_flye_spades_results = OverlapAnalysis_flye_spades.out
        All_overlap_results = OverlapAnalysis_opera_flye.out
                              .mix(OverlapAnalysis_opera_spades.out)
                              .mix(OverlapAnalysis_flye_spades.out)
}
