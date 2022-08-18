seed =  SEED

       seqfile = SEQFILE
      Imapfile = IMAP
       outfile = RUNNAME_out.txt
      mcmcfile = RUNNAME_mcmc.txt

  speciesdelimitation = 0

  species&tree = SPECIES_LINE
                                 N_SAMPLES_PER_SPECIES
                 TREE

       usedata = 1
         nloci = N_LOCI

     cleandata = 0

    thetaprior = 3 THETA_BETA E
      tauprior = invgamma 3 TAU_BETA
    phiprior = 1 1

      finetune =  1: .01 .02 .03 .04 .05 .01 .01

         print = 1 0 0 0
        burnin = BURNIN
      sampfreq = 2
       nsample = MCMC_SAMPLES
