print(getwd())
setwd('./synthpop')
map_pumas <- c("0603701", "0603716", "0603733",
               "4805000", "4804901", "4804614",
               "0400134", "0400105", "0400122",
               "2501400", "2503603", "2503302",
               "1208900", "1203105", "1203103",
               "5600200", "5600100", "5600300", "5600400", "5600500")

densities <- c(383.7, 9049.6, 42788.1,
               66.1, 3457.2, 11736.8,
               112.0, 3947.0, 8075.6,
               885.9, 5817.3, 28710.4,
               160.5, 1989.8, 3285.1,
               # last entry is density for entire state of WY
               5.97)
synpop_suffix <- "20220127"
box::use(./plot_maps)
map_pumas_subset <- c(2503302)
plot_maps$plot_error_map("Spatial errors in tenure by houshold income distribution",
               map_pumas_subset, densities,
               variable="tenur_hhinc",
               spatial_level="tract",
               synpop_suffix=synpop_suffix,
               gray_hh_pop_under=30,
               gray_indv_pop_under=50,
               NA_label="too few households")
# synthpop/synthpop_output/2503302/syn_hhs_spatial_2503302.csv