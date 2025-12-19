process BlastDB {
        cpus 8
        memory '16 GB'

        input:
        tuple val(id), path(fasta)

        output:
        tuple val(id), path("${id}.db/*"), emit: dbfiles

        script:
        """
        mkdir ${id}.db
        makeblastdb -in ${fasta} -input_type fasta -dbtype nucl -out ${id}.db/${id}_db
        """
        }
