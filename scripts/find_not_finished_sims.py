import os
import glob
import json
import xml.etree.ElementTree as ET




def main():
    
    params = ["user_parameters.time_add_tnf", "user_parameters.duration_add_tnf", "user_parameters.concentration_tnf"]
    project_root = "./"
    exp_base_folder = os.path.join(project_root, "experiments")
    xml_base_fname = "settings.xml"
    exp_id = "drug_policy_sweep_n40_3"
    sweep_params_fname = "experiments/drug_policy_sweep_n40_3/drug_policy_sweep_n40_2_resume.txt"
    
    exp_base_folder = os.path.join(exp_base_folder, exp_id)
    finished_sims = {}
    finished_fname = exp_id + "_finished_sims.json"
    finished_fname = os.path.join(exp_base_folder, finished_fname)
    if os.path.exists(finished_fname):
        with open(finished_fname, "w") as fh:
            finished_sims = json.load(fh)
    else:
        print("Begining the XML processing")
        globing = os.path.join(exp_base_folder, "instance_*")
        for i in glob.glob(globing):
            err_fname = os.path.join(i, "err.txt")
            if not os.path.exists(err_fname):
                continue
            if os.stat(err_fname).st_size > 0:
                continue

            xml_fname = os.path.join(i, xml_base_fname)
            root = ET.parse(xml_fname)
            values = []
            for p in params:
                xpath = p.replace(".", "/")
                el = root.find("./{}".format(xpath))
                values.append(el.text)

            strn_hash = " ".join(values)
            finished_sims[strn_hash] = 1
        
        with open(finished_fname, "w") as fh:
            json.dump(finished_sims, fh)
    
    print("Processing XML files done!")
    print("Found %i finished simulations" % len(finished_sims))
    pending_sims = []
    with open(sweep_params_fname, "r") as fh:
        for i in fh:
            d = json.loads(i)
            values = [str(d[p]) for p in params]
            strn_hash = " ".join(values)
            if strn_hash not in finished_sims:
                pending_sims.append(i)
                
    pending_sims_fname = exp_id + "_resume.txt"
    pending_sims_fname = os.path.join(exp_base_folder, pending_sims_fname)
    print("Total remining simulations: %i" % len(pending_sims))
    with open(pending_sims_fname, 'w') as fh:
        fh.writelines(pending_sims)
    
main()
    
