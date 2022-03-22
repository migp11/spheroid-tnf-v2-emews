import sys
import os
import json
import xml.dom.minidom


def main():
    instance_folder  = sys.argv[1]
    if len(sys.argv) == 3:
        noise_param = sys.argv[2]
    else:
        noise_param = None
    params = {}
    line_pieces = instance_folder.split("_")

    if len(line_pieces) == 3: 
        iteration, rep = line_pieces[1:]
        params["iteration"] = iteration
        params["replicate"] = rep
    elif len(line_pieces) == 4: 
        iteration, ind, rep = line_pieces[1:]
        params["individual"] = ind
        params["iteration"] = iteration
        params["replicate"] = rep

    doc = xml.dom.minidom.parse(os.path.join(instance_folder,"settings.xml"))
    
    list_of_params = ["time_add_tnf", "duration_add_tnf", "concentration_tnf"]
    if noise_param:
        list_of_params.append(noise_param)
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
