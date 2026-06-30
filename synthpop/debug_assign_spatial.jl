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
const INDV_TRACT_MARG_FILES = ["tract_i_sex_i_age.csv"]
const INDV_BLKGP_MARG_FILES = ["blkgp_emply.csv"]
const INDV_MARG_COLS = [19, 20]

marg_file = "tract_hhtype.csv"
CSV.read("$MARG_DIR$marg_file", DataFrame)

length(pop)
m
marginals
puma_tract_equiv
curr_geo
blkgp_marg_df_raw = CSV.read(string(MARG_DIR, BLKGP_MARG_FILES[1]), DataFrame)
tract_hh_pops
MARG_FILES[1]


# 1. "tract_hhtype.csv"
tract_hhtype = CSV.read("$MARG_DIR$(TRACT_MARG_FILES[1])", DataFrame)
sum(Vector(tract_hhtype[1, propertynames(tract_hhtype)[2:ncol(tract_hhtype)]]))
sum(marginals[1], dims=1)[1]

# 2. "tract_tenur_hhinc.csv"
tract_tenur_hhinc = CSV.read("$MARG_DIR$(TRACT_MARG_FILES[2])", DataFrame)

# 3. "tract_nwork.csv"
tract_nwork = CSV.read("$MARG_DIR$(TRACT_MARG_FILES[3])", DataFrame)

# 4. "blkgp_tenur_hhsiz.csv"
blkgp_tenur_hhsiz = CSV.read("$MARG_DIR$(BLKGP_MARG_FILES[1])", DataFrame)
# Sanity check that first row sums to the same first element of the blkgp_hh_pops[1] vector
blkgp_hh_pops[1] == sum(Vector(blkgp_tenur_hhsiz[1, propertynames(blkgp_tenur_hhsiz)[2:ncol(blkgp_tenur_hhsiz)]]))

# 5. "tract_i_sex_i_age.csv"
tract_i_sex_i_age = CSV.read("$MARG_DIR$(INDV_TRACT_MARG_FILES[1])", DataFrame)

# 6. "blkgp_emply.csv"
blkgp_emply = CSV.read("$MARG_DIR$(INDV_BLKGP_MARG_FILES[1])", DataFrame)

size(tract_i_sex_i_age)
length(marginals)

Matrix(puma_df)
pop_1 = pop[61052]
size(syn_indvs)
indv_factors[1][1]

indv_factors_dummy = Any[]
for (indv_marg_col, lvls) in zip(INDV_MARG_COLS, levelss[indv_index:length(levelss)])
        with_counts = combine(groupby(syn_indvs, :HHID), indv_marg_col => hh_values -> Tuple(count(val->val==l, hh_values) for l in lvls))
        counts_mat = [[v for v in vals] for vals in with_counts[!,2]]
        counts_mat = [[row[col] for row in counts_mat] for col in 1:size(counts_mat[1])[1]]
        push!(indv_factors_dummy, counts_mat)
end