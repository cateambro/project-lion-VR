process BlastComparison {
        cpus 8
        memory '16 GB'

        publishDir 'results', mode: 'copy'

        input:
        tuple val(id), path(query), path(db_files)

        output:
        tuple val(id), path("${id}_comparison")

        script:
        def db_name = db_files.find { it.name.endsWith('.ndb') }.name.replaceAll('\\.ndb$', '')
        """
        mkdir -p results
        blastn -db ${db_name} -query ${query} -num_threads 8 -outfmt 6 -min_raw_gapped_score 10000 -out ${id}_comparison
        """
        }
