import string;
import python;


string summarize_sim = 
"""
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

    line_pieces = instance_folder.split("_")
    if len(line_pieces)>3:
        iteration, ind, rep = line_pieces[1:]
        params["individual"] = ind
        params["iteration"] = iteration
        params["replicate"] = rep
    else:
        ind, rep = line_pieces[1:]
        params["individual"] = ind
        params["replicate"] = rep

fname = os.path.join(instance_folder, 'sim_summary.json')
with open(fname, 'w') as fh:
    json.dump(params, fh)
""";
(void o) results2json(string parameters, string instance_dir)
{
    string code_summarize = summarize_sim % (parameters, instance_dir);
    python_persist(code_summarize, "'ignore'")
}



string to_xml_code =
"""
import params2xml
import json

params = json.loads('%s')
params['user_parameters.random_seed'] = '%s'

default_settings = '%s'
xml_out = '%s'

params2xml.params_to_xml(params, default_settings, xml_out)
""";

(void o) params2xml(string parameters, int replication, string default_settings, string instance_dir){
    string instance_settings = instance_dir + "settings.xml";
    string code = to_xml_code % (parameters, replication, default_settings, instance_settings);
    python_persist(code, "'ignore'")
}