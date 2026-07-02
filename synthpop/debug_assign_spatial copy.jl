ENV["GUROBI_HOME"] = "C:/gurobi1302/win64/"
ENV["GRB_LICENSE_FILE"] = joinpath(@__DIR__, "gurobi.lic")

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

## Environment Variables / Constants 

const MARG_DIR = "synthpop_data/acs_marginals/2503302/"
const BLKGP_MARG_FILES = ["blkgp_tenur_hhsiz.csv"]
const TRACT_MARG_FILES = ["tract_hhtype.csv", "tract_tenur_hhinc.csv", "tract_nwork.csv"]
const BLKGP_MARG_FILES = ["blkgp_tenur_hhsiz.csv"]
const INDV_TRACT_MARG_FILES = ["tract_i_sex_i_age.csv"]
const INDV_BLKGP_MARG_FILES = ["blkgp_emply.csv"]
const INDV_MARG_COLS = [19, 20]
const MARG_COLS = [11, 21, 4, 22]
const GUROBI_LOGFILE = "synthpop_gurobi_log.txt"

marg_file = "tract_hhtype.csv"
CSV.read("$MARG_DIR$marg_file", DataFrame)

length(pop)
m
marginals[1]
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
indv_factors[5][1][1]

indv_factors_dummy = Any[]
# for (indv_marg_col, lvls) in zip(INDV_MARG_COLS, levelss[indv_index:length(levelss)])
#         with_counts = combine(groupby(syn_indvs, :HHID), indv_marg_col => hh_values -> Tuple(count(val->val==l, hh_values) for l in lvls))
#         counts_mat = [[v for v in vals] for vals in with_counts[!,2]]
#         counts_mat = [[row[col] for row in counts_mat] for col in 1:size(counts_mat[1])[1]]
#         push!(indv_factors_dummy, counts_mat)
# end
###################################################################

# Define JuMP model
model = Model(Gurobi.Optimizer)
set_optimizer_attribute(model, "LogFile", GUROBI_LOGFILE)

## Variables
@variable(model, x[1:n*m]) # define variable x
n_cells = sum(sum(length(lvl) for lvl in marg) for marg in marginals)
@variable(model, y[1:n_cells]) # define absolute value helper variable y

## Objective
@objective(model, Min, sum(y))

## Constraints
@constraint(model, con_lb[i=1:n*m], 0 <= x[i]) # lower bound constraint
@constraint(model, con_ub[i=1:n*m], x[i] <= 1) # upper bound constraint
@constraint(model, con_rowsum[i=1:n], sum(x[m*(i-1)+j] for j in 1:m) == 1)
@constraint(model, con_colsum[j=1:m], sum(x[m*(i-1)+j] for i in 1:n) == blkgp_hh_pops[j])

# add marginal cell constraints to enforce absolute value
# marg_cell_i = 1
# for (marg_i, (marg_col, marg, lvls, indv_facs)) in enumerate(zip(vcat(MARG_COLS, INDV_MARG_COLS), marginals, levelss, indv_factors))
#         cell_weight = length(lvls) * length(marg[1])
#         for (lvl_i, (lvl, ifs)) in enumerate(zip(lvls, indv_facs))
#                 if length(marg[1]) == m # block group marginal
#                         for j in 1:m
#                                 @constraint(model, y[marg_cell_i] >= (sum(ifs[i] * x[m*(i-1)+j] for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*blkgp_hh_pops[j])
#                                 @constraint(model, y[marg_cell_i] >= -(sum(ifs[i] * x[m*(i-1)+j] for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*blkgp_hh_pops[j])
#                                 global marg_cell_i += 1
#                         end
#                 else # tract marginal
#                         for j in 1:length(tract_hh_pops)
#                                 @constraint(model, y[marg_cell_i] >= (sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*tract_hh_pops[j])
#                                 @constraint(model, y[marg_cell_i] >= -(sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*tract_hh_pops[j])
#                                 global marg_cell_i += 1
#                         end
#                 end
#         end
# end


captured_terms = Dict{String, Any}()

try
    marg_cell_i = 1
    for (marg_i, (marg_col, marg, lvls, indv_facs)) in enumerate(zip(vcat(MARG_COLS, INDV_MARG_COLS), marginals, levelss, indv_factors))
        cell_weight = length(lvls) * length(marg[1])
        for (lvl_i, (lvl, ifs)) in enumerate(zip(lvls, indv_facs))
            
            if length(marg[1]) == m 
                for j in 1:m
                    marg_cell_i += 1
                end
            else 
                # --- TRACT MARGINAL BRANCH ---
                j = 1 
                
                # 1. Find the first household index 'i' that passes the loop conditional filter
                first_matching_i = nothing
                for (i, hh) in enumerate(pop)
                    if marg_i >= indv_index || hh[marg_col] == lvl
                        first_matching_i = i
                        break 
                    end
                end
                
                if first_matching_i !== nothing
                    i_match = first_matching_i
                    
                    # 2. Extract the exact components used in the inner sum for this specific household
                    captured_terms["inner_sum_hh_index"] = i_match
                    captured_terms["inner_sum_ifs_multiplier"] = ifs[i_match]
                    captured_terms["inner_sum_target_blockgroups"] = tract_blkgp[j]
                    
                    # Capture raw indices
                    x_indices = [m * (i_match - 1) + k for k in tract_blkgp[j]]
                    captured_terms["inner_sum_x_indices_evaluated"] = x_indices
                    
                    # FIX: Convert JuMP decision variables to text strings to prevent serialization hanging
                    captured_terms["inner_sum_x_values"] = [string(x[idx]) for idx in x_indices]
                    
                    # FIX: Convert the inner sum expression layout to a string
                    inner_sum_expr = sum(ifs[i_match] * x[m*(i_match-1)+k] for k in tract_blkgp[j])
                    captured_terms["inner_sum_calculated_result"] = string(inner_sum_expr)
                else
                    captured_terms["inner_sum_status"] = "No matching household found for this category filter"
                end
                
                # 3. Process contextual overall metrics
                est_j1 = sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) 
                             for (i,hh) in enumerate(pop) if marg_i >= indv_index || hh[marg_col] == lvl)
                
                # FIX: Convert global JuMP summation expression layout to a string
                captured_terms["total_estimate_term1"] = string(est_j1)
                
                # Targets and weights are standard numeric arrays, so they don't cause hanging
                captured_terms["census_target_term2"] = marg[lvl_i][j]
                captured_terms["scaling_factor_term3"] = (1 + marg[lvl_i][j]) / cell_weight * tract_hh_pops[j]
                
                throw("First Tract Case & Inner Sum Extracted Successfully!")
            end
        end
    end
catch e
    println("\n[Intercepted Loop] State: ", e)
end

# --- Safe Serialization Now Happens Instantly ---
serialize("./data/assign_spatial/captured_terms.jls", captured_terms)

# --- Print out your deep-dive isolated variables ---
# println("\n=== DEEP DIVE: FIRST VALID TERM OF INNER SUM ===")
# println("HOUSEHOLD INDEX (i):     ", get(captured_terms, "inner_sum_hh_index", "N/A"))
# println("IFS MULTIPLIER (ifs[i]): ", get(captured_terms, "inner_sum_ifs_multiplier", "N/A"))
# println("TARGET BLOCKGROUPS (k):  ", get(captured_terms, "inner_sum_target_blockgroups", "N/A"))
# println("EVALUATED X INDICES:     ", get(captured_terms, "inner_sum_x_indices_evaluated", "N/A"))
# println("RAW X VALUES FROM DECVAR:", get(captured_terms, "inner_sum_x_values", "N/A"))
# println("--------------------------------------------------")
# println("FINAL INNER SUM RESULT:  ", get(captured_terms, "inner_sum_calculated_result", "N/A"))

# println("\n=== GLOBAL CONTEXTUAL TERMS ===")
# println("TOTAL ESTIMATE (Term 1): ", get(captured_terms, "total_estimate_term1", "N/A"))
# println("CENSUS TARGET  (Term 2): ", get(captured_terms, "census_target_term2", "N/A"))
# println("SCALING FACTOR (Term 3): ", get(captured_terms, "scaling_factor_term3", "N/A"))
captured_terms["total_estimate_term1"]
captured_terms["inner_sum_calculated_result"]
captured_terms["inner_sum_target_blockgroups"]
captured_terms["inner_sum_x_values"]

marg_i   = 1                       # First loop category index
marg_col = vcat(MARG_COLS, INDV_MARG_COLS)[marg_i] 
marg     = marginals[marg_i]       # Maps to marginals[1]
lvls     = levelss[marg_i]         # Maps to levelss[1]
ifs      = indv_factors[marg_i][1] # First level factors

lvl_i    = 1                       # First demographic level inside this category
lvl      = lvls[lvl_i]             # The text label for this level
j        = 1                       # First Tract index

# 1. Compute Term 1 (ai1: Population Estimate for Tract 1) ---
a_i1 = sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) 
           for (i,hh) in enumerate(pop) if marg_i >= indv_index || hh[marg_col] == lvl)

# 2. Compute Term 2 (b1: True Census Target for Tract 1) ---
b_1 = marg[lvl_i][j]

# 3. Calculate Raw Difference Expression ---
difference_expr = a_i1 - b_1