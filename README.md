# bpp-msci-workflow
A Snakemake workflow for the MSCi framework in BP&amp;P

## Description ##
BP&P is a software for demographic analyses enabling studies of (among many other things) introgression. While highly useful, it can be challening to use. The hope is that this workflow will simplify the use of BP&P for introgression analyses.

It should be emphasised that this project is completely unaffiliated with BP&P and its development team. 

## Prerequisites ##
This workflow requires Snakemake as well as mamba. Please see their respective websites to install them. In spite of what mamba maintainers warn, I've found that mamba can be installed safely in a conda environment other than base.

## 1. Set parameters in config.yaml ##
Config.yaml is the main method of controlling the pipeline. It takes the following parameters:
```
imap: "config_files/Imap"
vcf: "config_files/file.vcf
fasta: "config_files/reference.fa"
gff: "config_files/reference.gff"
regions: "all" # please ignore - this feature isn't working yet
number_of_loci: 1000
ctl_template: "config_files/template.ctl"
theta_beta: 0.0005
tau_beta: 0.02
mcmc_samples: 1000
number_of_repeats: 3
msci: "config_files/msci.txt"
email: "email@domain.com"
account: "HPC user account/group" # if not applicable, you'll need to delete the SBATCH command in config_files/run_bpp.sh
```

It is assumed that have a VCF, a reference fasta, and a GFF file for your organism(s) of interest. If you are interested in a particular region, or regions, you could easily subset the VCF with bcftools or similar and run the pipeline on those subsets.

The other files and parameters are less standard:

#### Imap ####
The Imap file is simply a tab-delimited file of samples (must match VCF) and their population/species assignment:
```
IndA  SpeciesA
IndB  SpeciesB
IndC  SpeciesC
```

#### Control file ####
BP&P settings are controlled using a control file. The pipeline generates appropriate control files automatically, using data from config.yaml. You should however check the resulting control files to ensure that parameters are appropriate for your analysis; I have chosen default values for some of them. Please refer to the BP&P manual for guidance on parameter choices.

#### Theta and tau beta values ####
This sets the beta value for the theta and tau priors - alpha is set as 3 by default (but you can change this in template.ctl). 

#### MCMC samples ####

#### Number of repeats ####
This sets how many repeats you want per analysis. Each repeat is performed with a new seed but with the same dataset.

#### MSCi ####
To run the introgression analysis, you need to specify the model you are interested in running. This is set in `msci.txt`, which looks something like this:
```
```

For more details on how to set up the `msci.txt` file, please see 

#### Email and account ####
These are passed to Slurm. If you are not on a Slurm based system, you'll have to edit the scripts to make it work. Sorry.

## 2. Run pipeline ##
Once everything is set up, you can run the pipeline with: </br>
`snakemake -c1 --use-conda`

## 3. Analyse results ##
BP&P will output files called things like coding_1_out.txt in the working directory.



