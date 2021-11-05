#!/usr/bin/env python
# coding: utf-8

import re
import os
import sys
import numpy as np
import pandas as pd
import xml.dom.minidom
import matplotlib.pyplot as plt
from multicellds import MultiCellDS

pd.options.mode.chained_assignment = None


def get_timeserie_mean(mcds, filter_alive=True):
    time = []
    values = []
    filter_alive = True
    for t, df in mcds.cells_as_frames_iterator():
        time.append(t)
        df = df.iloc[:,3:]
        if filter_alive:
            mask = df['current_phase'] <= 14
            df = df[mask]
        values.append(df.mean(axis=0).values)

    cell_columns = df.columns.tolist()
    df = pd.DataFrame(values, columns=cell_columns)
    df['time'] = time
    return df[['time'] + cell_columns]


def get_timeserie_density(mcds, density_id, density_name='density', agg='sum'):
    data = []
    for t,m in mcds.microenvironment_as_matrix_iterator():
        value = -1
        if agg == 'sum':
            value = m[4 + density_id,:].sum()
        if agg == 'mean':
            value = m[4 + density_id,:].mean()
        data.append((t, value))
    df = pd.DataFrame(data=data, columns=['time', density_name])
    return df

def plot_molecular_model(df_cell_variables, list_of_variables, ax, threshold=0.5):
    for label in list_of_variables:
        y = df_cell_variables[label]
        time = df_cell_variables["time"]
        ax.plot(time, y, label="% X " + label)

    ax.set_ylabel("% X")
    ax.yaxis.grid(True)
    ax.set_xlim((0,time.values[-1]))
    ax.set_ylim((0,1.05))
    
    
def plot_cells(df_time_course, color_dict, ax):

    # Alive/Apoptotic/Necrotic vs Time
    for k in color_dict:
        ax.plot(df_time_course.time, df_time_course[k], "-", c=color_dict[k], label=k)
    
    # setting axes labels
    # ax.set_xlabel("time (min)")
    ax.set_ylabel("Nº of cells")
    
    # Showing legend
    ax.legend()
    ax.yaxis.grid(True)

def main():
    color_dict = {"alive": "g", "apoptotic": "r", "necrotic":"k"}

    
    output_folder  = sys.argv[1]
    
    doc = xml.dom.minidom.parse(os.path.join(output_folder,"settings.xml"))
    
    
    custom_data = doc.getElementsByTagName("TNFR_receptors_per_cell")
    total_receptor = float(custom_data[0].firstChild.nodeValue)
    
    custom_data = doc.getElementsByTagName("time_add_tnf")
    k1 = round(float(custom_data[0].firstChild.nodeValue), 4)
    custom_data = doc.getElementsByTagName("duration_add_tnf")
    k2 = round(float(custom_data[0].firstChild.nodeValue), 4)
    custom_data = doc.getElementsByTagName("concentration_tnf")
    k3 = round(float(custom_data[0].firstChild.nodeValue), 4)

    

    print("Processing output folder %s" % output_folder)
    mcds = MultiCellDS(output_folder=output_folder)
    

    df_time_course = mcds.get_cells_summary_frame()
    df_cell_variables = get_timeserie_mean(mcds, filter_alive=True)
    

    density_id = 1
    density_name, density_units  = mcds.microenvironment_columns[density_id][:2]
    agg_density = 'mean'
    df_time_tnf = get_timeserie_density(mcds, density_id, density_name=density_name, agg=agg_density)
    max_tnf = df_time_tnf[density_name].max() * 1.05
    

    df_time_course.to_csv(os.path.join(output_folder, "time_course.tsv"), sep="\t")
    df_cell_variables.to_csv(os.path.join(output_folder, "cell_variables.tsv"), sep="\t")
    
    
    
    df_time_tnf.to_csv(os.path.join(output_folder, "tnf_time.tsv"), sep="\t")

    fig, axes = plt.subplots(3, 1, figsize=(12,12), dpi=150, sharex=True, sharey=False)
    
    fig.suptitle('Pulse period: %.4f, Pulse duration: %.4f, [TNF]: %.4f' % (k1,k2,k3) )
    
    plot_cells(df_time_course, color_dict, axes[0])
    
    list_of_variables = ['bound_external_TNFR', 'unbound_external_TNFR', 'bound_internal_TNFR']
    
    df_cell_variables[list_of_variables] = df_cell_variables[list_of_variables] / total_receptor

    plot_molecular_model(df_cell_variables, list_of_variables, axes[1])
    threshold = 0.5
    
    axes[1].hlines(threshold, 0, df_time_course.time.iloc[-1], label="Activation threshold")
    ax2 = axes[1].twinx()
    ax2.plot(df_time_tnf.time, df_time_tnf['tnf'], 'r', label="[TNF]")
    ax2.set_ylabel("[TNF]")
    ax2.set_ylim([0, max_tnf])
    axes[1].legend(loc="upper left")
    ax2.legend(loc="upper right")

    list_of_variables = ['tnf_node', 'nfkb_node', 'fadd_node']
    plot_molecular_model(df_cell_variables, list_of_variables, axes[2])
    axes[2].set_xlabel("time (min)")
    ax2 = axes[2].twinx()
    ax2.plot(df_time_tnf.time, df_time_tnf['tnf'], 'r', label="[TNF]")
    ax2.set_ylabel("[TNF]")
    ax2.set_ylim([0, max_tnf])
    axes[2].legend(loc="upper left")
    ax2.legend(loc="upper right")
    

    fig.tight_layout()
    fig.savefig(os.path.join(output_folder, 'variables_vs_time.png'))
    


main()
