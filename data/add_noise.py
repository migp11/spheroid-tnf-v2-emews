import sys
import json
import pandas as pd
import numpy as np
def main():

    csv_fname  = sys.argv[1]
    df = pd.read_csv(csv_fname, sep="\t", index_col=0)
    cols_rename = {i:f"user_parameters.{i}" for i in df.columns}
    df = df.rename(cols_rename, axis=1)
    new_params = ["TNFR_binding_rate_std", "TNFR_endocytosis_rate_std", "TNFR_recycling_rate_std"]
    for x in np.arange(0,1.1, 0.1):
        for i in new_params:
            df[f"user_parameters.{i}"] = x
        for d in df.to_dict('records'):
            print(json.dumps(d))

main()
