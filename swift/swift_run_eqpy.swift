import files;
import string;
import sys;
import io;
import stats;
import python;
import math;
import location;
import assert;

import swift_utils;
import EQPy;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");





string result_template =
"""
import statistics

x = '%s'.split(',')
x = [float(xx) for xx in x]

if len(x) > 0:
  res = statistics.mean(x)
else: 
  res = 9999999999
""";


string count_template =
"""
import get_metrics
instance_dir = '%s'
count = get_metrics.get_tumor_cell_count(instance_dir)
""";
(string result) get_result(string instance_dir) {
  // Use a few lines of R code to read the output file
  // See the read_last_row variable above
  string code = count_template % instance_dir;
  result = python_persist(code, "str(count)");
}

app (file out, file err) run_model (string model_sh, string executable_path, string settings_file, string instance)
{
    "bash" model_sh executable_path settings_file emews_root instance @stdout=out @stderr=err;
}

app (void o) summarize_simulation (file summarize_py, string instance_dir) {
    "python" summarize_py instance_dir;
}

// deletes the specified directory
app (void o) rm_dir(string dirname) {
  "rm" "-rf" dirname;
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}



(string result) run_obj(string custom_parameters, int algo_iteration, int parameter_iteration, int num_replications, string executable, string default_settings)
{
    string model_sh = emews_root + "/scripts/growth_model.sh";
    file summarize_py = input(emews_root + "/scripts/summarize_simulation.py");
    string cell_counts[];
    foreach replication in [0:num_replications-1:1] {
      string instance_dir = "%s/instance_%i_%i_%i/" % (turbine_output, algo_iteration, parameter_iteration, replication+1);
      make_dir(instance_dir) => {
        
        
        file out <instance_dir + "out.txt">;
        file err <instance_dir + "err.txt">;
        
        // replication iteration used as a seed
        params2xml(custom_parameters, replication, default_settings, instance_dir) =>
        (out,err) = run_model(model_sh, executable, instance_settings, instance_dir) => {
          cell_counts[replication] = get_result(instance_dir);
          results2json(custom_parameters, instance_dir) =>
          summarize_simulation(summarize_py, instance_dir) =>
          rm_dir(instance_dir + "output/");
        }
      }
    }
    string cell_counts_string = string_join(cell_counts, ",");
    string code = result_template % cell_counts_string;
    result = python_persist(code, "str(res)");
}

(void v) loop (location ME, int trials, string executable_model, string settings) {
    for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    // gets the model parameters from the python algorithm
    string params =  EQPy_get(ME);
    boolean c;
    // TODO
    // Edit the finished flag, if necessary.
    // when the python algorithm is finished it should
    // pass "DONE" into the queue, and then the
    // final set of parameters. If your python algorithm
    // passes something else then change "DONE" to that
    if (params == "DONE")
    {
        string finals =  EQPy_get(ME);
        // TODO if appropriate
        // split finals string and join with "\\n"
        // e.g. finals is a ";" separated string and we want each
        // element on its own line:
        // multi_line_finals = join(split(finals, ";"), "\\n");
        string fname = "%s/final_result" % (turbine_output);
        file results_file <fname> = write(finals) =>
        printf("Writing final result to %s", fname) =>
        // printf("Results: %s", finals) =>
        v = make_void() =>
        c = false;
    }
    else if (params == "EQPY_ABORT")
    {
        printf("EQPy Aborted");
        string why = EQPy_get(ME);
        // TODO handle the abort if necessary
        // e.g. write intermediate results ...
        printf("%s", why) =>
        v = propagate() =>
        c = false;
    }
    else
    {
        string param_array[] = split(params, ";");
        string results[];
        foreach parameter, parameter_iteration in param_array
        {
            results[parameter_iteration] = run_obj(parameter, i, parameter_iteration, trials, executable_model, settings);
        }
        string result = join(results, ";");
        //printf("passing %s", res);
        EQPy_put(ME, result) => c = true;
    }
  }
}


(void o) start (int ME_rank, string package, string algo_params, int num_variations, string executable_model, string settings) {
    location ME = locationFromRank(ME_rank);
    
    EQPy_init_package(ME, package) =>
    EQPy_get(ME) =>
    EQPy_put(ME, algo_params) =>
      loop(ME, num_variations, executable_model, settings) => {
        EQPy_stop(ME);
        o = propagate();
    }
}


main() {

  string executable = argv("exe");
  string settings = argv("settings");
  int random_seed = toint(argv("seed", "0"));
  int num_variations = toint(argv("nv", "3"));
  int num_iterations = toint(argv("ni","10"));
  int num_population = toint(argv("np", "5"));
  float sigma = tofloat(argv("sigma", "1.0"));
  string ea_parameters_file = argv("ea_params");
  string strategy = argv("strategy");
  
  string package;
  string algo_params;
  if (strategy == "CMA")
  { 
    package = "deap_cmaes";
    algo_params = "%d,%d,%f,%d,'%s'" %  (num_iterations, num_population, sigma, random_seed, ea_parameters_file);
  }
  else if (strategy == "GA")
  { 
    package = "deap_ga";
    algo_params = "%d,%d,%d,'%s'" %  (num_iterations, num_population, random_seed, ea_parameters_file);
  }
  else 
  { 
    package = ""; 
    algo_params = "";
  }

  assert(strlen(package)>0, "ERROR: strategy parameter should be either GA/CMA");
  assert(strlen(algo_params)>0, "ERROR: algo_params could not be correctly defined");
  assert(file_exists(executable), "ERROR: executable model %s cannot be found" % executable);
  assert(file_exists(settings), "ERROR: setting file %s cannot be found" % settings);
  assert(strlen(getenv("PYTHONPATH")) > 0, "Set PYTHONPATH!");
  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  printf("Running EMEWS");
  printf("- Using %s (%s) with parameters %s" % (strategy, package, algo_params));
  printf("- Running model %s using template config %s" % (executable, settings));

  int rank = string2int(r_ranks[0]);
  start(rank, package, algo_params, num_variations, executable, settings);
}
