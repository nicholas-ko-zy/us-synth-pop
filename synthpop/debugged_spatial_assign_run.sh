# for tol in 0.50 0.3 0.1; do
#   echo "Running with COLSUM_REL_TOL=$tol"
#   julia copy_assign_spatial.jl 2503302 \
#     synthpop_output/2503302/syn_hhs_2503302.csv \
#     synthpop_output/2503302/syn_hhs_spatial_2503302_tol${tol}.csv \
#     synthpop_output/2503302/syn_indvs_2503302.csv \
#     synthpop_output/2503302/syn_indvs_spatial_2503302_tol${tol}.csv \
#     synthpop_data/2010_Census_Tract_to_2010_PUMA.csv \
#     synthpop_data/acs_marginals/2503302/ \
#     synthpop_gurobi_log_debug_tol${tol}.txt \
#     "C:\gurobi1302\win64" ./gurobi.lic \
#     $tol
# done

# julia copy_assign_spatial.jl 2503302 \
#     synthpop_output/2503302/syn_hhs_2503302.csv \
#     synthpop_output/2503302/syn_hhs_spatial_2503302_smoketest.csv \
#     synthpop_output/2503302/syn_indvs_2503302.csv \
#     synthpop_output/2503302/syn_indvs_spatial_2503302_smoketest.csv \
#     synthpop_data/2010_Census_Tract_to_2010_PUMA.csv \
#     synthpop_data/acs_marginals/2503302/ \
#     synthpop_gurobi_log_smoketest.txt \
#     "C:\gurobi1302\win64" ./gurobi.lic \
#     1.0

julia assign_spatial.jl 2503302 \
    synthpop_output/smoketest/2503302/syn_hhs_2503302.csv \
    synthpop_output/smoketest/2503302/syn_hhs_spatial_2503302.csv \
    synthpop_output/smoketest/2503302/syn_indvs_2503302.csv \
    synthpop_output/smoketest/2503302/syn_indvs_spatial_2503302.csv \
    synthpop_data/smoketest/2010_Census_Tract_to_2010_PUMA.csv \
    synthpop_data/acs_marginals/2503302/ \
    synthpop_output/smoketest/synthpop_gurobi_log.txt \
    "C:\gurobi1302\win64" ./gurobi.lic \