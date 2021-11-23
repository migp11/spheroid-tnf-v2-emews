#!/usr/bin/env python

import sys
import os
import json


def main():
    instance_folder  = sys.argv[1]
    params = {}
    fname = os.path.join(instance_folder, 'sim_summary.json')
    with open(fname, 'r') as fh:
        params = json.load(fh)

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
    
    print(json.dumps(params))

main()
