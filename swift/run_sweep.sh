#! /usr/bin/env bash

set -eu

if [ "$#" -ne 3 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID INPUT SETTINGS_XML (e.g. ${script_name} exp_1 data/input.txt data/settings_template_3D.xml)"
  exit 1
fi


# uncomment to turn on swift/t logging. Can also set TURBINE_LOG,
# TURBINE_DEBUG, and ADLB_DEBUG to 0 to turn off logging
# export TURBINE_LOG=1 TURBINE_DEBUG=1 ADLB_DEBUG=1
export EMEWS_PROJECT_ROOT=$( cd $( dirname $0 )/.. ; /bin/pwd )
# source some utility functions used by EMEWS in this script
source "${EMEWS_PROJECT_ROOT}/etc/emews_utils.sh"

export EXPID=$1
export TURBINE_OUTPUT=$EMEWS_PROJECT_ROOT/experiments/$EXPID
check_directory_exists

# TODO edit the number of processes as required.
# export PROCS=720
export PROCS=48

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if the MACHINE variable (see below) is not set.
export QUEUE=main
export WALLTIME=36:00:00
#export WALLTIME=1:59:00
export PPN=12
export TURBINE_JOBNAME="${EXPID}_job"

# Extra argument passed to SLURM script
# options debug, bsc_ls
#export TURBINE_SBATCH_ARGS=--qos=bsc_ls
#export TURBINE_SBATCH_ARGS=--qos=debug

# if R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib
# if python packages can't be found, then uncommited and set this
# export PYTHONPATH=/path/to/python/packages
export PYTHONPATH=$PYTHONPATH:$EMEWS_PROJECT_ROOT/python


# TODO edit command line arguments as appropriate
# for your run. Note that the default $* will pass all of this script's
# command line arguments to the swift script.
mkdir -p $TURBINE_OUTPUT

PARAMS_FILE_SOURCE=`realpath $2`
SETTINGS_SOURCE=`realpath $3`
# SETTINGS_SOURCE=$EMEWS_PROJECT_ROOT/data/settings_template_3D.xml
EXE_SOURCE=$EMEWS_PROJECT_ROOT/model/tnf-cancer-model

EXE_OUT=$TURBINE_OUTPUT/`basename $EXE_SOURCE`
SETTINGS_OUT=$TURBINE_OUTPUT/settings.xml
PARAMS_FILE_OUT=$TURBINE_OUTPUT/`basename $PARAMS_FILE_SOURCE`

cp $EXE_SOURCE $EXE_OUT
cp $SETTINGS_SOURCE $SETTINGS_OUT
cp $PARAMS_FILE_SOURCE $PARAMS_FILE_OUT

cp -r $EMEWS_PROJECT_ROOT/data/boolean_network $TURBINE_OUTPUT

REP=3

CMD_LINE_ARGS="$* -nv=$REP -exe=$EXE_OUT -settings=$SETTINGS_OUT -parameters=$PARAMS_FILE_OUT"

# set machine to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE="slurm"
# MACHINE=""

if [ -n "$MACHINE" ]; then
  MACHINE="-m $MACHINE"
fi

# Add any script variables that you want to log as
# part of the experiment meta data to the USER_VARS array,
# for example, USER_VARS=("VAR_1" "VAR_2")
USER_VARS=()
# log variables and script to to TURBINE_OUTPUT directory
log_script

module load python java R/3.4.0 swiftt/1.4.3

# echo's anything following this standard out
set -x
SWIFT_FILE=swift_run_sweep.swift
swift-t -n $PROCS $MACHINE -p -I $EMEWS_PROJECT_ROOT/swift/ $EMEWS_PROJECT_ROOT/swift/$SWIFT_FILE $CMD_LINE_ARGS
