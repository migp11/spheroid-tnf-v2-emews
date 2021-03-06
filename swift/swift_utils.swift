import string;
import python;


string summarize_sim = 
"""
import sys
import os
import json

params = json.loads('%s')
instance_folder = '%s'

params['initial_cell_count'] =  -1
params['final_cell_count'] = -1
fname = os.path.join(instance_folder, 'metrics.txt')
if os.path.exists(fname):
    file_lines = []
    with open(fname) as fh:
        lines = [i.rstrip() for i in fh.readlines()]

    params['initial_cell_count'] = lines[0].split("\t")[1]
    params['final_cell_count'] = lines[-1].split("\t")[1]
    
    run_info = instance_folder.rstrip("/")
    run_info = run_info.split("/")
    line_pieces = run_info[-1].split("_")
    print(line_pieces)
    if len(line_pieces) == 3:
        iteration, ind, rep = line_pieces[1:]
        params["individual"] = ind
        params["iteration"] = iteration
        params["replicate"] = rep
    elif len(line_pieces) == 2:
        ind, rep = line_pieces[1:]
        params["individual"] = ind
        params["replicate"] = rep
    else:
        print(f"Can't find {fname} file")
        sys.exit(1)

    fname = os.path.join(instance_folder, 'sim_summary.json')
    with open(fname, 'w') as fh:
        json.dump(params, fh)
else:
    print(f"Can't find {fname} file")
    sys.exit(1)
""";

(void v) results2json(string parameters, string instance_dir)
{
    string code_summarize = summarize_sim % (parameters, instance_dir);
    python_persist(code_summarize, "'ignore'") =>
    v = propagate();
}



string to_xml_code =
"""
import params2xml
import json

params = json.loads('%s')
print(params)
params['user_parameters.random_seed'] = '%s'

default_settings = '%s'
xml_out = '%s'

params2xml.params_to_xml(params, default_settings, xml_out)
print(f'saving params to {xml_out}')
""";

(void v) params2xml(string parameters, int seed, string default_settings, string instance_settings)
{
    string code = to_xml_code % (parameters, seed, default_settings, instance_settings);
    python_persist(code, "'ignore'") =>
    v = propagate();
}