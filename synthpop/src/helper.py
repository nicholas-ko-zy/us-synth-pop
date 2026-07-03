import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def process_tract_hhtype(tract_hhtype):
    """
    Helper function to clean wide-format census data, sum up demographic 
    counts across all geographic areas, and calculate baseline percentage weights.
    """
    hhtype_cols = ['MC', 'NS', 'SM', 'NF', 'GQ']
    
    # Melt the demographic columns into a long vertical series
    tract_hhtype_melted = tract_hhtype.melt(
        id_vars=['geoid'], 
        value_vars=hhtype_cols, 
        var_name='hhtype', 
        value_name='count'
    )
    
    # Sum up counts across all geographic geoids to get the regional distribution totals
    tract_hhtype_agg = tract_hhtype_melted.groupby('hhtype')['count'].sum().reset_index()
    tract_hhtype_agg.columns = ['hhtype', 'census_count']
    
    # Calculate global baseline percentage weights
    tract_hhtype_agg['census_pct'] = (tract_hhtype_agg['census_count'] / tract_hhtype_agg['census_count'].sum()) * 100
    return tract_hhtype_agg


def generate_side_by_side_plot(census_df, synpop_df, location=''):
    """
    Main function to coordinate data preparation and render a side-by-side 
    bar chart comparison between Census and Synthesized Population.
    """
    # 1. Process Census Data via abstracted helper function
    census_processed = process_tract_hhtype(census_df)

    # 2. Process Synpop Data (Individual rows to aggregated totals)
    synpop_clean = synpop_df.copy()
    synpop_clean['hhtype_clean'] = synpop_clean['hhtype'].str.replace(r'\d+', '', regex=True)
    syn_agg = synpop_clean['hhtype_clean'].value_counts().reset_index()
    syn_agg.columns = ['hhtype', 'syn_count']
    syn_agg['syn_pct'] = (syn_agg['syn_count'] / syn_agg['syn_count'].sum()) * 100

    # 3. Merge and Compute Differences (Straight Subtraction)
    df_plot = pd.merge(census_processed, syn_agg, on='hhtype', how='outer').fillna(0)
    # Updated to absolute percentage point difference
    df_plot['pct_diff'] = df_plot['syn_pct'] - df_plot['census_pct']
    
    # Clean display labels mapping
    labels_map = {
        'MC': 'Married Couples', 
        'NS': 'No Spouse', 
        'SM': 'Single-member', 
        'NF': 'Non-Family', 
        'GQ': 'Group Quarters'
    }
    df_plot['label'] = df_plot['hhtype'].map(labels_map)

    # 4. Plot Setup
    fig, ax = plt.subplots(figsize=(11, 5))

    categories = df_plot['label'].tolist()
    census_percentages = df_plot['census_pct'].tolist()
    syn_percentages = df_plot['syn_pct'].tolist()
    pct_differences = df_plot['pct_diff'].tolist()

    x = np.arange(len(categories))
    width = 0.28  # Width of individual bars

    # Render bars: Blue for Census, Red for Synth Pop
    rects1 = ax.bar(x - width/2, census_percentages, width, label='Census', color='skyblue')
    rects2 = ax.bar(x + width/2, syn_percentages, width, label='Syn Pop', color='salmon')

    # Add text box percentage difference indicators
    for i in range(len(categories)):
        max_height = max(census_percentages[i], syn_percentages[i])
        diff = pct_differences[i]
        sign = "+" if diff >= 0 else ""
        label_text = f"{sign}{diff:.2f}%"
        
        ax.text(x[i], max_height + 1.2, label_text, ha='center', va='bottom', fontsize=9,
                bbox=dict(boxstyle="square,pad=0.3", fc="white", ec="gray", lw=0.8))

    # Formatting and Styling
    ax.set_ylabel('%', fontsize=11)
    ax.set_title(f'Comparison of Household Type {location}', fontsize=12, pad=15)
    ax.set_xticks(x)
    ax.set_xticklabels(categories, fontsize=10)
    # ax.set_ylim(0, max(max(census_percentages), max(syn_percentages)) * 1.15)
    # TODO: Change to global value
    ax.set_ylim(0, 80)
    ax.legend(loc='upper left', bbox_to_anchor=(1.02, 1), frameon=True)

    # Clean axes spines
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    plt.tight_layout()
    plt.show()
    display(df_plot.rename(columns={'label': 'hhtype'})[['hhtype', 'census_pct', 'syn_pct', 'pct_diff']])

    
