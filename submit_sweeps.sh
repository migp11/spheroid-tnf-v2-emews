LAYOUTS=("2D" "3D")
EXP_LIST=("bind" "endo" "recy")
for i in ${LAYOUTS[@]}
do
    XML="data/settings_template_${i}.xml"
    for j in ${EXP_LIST[@]}
    do
        EXP_ID="sweep_test_top30_with_${j}_noise_${i}"
        INPUT="data/$EXP_ID.txt"
        bash swift/run_sweep.sh $EXP_ID $INPUT $XML
    done
done
