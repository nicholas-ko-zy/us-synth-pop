# Notes

## TODOs
- [ ] Look into systematising the spatial errors in plot 3 (spatial error heatmap) using error metrics like Moran's I.
- [ ] Replicate the Gurobi model (Julia) using an open-source optimisation solver (Python)
    + [ ] Extract the input files to run `select_synpop.jl` and `assign_spatial.jl` independently
    + [ ] Find a working census tract that successfully runs the full pipeline
- [ ] Try to parallelise the process in the Python rewrite as much as possible, given that pop. synthesis for each PUMA is an independent process
- [ ] Low priority. Try to see if you can run the synthpop script on your Linux pc.
- [ ] Create a block diagram of the modules fitting together, see if you can extract the input values to the Gurobi model, to replicate it on a OS Python solver 

## `synthpop.R`
### What it does
- Load libaries
- Set seed
- Assign local R vars to command line argument (when RScript is run from command line)
- Set config i.e. File paths for modules, Julia/R executables, output path. Create output dirs if they do not exist.
- Order of runs (`source`)
    + `prepare_data_file`: `prepare_data.R`
    + `train_bns_file`: `train_bns.R`
    + `sample_hhs_file`: `sample_hhs.R`
    + `sample_indvs_file`: `sample_indvs.R`
    + Run command line command: (`select_synpop_cmd`)
    + Run command line command: (`assign_spatial_cmd`) <- this is where the Julia file is called

Would it help to gather all the files in the Julia file then replicate it in a Python version.

### Variables to note
- `select_synpop_cmd`
```
"\"C:/Users/nicho/AppData/Local/Microsoft/WindowsApps/julia.exe\" \"select_synpop.jl\" 0603700 synthpop_output/0603700/hh_pool_0603700.csv synthpop_output/0603700/indv_pool_0603700.csv synthpop_output/0603700/syn_hhs_0603700.csv synthpop_output/0603700/syn_indvs_0603700.csv synthpop_data/2010_Census_Tract_to_2010_PUMA.csv synthpop_data/acs_marginals/0603700/ synthpop_gurobi_log.txt \"C:\\gurobi1302\\win64\" ./gurobi.lic"
```

- `assign_spatial_cmd`
```
"\"C:/Users/nicho/AppData/Local/Microsoft/WindowsApps/julia.exe\" \"assign_spatial.jl\" 0603700 synthpop_output/0603700/syn_hhs_0603700.csv synthpop_output/0603700/syn_hhs_spatial_0603700.csv synthpop_output/0603700/syn_indvs_0603700.csv synthpop_output/0603700/syn_indvs_spatial_0603700.csv synthpop_data/2010_Census_Tract_to_2010_PUMA.csv synthpop_data/acs_marginals/0603700/ synthpop_gurobi_log.txt \"C:\\gurobi1302\\win64\" ./gurobi.lic"
```

### Generic Notes
- Modules are assign variable names
- Julia modules
    + select_synpop_file <- "select_synpop.jl"
    + assign_spatial_file <- "assign_spatial.jl"