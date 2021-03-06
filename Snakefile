from GetSequences import get_sequences
configfile: "config.yaml"

files=get_sequences(config['seqfile'])

rule all:
    input:
        expand("BAM/{sample}.sort.bam", sample=files.keys()),
        expand("BAM/{sample}.sort.bam.bai", sample=files.keys())

rule hisat:
    input:
        reads = lambda wildcards: files[wildcards.sample]
    output:
        temp("BAM/{sample}.bam")
    params:
        input1 = lambda wildcards: ','.join(files[wildcards.sample][::2]),
        input2 = lambda wildcards: ','.join(files[wildcards.sample][1::2]),        
        idx = config['reference']['index'],
        extra = '--known-splicesite-infile ' + config['reference']['splice_sites'],
        threads = 8
    benchmark:
        "Benchmarks/{sample}.hisat.benchmark.txt"
    log:
        "Logs/{sample}_hisat_map.txt"
    shell:
        "(hisat2 {params.extra} --threads {params.threads}"
        " -x {params.idx} -1 {params.input1} -2 {params.input2}"
        " | samtools view -Sbh -o {output} -)"
        " 2> {log}"


rule sort_bam:
    input:
        rules.hisat.output
    output:
        "BAM/{sample}.sort.bam"
    params:
        "-m 4G"
    threads: 8
    wrapper:
        "0.17.4/bio/samtools/sort"
        
rule samtools_index:
    input:
        rules.sort_bam.output
    output:
        "BAM/{sample}.sort.bam.bai"
    wrapper:
        "0.17.4/bio/samtools/index"

