import os
import numpy as np


def get_tumor_cell_count(instance_dir):
    """
    @return tumor cell count value from fname or -2, if file doesn't exist, or
    -1 if run terminated prematurely.
    """
    tumor_cell_count = 'NaN'
    fname = '{}/metrics.txt'.format(instance_dir)
    if os.path.exists(fname):
        file_lines = []
        with open(fname) as fh:
            lines = [i.rstrip() for i in fh.readlines()]
         
        row = lines[-1].split("\t")
        tumor_cell_count = row[1]

    return tumor_cell_count


