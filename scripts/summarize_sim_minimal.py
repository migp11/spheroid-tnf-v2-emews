import sys
import os
import json
import xml.dom.minidom


def main():
    instance_folder  = sys.argv[1]

    params = {}
    line_pieces = instance_folder.split("_")
    iteration, ind, rep = line_pieces[1:]
    
    params["individual"] = ind
    params["iteration"] = iteration
    params["replicate"] = rep

    doc = xml.dom.minidom.parse(os.path.join(instance_folder,"settings.xml"))
    
    list_of_params = ["time_add_tnf", "duration_add_tnf", "concentration_tnf"]
    for i in list_of_params:
        custom_data = doc.getElementsByTagName(i)
        node = custom_data[0]
        value = round(float(node.firstChild.nodeValue), 4)
        params["user_parameters." + node.nodeName] = value
    
    params['initial_cell_count'] =  -1
    params['final_cell_count'] = -1
    fname = os.path.join(instance_folder, 'metrics.txt')
    if os.path.exists(fname):
        file_lines = []
        with open(fname) as fh:
            lines = [i.rstrip() for i in fh.readlines()]

        params['initial_cell_count'] = lines[0].split("\t")[1]
        params['final_cell_count'] = lines[-1].split("\t")[1]

    fname = os.path.join(instance_folder, 'sim_summary.json')
    print(json.dumps(params))
    # ~ with open(fname, 'w') as fh:
        # ~ json.dump(params, fh)

main()
