ENV["GUROBI_HOME"] = ARGS[9]
ENV["GRB_LICENSE_FILE"] = ARGS[10]

using Gurobi, JuMP, CSV, DataFrames, Random, RLEVectors, StatsBase, Serialization
test_var = 1
Random.seed!(1033)

@time begin

const CURR_PUMA = ARGS[1]
const SYN_HHS_FILE = ARGS[2]
const SYN_HHS_SPATIAL_FILE = ARGS[3]
const SYN_INDVS_FILE = ARGS[4]
const SYN_INDVS_SPATIAL_FILE = ARGS[5]
const PUMA_TRACT_EQUIV_FILE = ARGS[6]
const MARG_DIR = ARGS[7]
const GUROBI_LOGFILE = ARGS[8]

const TRACT_MARG_FILES = ["tract_hhtype.csv", "tract_tenur_hhinc.csv", "tract_nwork.csv"]
const BLKGP_MARG_FILES = ["blkgp_tenur_hhsiz.csv"]
const MARG_COLS = [11, 21, 4, 22]
const INDV_TRACT_MARG_FILES = ["tract_i_sex_i_age.csv"]
const INDV_BLKGP_MARG_FILES = ["blkgp_emply.csv"]
const INDV_MARG_COLS = [19, 20]

# Uncomment if you want to serialize variables for debugging
# const CURR_PUMA = "2503302"
# const SYN_HHS_FILE = "synthpop_output/2503302/syn_hhs_2503302.csv"
# const SYN_HHS_SPATIAL_FILE = "synthpop_output/2503302/syn_hhs_spatial_2503302.csv"
# const SYN_INDVS_FILE = "synthpop_output/2503302/syn_indvs_2503302.csv"
# const SYN_INDVS_SPATIAL_FILE = "synthpop_output/2503302/syn_indvs_spatial_2503302.csv"
# const PUMA_TRACT_EQUIV_FILE = "synthpop_data/2010_Census_Tract_to_2010_PUMA.csv"
# const MARG_DIR = "synthpop_data/acs_marginals/2503302/"
# const GUROBI_LOGFILE = "synthpop_gurobi_log.txt"
# ENV["GUROBI_HOME"] = "C:/gurobi1302/win64"
# ENV["GRB_LICENSE_FILE"] = "gurobi.lic"


## Get tracts and block groups
puma_tract_equiv = CSV.read(PUMA_TRACT_EQUIV_FILE, DataFrame)
curr_geo = filter(row -> row.STATEFP == parse(Float64, CURR_PUMA[1:2]) && row.PUMA5CE == parse(Float64, CURR_PUMA[3:7]), puma_tract_equiv)
const TRACT_GEOIDS = [string(lpad(string(sct[1]), 2, "0"), lpad(string(sct[2]), 3, "0"), lpad(string(sct[3]), 6, "0"))
                        for sct in zip(curr_geo.STATEFP, curr_geo.COUNTYFP, curr_geo.TRACTCE)]

blkgp_marg_df = CSV.read(string(MARG_DIR, BLKGP_MARG_FILES[1]), DataFrame)
blkgp_marg_df = filter(row -> lpad(string(row.geoid), 12, "0")[1:11] in TRACT_GEOIDS, blkgp_marg_df)
const BLKGP_GEOIDS = lpad.(string.(blkgp_marg_df.geoid), 12, "0")

# Create tract-block group mapping
const tract_blkgp = [findall(tract -> tract == tract_geoid, SubString.(BLKGP_GEOIDS, 1, 11)) for tract_geoid in TRACT_GEOIDS]

## Process marginals
indv_index = length(vcat(TRACT_MARG_FILES, BLKGP_MARG_FILES)) + 1
const m = length(BLKGP_GEOIDS)
marginals = []
levelss = []
const MARG_FILES = vcat(TRACT_MARG_FILES, BLKGP_MARG_FILES, INDV_TRACT_MARG_FILES, INDV_BLKGP_MARG_FILES)
for marg_file in MARG_FILES
        marg_df = CSV.read("$MARG_DIR$marg_file", DataFrame)
        marg_df = filter(row -> lpad(string(row.geoid), (marg_file in vcat(TRACT_MARG_FILES, INDV_TRACT_MARG_FILES) ? 11 : 12), "0") in (marg_file in vcat(TRACT_MARG_FILES, INDV_TRACT_MARG_FILES) ? TRACT_GEOIDS : BLKGP_GEOIDS), marg_df)
        select!(marg_df, Not(:geoid))
        marg = [col[:] for col in eachcol(Matrix(marg_df))]
        push!(marginals, marg)
        push!(levelss, names(marg_df))
end

const tract_hh_pops = sum(marginals[1], dims=1)[1]
const blkgp_hh_pops = sum(marginals[indv_index-1], dims=1)[1]
const tract_indv_pops = sum(marginals[indv_index], dims=1)[1]
const blkgp_indv_pops = sum(marginals[length(marginals)], dims=1)[1]

## Process population
syn_hhs = CSV.read(SYN_HHS_FILE, DataFrame)
puma_df = filter(row -> lpad(string(row.puma), 7, "0") == CURR_PUMA, syn_hhs)
pop = [row[:] for row in eachrow(Matrix(puma_df))]

const n = length(pop)

syn_indvs = CSV.read(SYN_INDVS_FILE, DataFrame)
n_indvs = DataFrames.nrow(syn_indvs)
syn_hhs_hhsizs = rle(syn_indvs.HHID)[2]

# Precompute individual variable level counts for each household
indv_factors = Any[]
for lvls in levelss[1:(indv_index-1)]
        push!(indv_factors, [[1 for _ in 1:n] for _ in 1:length(lvls)])
end
for (indv_marg_col, lvls) in zip(INDV_MARG_COLS, levelss[indv_index:length(levelss)])
        with_counts = combine(groupby(syn_indvs, :HHID), indv_marg_col => hh_values -> Tuple(count(val->val==l, hh_values) for l in lvls))
        counts_mat = [[v for v in vals] for vals in with_counts[!,2]]
        counts_mat = [[row[col] for row in counts_mat] for col in 1:size(counts_mat[1])[1]]
        push!(indv_factors, counts_mat)
end

println("Block groups: ", m)
println("Tracts: ", length(TRACT_GEOIDS))
println("Households: ", n)
println("Individuals: ", n_indvs)
println("Marginals: ", MARG_FILES)

# Serialise variables here for debugging
# serialize("./data/assign_spatial/puma_tract_equiv.jls", puma_tract_equiv)
# serialize("./data/assign_spatial/curr_geo.jls", curr_geo)
# serialize("./data/assign_spatial/TRACT_GEOIDS.jls", TRACT_GEOIDS)
# serialize("./data/assign_spatial/blkgp_marg_df.jls", blkgp_marg_df)
# serialize("./data/assign_spatial/BLKGP_GEOIDS.jls", BLKGP_GEOIDS)
# serialize("./data/assign_spatial/tract_blkgp.jls", tract_blkgp)
# serialize("./data/assign_spatial/indv_index.jls", indv_index)
# serialize("./data/assign_spatial/m.jls", m)
# serialize("./data/assign_spatial/MARG_FILES.jls", MARG_FILES)
# serialize("./data/assign_spatial/marginals.jls", marginals)
# serialize("./data/assign_spatial/levelss.jls", levelss)
# serialize("./data/assign_spatial/tract_hh_pops.jls", tract_hh_pops)
# serialize("./data/assign_spatial/blkgp_hh_pops.jls", blkgp_hh_pops)
# serialize("./data/assign_spatial/tract_indv_pops.jls", tract_indv_pops)
# serialize("./data/assign_spatial/blkgp_indv_pops.jls", blkgp_indv_pops)
# serialize("./data/assign_spatial/syn_hhs.jls", syn_hhs)
# serialize("./data/assign_spatial/puma_df.jls", puma_df)
# serialize("./data/assign_spatial/pop.jls", pop)
# serialize("./data/assign_spatial/n.jls", n)
# serialize("./data/assign_spatial/syn_indvs.jls", syn_indvs)
# serialize("./data/assign_spatial/n_indvs.jls", n_indvs)
# serialize("./data/assign_spatial/syn_hhs_hhsizs.jls", syn_hhs_hhsizs)
# serialize("./data/assign_spatial/indv_factors.jls", indv_factors)
#######################################################
## Define optimization model
model = Model(Gurobi.Optimizer)
set_optimizer_attribute(model, "LogFile", GUROBI_LOGFILE)

# Low-RAM Profile Tuning Controls
set_optimizer_attribute(model, "Method", 1)         # Forces Dual Simplex (Saves massive memory over Barrier)
set_optimizer_attribute(model, "Threads", 4)        # Avoids thread over-allocation context thrashing
set_optimizer_attribute(model, "Presolve", 1)       # Enforces baseline matrix simplification routines
set_optimizer_attribute(model, "PreSparsify", 1)    # Aggressively strips non-zero structural overhead

## Variables
@variable(model, x[1:n*m]) 
n_cells = sum(sum(length(lvl) for lvl in marg) for marg in marginals)
@variable(model, y[1:n_cells]) 

## Objective
@objective(model, Min, sum(y))

## Constraints
@constraint(model, con_lb[i=1:n*m], 0 <= x[i]) 
@constraint(model, con_ub[i=1:n*m], x[i] <= 1) 
@constraint(model, con_rowsum[i=1:n], sum(x[m*(i-1)+j] for j in 1:m) == 1)
@constraint(model, con_colsum[j=1:m], sum(x[m*(i-1)+j] for i in 1:n) == blkgp_hh_pops[j])

# Add marginal cell constraints to enforce absolute value
marg_cell_i = 1
for (marg_i, (marg_col, marg, lvls, indv_facs)) in enumerate(zip(vcat(MARG_COLS, INDV_MARG_COLS), marginals, levelss, indv_factors))
        cell_weight = length(lvls) * length(marg[1])
        for (lvl_i, (lvl, ifs)) in enumerate(zip(lvls, indv_facs))
                if length(marg[1]) == m # Block group marginal
                        for j in 1:m
                                @constraint(model, y[marg_cell_i] >= (sum(ifs[i] * x[m*(i-1)+j] for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*blkgp_hh_pops[j])
                                @constraint(model, y[marg_cell_i] >= -(sum(ifs[i] * x[m*(i-1)+j] for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*blkgp_hh_pops[j])
                                global marg_cell_i += 1
                        end
                else # Tract marginal
                        for j in 1:length(tract_hh_pops)
                                @constraint(model, y[marg_cell_i] >= (sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*tract_hh_pops[j])
                                @constraint(model, y[marg_cell_i] >= -(sum(sum(ifs[i] * x[m*(i-1)+k] for k in tract_blkgp[j]) for (i,hh) in enumerate(pop) if marg_i>=indv_index || hh[marg_col]==lvl) - marg[lvl_i][j])/(1+marg[lvl_i][j])/cell_weight*tract_hh_pops[j])
                                global marg_cell_i += 1
                        end
                end
        end
end

## Optimize
optimize!(model)

println("****************************************************")
term_status = termination_status(model)
println("Solver terminated with status: ", term_status)

# Intercept execution safely if Gurobi resolves matrix successfully
if term_status in [MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.FEASIBLE_POINT]
    println("Final objective value = ", objective_value(model))
    
    ## Assign households to optimized tracts
    sol_matrix = transpose(reshape(value.(x), (m, n)))
    blkgp_assignments = [BLKGP_GEOIDS[argmax(row)] for row in eachrow(sol_matrix)]
    blkgp_by_hhid = DataFrame(HHID = [row[1] for row in pop], geoid = blkgp_assignments)

    syn_hhs_spatial = leftjoin(syn_hhs, blkgp_by_hhid, on=:HHID)
    if "tenur_hhinc_prox" in names(syn_hhs_spatial) select!(syn_hhs_spatial, Not(:tenur_hhinc_prox)) end
    if "tenur_hhsiz_prox" in names(syn_hhs_spatial) select!(syn_hhs_spatial, Not(:tenur_hhsiz_prox)) end
    CSV.write(SYN_HHS_SPATIAL_FILE, syn_hhs_spatial)

    syn_indvs_spatial = leftjoin(syn_indvs, blkgp_by_hhid, on=:HHID)
    CSV.write(SYN_INDVS_SPATIAL_FILE, syn_indvs_spatial)
    println("Spatial allocation files generated successfully.")

else
    if term_status == MOI.INFEASIBLE
        println("Model is infeasible! Computing Irreducible Infeasible Set (IIS)...")
        
        # Calculate conflict arrays inside JuMP context
        compute_conflict!(model)
        
        # Write structural conflict maps out to an .ilp text file
        conflict_file = replace(GUROBI_LOGFILE, ".txt" => "_conflict.ilp")
        write_to_file(model, conflict_file)
        
        println("IIS conflict matrix written successfully to: ", conflict_file)
    else
        println("Optimization execution suspended or timed out with unhandled status.")
    end
    
    error("Optimization failed to resolve a viable matrix structure. Review logs.")
end

end