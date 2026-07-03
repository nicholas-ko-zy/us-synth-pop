# make_smoke_test_data.jl
using CSV, DataFrames

# Set this to whichever PUMA you want smoke-test data for, e.g.:
# Suffolk County, MA -> "2503302"
# Fulton County, GA  -> "1300100"
const CURR_PUMA = "1300100"

const N_TRACTS = 3
const N_HOUSEHOLDS = 1000

const OUT_DIR = "synthpop_output/smoketest/$CURR_PUMA"
const DATA_DIR = "synthpop_data/smoketest"
mkpath(OUT_DIR)
mkpath(DATA_DIR)

# --- Trim the tract equivalence file down to a few tracts for this PUMA ---
puma_tract_equiv = CSV.read("synthpop_data/2010_Census_Tract_to_2010_PUMA.csv", DataFrame)
curr_geo = filter(row -> row.STATEFP == parse(Float64, CURR_PUMA[1:2]) &&
                          row.PUMA5CE == parse(Float64, CURR_PUMA[3:7]), puma_tract_equiv)
curr_geo_small = first(curr_geo, N_TRACTS)

other_pumas = filter(row -> !(row.STATEFP == parse(Float64, CURR_PUMA[1:2]) &&
                               row.PUMA5CE == parse(Float64, CURR_PUMA[3:7])), puma_tract_equiv)
equiv_small = vcat(other_pumas, curr_geo_small)
CSV.write(joinpath(DATA_DIR, "2010_Census_Tract_to_2010_PUMA.csv"), equiv_small)

# --- Trim households ---
syn_hhs = CSV.read("synthpop_output/$CURR_PUMA/syn_hhs_$CURR_PUMA.csv", DataFrame)
puma_hhs = filter(row -> lpad(string(row.puma), 7, "0") == CURR_PUMA, syn_hhs)
small_hhs = first(puma_hhs, N_HOUSEHOLDS)
CSV.write(joinpath(OUT_DIR, "syn_hhs_$CURR_PUMA.csv"), small_hhs)

keep_hhids = Set(small_hhs.HHID)

# --- Trim individuals ---
syn_indvs = CSV.read("synthpop_output/$CURR_PUMA/syn_indvs_$CURR_PUMA.csv", DataFrame)
small_indvs = filter(row -> row.HHID in keep_hhids, syn_indvs)
CSV.write(joinpath(OUT_DIR, "syn_indvs_$CURR_PUMA.csv"), small_indvs)

println("Wrote smoke-test files to $OUT_DIR and $DATA_DIR")
println("  PUMA: ", CURR_PUMA)
println("  Tracts kept: ", N_TRACTS)
println("  Households kept: ", nrow(small_hhs))
println("  Individuals kept: ", nrow(small_indvs))