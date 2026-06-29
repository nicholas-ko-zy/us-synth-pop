## 
using Gurobi, JuMP, CSV, DataFrames, Random, RLEVectors, StatsBase, Serialization

##
puma_tract_equiv = deserialize("./data/assign_spatial/puma_tract_equiv.jls")
curr_geo = deserialize("./data/assign_spatial/curr_geo.jls")
TRACT_GEOIDS = deserialize("./data/assign_spatial/TRACT_GEOIDS.jls")
blkgp_marg_df = deserialize("./data/assign_spatial/blkgp_marg_df.jls")
BLKGP_GEOIDS = deserialize("./data/assign_spatial/BLKGP_GEOIDS.jls")
tract_blkgp = deserialize("./data/assign_spatial/tract_blkgp.jls")
indv_index = deserialize("./data/assign_spatial/indv_index.jls")
m = deserialize("./data/assign_spatial/m.jls")
MARG_FILES = deserialize("./data/assign_spatial/MARG_FILES.jls")
marginals = deserialize("./data/assign_spatial/marginals.jls")
levelss = deserialize("./data/assign_spatial/levelss.jls")
tract_hh_pops = deserialize("./data/assign_spatial/tract_hh_pops.jls")
blkgp_hh_pops = deserialize("./data/assign_spatial/blkgp_hh_pops.jls")
tract_indv_pops = deserialize("./data/assign_spatial/tract_indv_pops.jls")
blkgp_indv_pops = deserialize("./data/assign_spatial/blkgp_indv_pops.jls")
syn_hhs = deserialize("./data/assign_spatial/syn_hhs.jls")
puma_df = deserialize("./data/assign_spatial/puma_df.jls")
pop = deserialize("./data/assign_spatial/pop.jls")
n = deserialize("./data/assign_spatial/n.jls")
syn_indvs = deserialize("./data/assign_spatial/syn_indvs.jls")
n_indvs = deserialize("./data/assign_spatial/n_indvs.jls")
syn_hhs_hhsizs = deserialize("./data/assign_spatial/syn_hhs_hhsizs.jls")
indv_factors = deserialize("./data/assign_spatial/indv_factors.jls")

##
marginals
const MARG_DIR = "synthpop_data/acs_marginals/2503302/"
const BLKGP_MARG_FILES = ["blkgp_tenur_hhsiz.csv"]
const TRACT_MARG_FILES = ["tract_hhtype.csv", "tract_tenur_hhinc.csv", "tract_nwork.csv"]
const BLKGP_MARG_FILES = ["blkgp_tenur_hhsiz.csv"]
marg_file = "tract_hhtype.csv"
CSV.read("$MARG_DIR$marg_file", DataFrame)

length(pop)
m
marginals
puma_tract_equiv
curr_geo
blkgp_marg_df_raw = CSV.read(string(MARG_DIR, BLKGP_MARG_FILES[1]), DataFrame)
