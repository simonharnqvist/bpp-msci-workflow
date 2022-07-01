import pandas as pd
import fileinput
import random
import argparse

def generate_control_file(ctl_template, imap, n_loci, tree, theta_beta, tau_beta, mcmc_samples, seqfile, seqtype, rep):

    imap_df = pd.read_csv(imap, sep = " ")
    populations = list(imap_df.iloc[:,1].unique())

    n_samples_per_species = str(round(int(n_loci)/len(populations)))
    list_of_n_samples = [n_samples_per_species] * len(populations)
    n_samples = " ".join(list_of_n_samples)

    replacements = {
        "RUNNAME":f"{seqtype}_{rep}",
        "IMAP": imap,
        "SEED":random.randint(1,10000),
        "SEQFILE":seqfile,
        "SPECIES_LINE":str(len(populations)) + " " + ' '.join(populations),
        "N_SAMPLES_PER_SPECIES": n_samples,
        "TREE":tree,
        "N_LOCI":n_loci,
        "THETA_BETA":theta_beta,
        "TAU_BETA":tau_beta,
        "MCMC_SAMPLES":mcmc_samples,
        "BURNIN":str(round(int(mcmc_samples) * 0.1))
        }
    
    with open (ctl_template, "r") as f:
        data = f.read()
        for key, replacement in replacements.items():
            data = data.replace(key, str(replacement))
    print(data)

parser = argparse.ArgumentParser()
parser.add_argument("--imap")
parser.add_argument("--n_loci")
parser.add_argument("--tree")
parser.add_argument("--theta_beta")
parser.add_argument("--tau_beta")
parser.add_argument("--mcmc_samples")
parser.add_argument("--seqfile")
parser.add_argument("--seqtype")
parser.add_argument("--rep")
parser.add_argument("--ctl_template")
args = parser.parse_args()


if __name__ == "__main__":
    generate_control_file(
        ctl_template = args.ctl_template, imap = args.imap, n_loci = args.n_loci,
        tree = args.tree, theta_beta = args.theta_beta,
        tau_beta = args.tau_beta, mcmc_samples = args.mcmc_samples,
        seqfile = args.seqfile, seqtype = args.seqtype, rep = args.rep)


