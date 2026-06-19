# Notes

## TODOs
- [ ] Look into systematising the spatial errors in plot 3 (spatial error heatmap) using error metrics like Moran's I. `plot_error_map`
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

## `plot_maps.R`

### `plot_error_map`
- `puma_labels`: Stores the plot names for 15 of the puma codes + state of WY, and their population densities.

- `sf_geos.puma` <- Calls the function `get_error_map_data`, which calls `get_rmses`. Get the map data based on the map_pumas, since I only added Suffolk County, MA, it only gave me the geometries of all in that county. Smallest spatial resolution is the census tract level.

![](img/plot_error_map_sf_geos_puma.png)

- The marg_ct (marginal counts) are taken from the `error_heatmap()` function,

![](img/plot_error_map_heatmap_data.png)

Each census tract level contains a `hh_pop` and a `indv_pop` column, with pop count inside that cell.

- There is a step to remove empty geometries as a safety net.

- `sf_geos.puma.sf`: Applies `st_sf` to the `sf_geos.puma` df. `st_sf` coerces the dataframe into a `sf` object, which is a standard object in R to store spatial vector data.

![](img/plot_error_map_sf_geos_pumas_sf.png)

- For more detailed analysis of how the bulk of the data gets processed, look into `get_error_map_data()`


# `get_error_map_data()`

Args
- `variable`: "tenur_hhinc"
- `spatial_level`: "tract"

**Steps:** (Using census tract 2503302 as an example)
- Process synopop files
- Read these two files (replace the census code with something else, note that there is a synpop_suffix for distinguishing runs)
    + `syn_hhs_file`: "synthpop_output/2503302/syn_hhs_spatial_2503302-20220127.csv"
    + `syn_indvs_file`: "synthpop_output/2503302/syn_indvs_spatial_2503302-20220127.csv"
    + Remark: `synpop_suffix`: "20220127"
- Load and preprocess synpop and marginal dataframes
    + `syn_hhs`
    ![](img/get_error_map_data_syn_hhs.png)
    + `syn_indvs`
    ![](img/get_error_map_data_syn_indvs_head.png)

    ![](img/get_error_map_data_syn_indvs_tail.png)

- Process marginal files
- `marg_dir`: "synthpop_data/acs_marginals/2503302/"
- `margs`: List of 8 postprocessed marginal dataframes
    1. `tract_tenur_hhinc.1`

        ![](img/margs_tract_tenur_hhinc_1.png)

    2. `blkgp_tenur_hhsiz.1`

        ![](img/margs_blk_gp_tenur_hhsiz_1.png)

    3. `tract_nwork.1`

        ![](img/margs_tract_nwork_1.png)

    4. `tract_hhtype.1`

        ![](img/margs_tract_hhtype_1.png)

    5. `tract_nwork_ncars.1`

        ![](img/margs_tract_nwork_ncars_1.png)

    6. `tract_i_sex_i_age.1`

        ![](img/margs_tract_i_sex_i_age_1.png)

    7. `blkgp_emply.1`

        ![](img/margs_blkgp_emply_1.png)

    8. `tract_i_inc.1`

        ![](img/margs_tract_i_inc_1.png)
    
- Assign the marg name variable, `marg_name`: "tract_tenur_hhinc.l"
- Assign `sym_variable`: "tenur_hhinc_prox"
- Assign `heatmap_data`, which calls `error_heatmap`:
    + `error_heatmap()` > `pop`

        ![](img/error_heatmap_pop.png)
    + `error_heatmap()` > `marg`

        ![](img/error_heatmap_marg.png)

    + `error_heatmap()` > `heatmap_data`

        ![](img/error_heatmap_heatmap_data.png)

    + ![](img/plot_error_map_heatmap_data.png)

- Assign sf_geo data for plotting map data, data taken from `map_data/geos/[YOUR_PUMA_NUMBER]_[YOUR_SPATIAL_LEVEL]_geps.Rds` 
- Remark: `.Rds` files are like Python `.pkl` files
- `hh_marg_target`: "tract_hhtype.l"
- `hh_pops`: Count of households from the marginal files

    ![](img/get_error_map_data_hh_pops.png)

- `indv_marg_target`: "tract_i_sex_i_age.l"
- `indv_pops`: Count of individuals from the marginal files

    ![](img/get_error_map_data_indv_pops.png)

- `sf_geos`: Left join of sf_geos and hh_pops
- `sf_geos.puma`: Row bind of puma `sf_geos.puma` and `sf_geos`.
- Remark: ^ Strangely dataviewer shows only `geoid` and `NAME` cols for both `sf_geos` and `sf_geos.puma`.


# Moran's I

Constants/Parameters Defined
- **Spatial resolution of polygons** (i.e. Singapore's case: Region > Planning Area > Subzone)
- **Neighbour definition** (how polygons define their neighbours? Contiguous, Distance, Non-spatial? Rook, Queen?)
- **Spatial weight matrix, $w$**
    + (all weights of each polygon's list of neighbours must sum to 1, can reweigh if you have special insight i.e. pop density?) <- Apparently I is quite sensitive to the weights.
- 

**Reference**: https://mgimond.github.io/simple_moransI_example/

**What you'll need**
- R Libraries 
    + `sf`: To manipulate spatial data
    + `spdep`: To calculate Moran's I with hypothesis testing
    + `tmap`: For plotting map visualisations
- sf object (Like a geodataframe) with
    + Spatial attributes
    + Regular attributes (i.e. Age, Income, Housing Age etc)

**Pre-Moran's I Analysis Check**
- Take note of outliers, which might mess with your hypothesis testing
- Paraphrased from Gimond:
    > Moran's I is becomes less useful if there are outliers / if the data is heavily skewed. So it's good practice to check for the distribution of the data at the start.
- Methods to check for outliers (visual inspection)
    + Histogram
    + Boxplot

```R
# Histogram
hist(s$Income, main=NULL)
# Boxplot
boxplot(s$Income, horizontal=FALSE)
```

**Moran's I Analysis** 
1. Define neighbouring polygons
    + Neighbour definitions
        + Contiguous polygons (polygons adjacent to one another, no gaps)
        + Polygons within a certain distance threshold
            - Queen Case: If your polygon's vertex touches my (current position's) polygon, we're neighbours
            - Rook Case: Your polygon needs to share a border (not just vertex) with my (current position's) polygon, to be defined as neighbours.
        + Non-spatial definition, i.e. social, political, cultural neighbours.

```R
# `poly2nb` comes from the spdep package
nb <- poly2nb(s, queen=TRUE)
# The polygon ids that are 'neighbours' of polygon id 1
# In this case, each polygon is one county
nb[1]
```
- ^ Creates a list, each element in the list is one row of your spatial dataframe (a polygon).
- Each element contains the list of neighbours

2. Assign weights to the each polygon's neighbours.

Size of weight matrix, $w$, is a square matrix, but it will have zeroes in in $w_{ij}$ where polygon $i$ is not neighbours with polygon $j$.

From the [Moran's I Wikipedia page](https://en.wikipedia.org/wiki/Moran%27s_I):
> The idea is to construct a matrix that accurately reflects your assumptions about the particular spatial phenomenon in question. A common approach is to give a weight of 1 if two zones are neighbors, and 0 otherwise, though the definition of 'neighbors' can vary. Another common approach might be to give a weight of 1 to k nearest neighbors, 0 otherwise. An alternative is to use a distance decay function for assigning weights. Sometimes the length of a shared edge is used for assigning different weights to neighbors. The selection of spatial weights matrix should be guided by theory about the phenomenon in question. The value of is quite sensitive to the weights and can influence the conclusions you make about a phenomenon, especially when using distances.

You can use equal weights as in:

```
0.2(neighbor1) + 0.2(neighbor2) + 0.2(neighbor3) + 0.2(neighbor4) + 0.2(neighbor5)
```

```R
# Using the nb2listw from the spdep
# `lw` has type `listw` object
lw <- nb2listw(nb, style="W", zero.policy=TRUE)
```

- Documentation for `nb2listw`
```R
nb2listw(neighbours, glist=NULL, style="W", zero.policy=NULL)
listw2U(listw)
```
- **neighbours**
    
    an object of class nb

- **glist**

    list of general weights corresponding to neighbours

- **style**

    style can take values “W”, “B”, “C”, “U”, “minmax” and “S”

    + "W": Row standardised, sums over all neighbours to 1
    + "B": Basic binary coding
    + "C" Globally standardised (all pairs sum to n)
    + "U": "C" divided by number of neighbours 
    + "S": Variance-stabalizing coding scheme proposed by Tiefelsdorf et al. 1999, p. 167-168 

- **zero.policy**

    default NULL, use global option value; if FALSE stop with error for any empty neighbour sets, if TRUE permit the weights list to be formed with zero-length weights vectors

- **listw**
    
    a listw object created for example by nb2listw



3. (Optional) Compuate the weighted target attribute you are testing for
- Computed the (weighted) neighbour mean income values
- Note from Gimond: 
  > NOTE: This step does not need to be performed when running the moran or moran.test functions outlined in Steps 4 and 5. This step is only needed if you wish to generate a scatter plot between the income values and their lagged counterpart.

4. Compute Moran's I statistics
$$I = \frac{n}{\sum_{i=1}^{n}\sum_{j=1}^{n}w_{ij}}
\frac{\sum_{i=1}^{n}\sum_{j=1}^{n}w_{ij}(x_i-\bar{x})(x_j-\bar{x})}{\sum_{i=1}^{n}(x_i - \bar{x})^2}$$

```R
# Using the `moran()` function from the `spdep` package
I <- moran(s$Income, lw, length(nb), Szero(lw))[1]

# x - s$Income
# lw - listw
# n - length(nb)
# S0 - Szero(lw) <- If there are 67 regions and if all sum to 1 then S0 = 67
```

```R
# From the documentation
moran(x, listw, n, S0, zero.policy=attr(listw, "zero.policy"), NAOK=FALSE)
```

- **x**

    a numeric vector the same length as the neighbours list in listw

- **listw**

    a listw object created for example by nb2listw

- **n**

    number of zones

- **S0**

    global sum of weights

- **zero.policy**

    default attr(listw, "zero.policy") as set when listw was created, if attribute not set, use global option value; if TRUE assign zero to the lagged value of zones without neighbours, if FALSE assign NA

- **NAOK**

    if 'TRUE' then any 'NA' or 'NaN' or 'Inf' values in x are passed on to the foreign function. If 'FALSE', the presence of 'NA' or 'NaN' or 'Inf' values is regarded as an error.

5. Performing a hypothesis test

    i.e. 

    - $H_0$ : “the income values are randomly distributed across counties following a completely random process”
    - $H_1$ : "There is a spatial element to the distribution of mean income in the counties"
    - Two methods to perform hypothesis test
        + Analytical method
        + Monte Carlo method

    5.1 Analytical method
    - Use the `moran.test` function; one-sided hypothesis test.
    - Recall that the motivations for one vs. two sided test
    + One-sided: An increase or decrease (single directional change)
    + Two-sided: A change in either direction (bidirectional change)
    ```R
    moran.test(s$Income,lw, alternative="greater")
    ```
    - ^ Output log states that the p-value is close to 0.
    - Documentation for `moran.test`
    ```R
    moran.test(x, listw, randomisation=TRUE, zero.policy=attr(listw, "zero.policy"),
            alternative="greater", rank = FALSE, na.action=na.fail, spChk=NULL,
            adjust.n=TRUE, drop.EI2=FALSE)
    ```
    - The `alternative` parameter can take the following arguments
    + `greater`, $\mu > x$
    + `less`, $\mu < x$
    + `two.sided` $\mu \neq x$

    ```R
    # First arg: Attribute you want to test for
    # Second arg: List of weights
    # Alternative: greater, lesser, two.sided hypothesis test
    moran.test(s$Income, lw, alternative="two.sided")
    ```

    5.2 Monte Carlo Method
    - Analytical approach to Moran's I may be sensitive to irregularly distributed polygons.
    - Use the `moran.mc(n)` function to run an MC simulation, where `n` is the number of simulations.
    ```R
    MC<- moran.mc(s$Income, lw, nsim=999, alternative="greater")

    # View results (including p-value)
    MC
    ```

    ```R
    # Plot the Null distribution (note that this is a density plot instead of a histogram)
    # ^ to help visualise the distribution of Moran's I values had
    # incomes been randomly distributed.
    # The black line shows our observed statistic falls way right of the
    # distribution => income values are clustered
    plot(MC)
    ```

    Gimond suggests another way to visualise (on a map) how a typical your patterns are
    is to compare randomly distributed patterns side-by-side from your observed spatial distribution
    of your demographic attribute (or whatever attribute you're interested in)
