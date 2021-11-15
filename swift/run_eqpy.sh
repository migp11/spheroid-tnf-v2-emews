#! /usr/bin/env bash

set -eu

if [ "$#" -ne 2 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} EXPERIMENT_ID EA_PARAMS_FILE (e.g. ${script_name} experiment_1 data/ga_params.json)"
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
export PROCS=60

# TODO edit QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME
# as required. Note that QUEUE, WALLTIME, PPN, AND TURNBINE_JOBNAME will
# be ignored if MACHINE flag (see below) is not set
export QUEUE=main
export WALLTIME=24:00:00
export PPN=12
export TURBINE_JOBNAME="${EXPID}_job"

# Extra argument passed to SLURM script
# export TURBINE_SBATCH_ARGS=--qos=debug

# if R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib
# export PYTHONHOME=/path/to/python
export PYTHONPATH=$EMEWS_PROJECT_ROOT/python:$EMEWS_PROJECT_ROOT/ext/EQ-Py

# Resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# EQ/Py location
EQPY=$EMEWS_PROJECT_ROOT/ext/EQ-Py

# TODO edit command line arguments, e.g. -nv etc., as appropriate
# for your EQ/Py based run. $* will pass all of this script's
# command line arguments to the swift script
mkdir -p $TURBINE_OUTPUT

ALGO_PARAMS_FILE_SOURCE=$2
EXE_SOURCE=$EMEWS_PROJECT_ROOT/model/tnf-cancer-model
SETTINGS_SOURCE=$EMEWS_PROJECT_ROOT/data/settings_template_2D.xml

EXE_OUT=$TURBINE_OUTPUT/`basename $EXE_SOURCE`
SETTINGS_OUT=$TURBINE_OUTPUT/settings.xml
ALGO_PARAMS_FILE_OUT=$TURBINE_OUTPUT/`basename $2`

cp $EXE_SOURCE $EXE_OUT
cp $SETTINGS_SOURCE $SETTINGS_OUT
cp $ALGO_PARAMS_FILE_SOURCE $ALGO_PARAMS_FILE_OUT

cp -r $EMEWS_PROJECT_ROOT/data/boolean_network $TURBINE_OUTPUT

SEED=1234
ITER=15
REP=3
POP=100
SIGMA=1

#STRATEGY="CMA"

STRATEGY="GA"


CMD_LINE_ARGS="$* -strategy=$STRATEGY -sigma=$SIGMA -seed=$SEED -ni=$ITER -nv=$REP -np=$POP -exe=$EXE_OUT -settings=$SETTINGS_OUT -ea_params=$ALGO_PARAMS_FILE_OUT"

# Uncomment this for the BG/Q:
#export MODE=BGQ QUEUE=default

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

# echo's anything following this to standard out
set -x
SWIFT_FILE=swift_run_eqpy.swift
swift-t -n $PROCS $MACHINE -p -I $EQPY -r $EQPY $EMEWS_PROJECT_ROOT/swift/$SWIFT_FILE $CMD_LINE_ARGS
