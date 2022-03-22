
B="user_parameters.TNFR_binding_rate_std"
E="user_parameters.TNFR_endocytosis_rate_std"
R="user_parameters.TNFR_recycling_rate_std"
LAYOUTS=("2D" "3D")
for i in ${LAYOUTS[@]}
do
    F="sweep_test_top30_with_noise_${i}.txt"
    sed 's/\("'${E}'":\) [0-1].[0-9]/\1 0.0/' ${F} | sed 's/\("'${R}'":\) [0-1].[0-9]/\1 0.0/' > sweep_test_top30_with_bind_noise_${i}.txt
    sed 's/\("'${E}'":\) [0-1].[0-9]/\1 0.0/' ${F} | sed 's/\("'${B}'":\) [0-1].[0-9]/\1 0.0/' > sweep_test_top30_with_recy_noise_${i}.txt
    sed 's/\("'${R}'":\) [0-1].[0-9]/\1 0.0/' ${F} | sed 's/\("'${B}'":\) [0-1].[0-9]/\1 0.0/' > sweep_test_top30_with_endo_noise_${i}.txt
done
