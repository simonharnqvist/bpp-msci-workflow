configfile: "config.yaml"


rule all:
        input: "debug.txt"

rule make_temp_dir:
        output:
                temp(directory("temp"))
        shell:
                "mkdir -p {output}"

rule get_samples:
        params:
                imap=config["imap"]
        input:
                config["imap"]
        output:
                "temp/samples.txt"
        shell:
                """awk '{{print $1}}' {params.imap} > {output} """

rule rename_chromosomes_in_vcf:
        input:
                config["vcf"],
                config["fasta"]
        output:
                "temp/renamed.vcf.gz"
        conda:
                "env.yaml"
        shell:
                """
                grep ">" {input[1]} | sed 's/>//' | nl | awk '$1=$1' > temp/chr_names.txt
                bcftools annotate --rename-chrs temp/chr_names.txt {input[0]} | bgzip > {output}
                tabix {output}
                """

rule filter_vcf:
        input:
                "temp/samples.txt",
                "temp/renamed.vcf.gz"
        output:
                "temp/filtered.vcf"
        shell:
                """
                bcftools view --samples-file {input[0]} {input[1]} --min-alleles 2 --max-alleles 2 --force-samples -Oz > {output}
                """
                
rule prune_vcf_on_LD:
        input:
                "temp/filtered.vcf"
        output:
                "temp/pruned.vcf.gz"
        conda:
                "env.yaml"
        shell:
                """
                bcftools +prune -m 0.5 -w 10000 {input[0]} -Ov | bgzip > {output} # note use of old BCFtools; -l is now -m
                tabix {output}
                """

rule make_genome_file:
        input:
                config["fasta"]
        output:
                "temp/genome.txt"
        conda:
                "env.yaml"
        shell:
                r"cp {input} temp/fasta.fa; samtools faidx temp/fasta.fa; awk -v OFS='\t' {{'print $1,$2'}} temp/fasta.fa.fai > {output}"

rule generate_noncoding_bed:
        input:
                "temp/pruned.vcf.gz", "temp/genome.txt"
        output:
                "temp/noncoding.bed"
        conda:
                "env.yaml"
        shell:
                "bedtools complement -i {input[0]} -g {input[1]} > {output}"

rule generate_coding_bed:
        input:
                config["gff"]
        output:
                "temp/coding.bed"
        conda:
                "env.yaml"
        shell:
                """
        # awk '$3="CDS"' {input} | awk '{{print $1, $4, $5}}' | awk '!visited[$0]++' | sed '/^#/d' | sed '/ /\\t/g' > {output}
        bash scripts/generate_coding_bed.sh {input} > {output}
        """

rule select_random_regions:
        input:
                "temp/coding.bed",
                "temp/noncoding.bed"
        output:
                "temp/coding_selected_regions.bed",
                "temp/noncoding_selected_regions.bed"
        conda:
                "env.yaml"
        params:
                n_loci = config["number_of_loci"]
        shell:
                """
        bash scripts/makewindows.sh {input[0]} > {output[0]}
        bash scripts/makewindows.sh {input[1]} > {output[1]}
                """

rule generate_region_file:
    input:
        "temp/coding_selected_regions.bed", "temp/noncoding_selected_regions.bed"
    output:
        "temp/coding_regions.txt", "temp/noncoding_regions.txt"
    conda:
        "env.yaml"
    shell:
        """
                awk 'BEGIN{{OFS=":"}} {{print $1,$2,$3}}' {input[0]} | sed 's/:/-/2' | sed '/^#/d' > {output[0]}
                awk 'BEGIN{{OFS=":"}} {{print $1,$2,$3}}' {input[1]} | sed 's/:/-/2' | sed '/^#/d' > {output[1]}
                """

rule get_vcf_samples:
        input:
                "temp/pruned.vcf.gz"
        output:
                "temp/vcf_samples.txt"
        conda:
                "env.yaml"
        shell:
                """
                bcftools query -l {input} > {output}
        #comm -12 <(sort temp/vcf_samples_temp.txt) <(sort {input[0]}) > temp/vcf_samples.txt
                """

# This one should be several rules...
rule make_phylip:
        input:
                "temp/coding_regions.txt",
                "temp/noncoding_regions.txt",
                config["fasta"],
                "temp/pruned.vcf.gz",
                "temp/vcf_samples.txt"
        output:
                "coding_sequences.ph",
                "noncoding_sequences.ph"

        conda:
                "env.yaml"
        shell:
                """

                mkdir -p temp/sequences

                REGIONS=$(cat {input[0]} {input[1]})

                for region in ${{REGIONS}}
                do
                        for sample in $(cat {input[4]})
                        do
                                printf '>'$(echo ${{region}} | tr -s -c [:alnum:] _)'^'${{sample}} #header
                        samtools faidx {input[2]} ${{region}} | bcftools consensus -s ${{sample}} {input[3]}
                                printf '\\n'
                done | cut -f1,2 -d'>' | awk 'BEGIN {{RS = ">" ; FS = "\\n" ; ORS = ""}} $2 {{print ">"$0}}' > temp/sequences/${{region}}.txt
                done

                for region in ${{REGIONS}}
        do
            mafft --leavegappyregion --retree 2 --reorder temp/sequences/${{region}}.txt > temp/sequences/${{region}}_aligned.txt
            trimal -in temp/sequences/${{region}}_aligned.txt -out temp/sequences/${{region}}.ph -phylip_paml -gt 0.2
        done

                for region in $(cat {input[0]}) # coding
                do
                        FILE=temp/sequences/${{region}}.ph
                        if [ -f temp/sequences/${{region}}.ph ]
                        then
                                cat ${{FILE}}
                                printf '\\n'
                        fi
                done > {output[0]}

                for region in $(cat {input[1]}) # noncoding
        do
            FILE=temp/sequences/${{region}}.ph
            if [ -f temp/sequences/${{region}}.ph ]
            then
                cat ${{FILE}}
                printf '\\n'
            fi
        done > {output[1]}
                """

rule install_bpp:
        output:
                "bpp"
        shell:
                """
                wget https://github.com/bpp/bpp/releases/download/v4.4.1/bpp-4.4.1-linux-x86_64.tar.gz
                tar zxvf bpp-4.4.1-linux-x86_64.tar.gz
                rm bpp-4.4.1-linux-x86_64.tar.gz
                mv bpp-4.4.1-linux-x86_64/bin/bpp .
                """

rule make_tree:
        input:
                config["msci"],
                "bpp"
        output:
                "tree.txt"
        shell:
                """
                ./bpp --msci {input} | grep -A1 "Newick tree:" | grep -v "Newick tree:" > tree.txt
                """

rule generate_control_files:
        input:
                config["ctl_template"],
                config["imap"],
                "coding_sequences.ph",
                "noncoding_sequences.ph",
                "tree.txt"
        output:
                directory("control_files")
        conda:
                "env.yaml"
        shell:
                """
                mkdir -p control_files

                TREE=$(cat {input[4]})

                for SEQTYPE in "coding" "noncoding"
                do
                        END={config[number_of_repeats]}
                        for REP in $(seq 1 $END)
                        do
                                python scripts/generate_control_files.py --imap {config[imap]} \
                                --n_loci {config[number_of_loci]} --tree "${{TREE}}" \
                                        --theta_beta {config[theta_beta]} --tau_beta {config[tau_beta]} \
                                                --mcmc_samples {config[mcmc_samples]} --seqfile ${{SEQTYPE}}_sequences.ph \
                                                        --seqtype ${{SEQTYPE}} --rep ${{REP}} --ctl_template {config[ctl_template]} \
                                                                > control_files/${{SEQTYPE}}_${{REP}}.ctl
                        done
                done
                """

rule run_bpp:
        input:
                directory("control_files"),
                "bpp"
        output:
                "debug.txt"
        shell:
                """
                # Generate run scripts + submit to cluster
                for SEQTYPE in "coding" "noncoding"
                do
                        END={config[number_of_repeats]}
                        for REP in $(seq 1 $END)
                        do
                                RUNFILE=run_${{SEQTYPE}}_${{REP}}.sh
                                CTL_FILE=control_files/${{SEQTYPE}}_${{REP}}.ctl
                                cp config_files/run_bpp.sh ${{RUNFILE}}
                                sed -i "s/RUNNAME/${{SEQTYPE}}_${{REP}}/g" ${{RUNFILE}}
                                sed -i "s/EMAIL/{config[email]}/g" ${{RUNFILE}}
                                sed -i "s/ACCOUNT/{config[account]}/g" ${{RUNFILE}}
                                sed -i "s|CTL_FILE|${{CTL_FILE}}|g" ${{RUNFILE}}

                                bash ${{RUNFILE}}
                        done
                done

                echo 'Done' > debug.txt
                """
