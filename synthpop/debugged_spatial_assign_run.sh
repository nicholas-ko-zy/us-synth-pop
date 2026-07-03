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

# Working test with full suite of fixes
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

# Proof of infeasible result for original .jl on subsetted data
# julia assign_spatial.jl 2503302 \
#     synthpop_output/smoketest/2503302/syn_hhs_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_hhs_spatial_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_indvs_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_indvs_spatial_2503302.csv \
#     synthpop_data/smoketest/2010_Census_Tract_to_2010_PUMA.csv \
#     synthpop_data/acs_marginals/2503302/ \
#     synthpop_output/smoketest/synthpop_gurobi_log.txt \
#     "C:\gurobi1302\win64" ./gurobi.lic \

# Suffolk County, MA
# Iso-Fix 1: Scale blkgp_hh_pops back again so it matches n
# + Added necessary n definition, moved code chunk up; No change to logic
# julia isolate_bug_assign_spatial.jl 2503302 \
#     synthpop_output/smoketest/2503302/syn_hhs_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_hhs_spatial_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_indvs_2503302.csv \
#     synthpop_output/smoketest/2503302/syn_indvs_spatial_2503302.csv \
#     synthpop_data/smoketest/2010_Census_Tract_to_2010_PUMA.csv \
#     synthpop_data/acs_marginals/2503302/ \
#     synthpop_output/smoketest/synthpop_gurobi_log.txt \
#     "C:\gurobi1302\win64" ./gurobi.lic \

# Fulton County, GA
# Iso-Fix 1: Scale blkgp_hh_pops back again so it matches n
# + Added necessary n definition, moved code chunk up; 
# SUBSET OF POP
# julia isolate_bug_assign_spatial.jl 1300100 \
#     synthpop_output/smoketest/1300100/syn_hhs_1300100.csv \
#     synthpop_output/smoketest/1300100/syn_hhs_spatial_1300100.csv \
#     synthpop_output/smoketest/1300100/syn_indvs_1300100.csv \
#     synthpop_output/smoketest/1300100/syn_indvs_spatial_1300100.csv \
#     synthpop_data/smoketest/2010_Census_Tract_to_2010_PUMA.csv \
#     synthpop_data/acs_marginals/1300100/ \
#     synthpop_output/smoketest/synthpop_gurobi_log.txt \
#     "C:\gurobi1302\win64" ./gurobi.lic \

# Fulton County, GA
# Iso-Fix 1: Scale blkgp_hh_pops back again so it matches n
# + Added necessary n definition, moved code chunk up; 
# FULL POP
julia isolate_bug_assign_spatial.jl 1300100 \
    synthpop_output/1300100/syn_hhs_1300100.csv \
    synthpop_output/1300100/syn_hhs_spatial_1300100.csv \
    synthpop_output/1300100/syn_indvs_1300100.csv \
    synthpop_output/1300100/syn_indvs_spatial_1300100.csv \
    synthpop_data/2010_Census_Tract_to_2010_PUMA.csv \
    synthpop_data/acs_marginals/1300100/ \
    synthpop_gurobi_log_1300100_FULL_POP.txt \
    "C:\gurobi1302\win64" ./gurobi.lic




