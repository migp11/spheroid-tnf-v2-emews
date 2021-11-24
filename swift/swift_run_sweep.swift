import io;
import sys;
import files;
import string;
import python;

import swift_utils;


string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");


string count_template =
"""
import get_metrics
instance_dir = '%s'
count = get_metrics.get_tumor_cell_count(instance_dir)
""";

string find_min =
"""
v <- c(%s)
res <- which(v == min(v))
""";

app (file out, file err) run_model (file shfile, string executable, string param_line, string instance)
{
    "bash" shfile executable param_line emews_root instance @stdout=out @stderr=err;
}

app (void o) summarize_simulation (file summarize_py, string instance_dir) {
    "python" summarize_py instance_dir;
}

(string result) get_result(string instance_dir) {
  // Use a few lines of R code to read the output file
  // See the read_last_row variable above
  string code = count_template % instance_dir;
  result = python_persist(code, "str(count)");
}

app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}

app (void o) make_output_dir(string instance) {
  "mkdir" "-p" (instance+"/output");
}

// deletes the specified directory
app (void o) rm_dir(string dirname) {
  "rm" "-rf" dirname;
}

main() {

  string executable = argv("exe");
  string default_xml = argv("settings");
  int num_variations = toint(argv("nv", "3"));

  file model_sh = input(emews_root + "/scripts/growth_model.sh");
  file upf = input(argv("parameters"));
  file summarize_py = input(emews_root + "/scripts/summarize_simulation.py");

  string results[];
  string upf_lines[] = file_lines(upf);
  foreach params,i in upf_lines {
    foreach replication in [0:num_variations-1:1] {
      string instance_dir = "%s/instance_%i_%i/" % (turbine_output, i+1, replication+1);
      make_dir(instance_dir) => {        
        file out <instance_dir+"out.txt">;
        file err <instance_dir+"err.txt">;
        string instance_settings = instance_dir + "settings.xml" =>
        params2xml(params, i+replication, default_xml, instance_settings) =>
        (out,err) = run_model(model_sh, executable, instance_settings, instance_dir) => {
          results[replication] = get_result(instance_dir) =>
          results2json(params, instance_dir) =>
          summarize_simulation(summarize_py, instance_dir) =>
          rm_dir(instance_dir + "output/");
        }
      }
    }
  }
}
