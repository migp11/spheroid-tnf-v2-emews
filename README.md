# Optimizing dosage-specific treatments in a multi-scale model of a tumor growth

Ponce-de-Leon M, Montagud M, Akasiadis C, Schreiber J, Ntiniakou T and Valencia A
 

----------------
## Abstract
The emergence of cell resistance in cancer treatment is a complex phenomenon that emerges from the interplay of processes that occur at different scales. For instance, molecular mechanisms and population-level dynamics such as competition and cell-cell variability have been described as playing a key role in the emergence and evolution of cell resistances. Multi-scale models are a useful tool to study biology at a very different time and spatial scales, as they can integrate different processes that take place at the molecular, cellular and intercellular levels. In the present work, we use an extended hybrid multi-scale model of 3T3 fibroblast spheroid to perform a deep exploration of the parameter space of effective treatment strategies based on TNF pulses. To explore the parameter space of effective treatments in different scenarios and conditions, we have developed an HPC-optimized model exploration workflow based on EMEWS.  We first studied the effect of the cells spatial distribution in the values of the treatment parameters by optimizing the supply strategies in 2D monolayers and 3D spheroids of different sizes. We later study the robustness of the effective treatments when heterogeneous populations of cells are considered. We found that our model exploration workflow can find effective treatments in all the studied conditions. Our results show that cells' spatial geometry, as well as, population variability should be considered when optimizing treatment strategies in order to find robust parameter sets.

----------------

## EMEWS Workflow for model exploration of treatment strategies

This repository contains the code for the multi-scale model and the EMEWS-based model exploration exploration  workflow

Note: This project is compatible with swift-t v. 1.3+. Earlier versions will NOT work.

The project consists of the following directories:

```
spheroid-tnf-v2-emews/
  data/
  etc/
  experiments
  ext/
  python/
    test/
  R/
    test/
  scripts/
  swift/
  README.md
```
The directories are intended to contain the following:

 - `data` - model inputs including PhysiBoSS XML config files, and JSON parameter templates
 - `etc` - additional code used by EMEWS
 - `ext` - swift-t extensions such as eqpy, eqr
 - `python` - python code (e.g. model exploration algorithms written in python)
 - `python/test` - tests of the python code
 - `scripts` - any necessary scripts (e.g. scripts to launch a model), excluding scripts used to run the workflow.
 - `swift` - this folder includes the swift code with the model exploration workflows together with shell scripts to run the workflows

## Running in-silico experiments

### How to run the sweep

`Usage: run_sweep.sh EXPERIMENT_ID INPUT SETTINGS_XML (e.g. run_sweep.sh exp_1 data/input.txt data/settings_template_3D.xml)`

This shell scripts is a wrapper to lunch the model exploration workflow based on the sweep search (`swift_run_sweep.swift`)

Sweep experiments require three parameters.:

 - `EXPERIMENT_ID`: this is the name of the folder where the results will be stored `experiments/EXPERIMENT_ID`
 - `INPUT`: is a txt file where each line correspond to a JSON dictionary where the keys must be a correct path to a model parameter in the XML config file: 
^
    <br>
    `{ "user_parameters.duration_add_tnf": 5.2, "user_parameters.concentration_tnf": 0.14, "user_parameters.time_add_tnf": 420.0}`
    <br>
    where the key `user_parameters.duration_add_tnf` corresponds to a path in the xml config file.

 - `SETTINGS_XML`: A PhysiBoSS XML configuration file. See `settings_template_2D.xml` or `settings_template_3D.xml` for examples of 2D and 3D model layouts, respectively.

The sweep will iterate over all the provided parameters and run the simulation distributed according to the resources assigned in the `run_sweep.sh`:

 - `PROCS=48`: is the total number of CPUs assigned to the job.
 - `PPN=12`: the total number of siulation per computing node. Since PhysiBoSS is configured to use 4 threads (see settings_template_3D.xml) and each MN4 has 48 cpu, we can allocate 12 PhysiBoSS instances in each ode

### How to run GA/CMA-ES

`Usage: run_eqpy.sh EXPERIMENT_ID EA_PARAMS_FILE (e.g. run_eqpy.sh experiment_1 data/ga_params.json)`

 - `EXPERIMENT_ID`: this is the name of the folder where the results will be stored `experiments/EXPERIMENT_ID`
 - `EA_PARAMS_FILE`: is a json file containing the parameters or decision variable to optimize. It also includes the sigma for the sampling and bounds for the values.

This shell scripts is a wrapper to lunch the model exploration workflow based on evolutionary algorithms (`swift_run_eqpy.swift`)

Parameter regarding the population size, number of iterations (generations), replicates and population size should be modified inside `run_eqpy.sh`

- `SEED=1234`: the seed to initialize the random number generator
- `ITER=15`: the number of iterations (generations)
- `REP=3`: the total number of replicate for each evaluation
- `POP=100`: the population size (number of individuals)
- `SIGMA=1`: SIGMA is only used if the strategy used is the CMA
- `STRATEGY=[CMA|GA]`: evolutionary strategy to use

In the case of the GA the default parameters for the `mutation` and `crossover` are `0.2` and `0.5`, respectively. To change those values or other 
parameters of the GA the user should modify the file `python/deap_ga.py`

In the case of the CMA-ES user should modify the file `python/deap_cma.py` to change parameter such as centroids of the initial population.s

## The model

Here we present a multi-scale model of tumor growth that considers at the individual cell level the dynamics 
of the tumor necrosis factor (TNF) receptor and its downstream effect using a hybrid approach.

The model definition including all the submodel parameters can be found in the `data/settings_template_2D.xml` and `data/settings_template_3D.xml` files

The Boolean model is provided in MaBoSS format:

- `data/boolean_network/TNF_conf.cfg`: MaBoSS configuration file 
- `data/boolean_network/TNF_nodes.bnd`: MaBoSS network definitions file

![Alt text](data/figs/TNF_model.png)
<br>
**Figure 1.** Diagram representing the intracellular submodels of the multi-scale model of a tumor growth.
<br>

## Citation

- Ponce-de-Leon et al. **"Optimizing dosage-specific treatments in a multi-scale model of a tumor growth"**. Frontiers in Molecular Bioscience (2022) 10.3389/fmolb.2022.836794

