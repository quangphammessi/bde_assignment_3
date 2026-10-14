/*
    Silver: 2016 Census, table G02 (Selected Medians and Averages)
    Grain : one row per NSW LGA
    Feeds : gold.ref_census_g02

    lga_code_2016 arrives as 'LGA' + code ('LGA17200'). The prefix is removed
    so the code joins directly to s_lga / dim_lga. Measure columns keep the
    ABS short names in lower case.
    Note: mortgage repayments are monthly; rent and incomes are weekly.
*/

select
    replace(trim(lga_code_2016), 'LGA', '')   as lga_code,
    median_age_persons,
    median_mortgage_repay_monthly,
    median_tot_prsnl_inc_weekly,
    median_rent_weekly,
    median_tot_fam_inc_weekly,
    average_num_psns_per_bedroom,
    median_tot_hhd_inc_weekly,
    average_household_size
from {{ source('bronze', 'raw_census_g02') }}
