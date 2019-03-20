# Broadband Maps

A set of scripts for visualizing broadband speeds in New Hampshire and Vermont.

## Dependencies

* Ruby version 2.5.1
* MacOS 10.14


## Approach

### 1. Download broadband data from the FCC

### 2. Download population data from the census bureau

### 3. Load data into two PostgreSQL tables

*broadband_data*

* state_abbr
* block_code
* max_ad_up

*population_data*

* block_code
* population


### 4. Prepare data for use in a CARTO map


## Result

PostgreSQL table with the following structure:

*census_county_subdivisions*

* census_county_subdivision_id
* maximum_advertised_upload_speed
