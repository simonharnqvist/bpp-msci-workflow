#!/bin/bash

# By Mike Renfro; stolen from from https://github.com/bpp/bpp/issues/155
_fix_bpp_threads() {
	#1 Control file
  	BPP_CPUSET=$(sed 's/,/ /g' /sys/fs/cgroup/cpuset/slurm/uid_$(id -u)/job_${SLURM_JOBID}/cpuset.cpus)

  	BPP_START=$(( $(echo $BPP_CPUSET | awk '{print $1}') + 1 ))
  	BPP_STEP=$(( $(echo $BPP_CPUSET | awk '{print $2}') - $(echo $BPP_CPUSET | awk '{print $1}') ))
  	BPP_COUNT=${SLURM_CPUS_PER_TASK}

  	THREAD_SEARCH='^\s*threads\s*=\s*[[:digit:]]+\s*[[:digit:]]+\s*[[:digit:]]+'
  	THREAD_REPLACE="threads = ${BPP_COUNT} ${BPP_START} ${BPP_STEP}"

  	perl -pi.bak -e "s/${THREAD_SEARCH}/${THREAD_REPLACE}/g" ${1}
}

