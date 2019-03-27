# Broadband Maps

A set of scripts for downloading and manipulating FCC broadband data for New Hampshire and Vermont.

## Dependencies

* Ruby version 2.5.1
* PostgreSQL 11.2

## Instructions

1. Navigate to this repository's root directory in your command line interface.

2. Run the main script by typing `ruby prepare_data.rb`.

The result is saved in the file `county_subdivisions.gpkg` in the data directory.

## Data Sources

### Broadband data

https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477

### Census block shapefiles with 2010 population data

https://www.census.gov/geo/maps-data/data/tiger-data.html

*State-based population data is downloadable under "Population & Housing Unit Counts — Blocks".*

### Census county subdivision shapefiles

https://www.census.gov/geo/maps-data/data/cbf/cbf_cousub.html

*Select New Hampshire and Vermont from the "Select a State" dropdown.*


## Visualization

The final visualization of the data in CartoDB can be found at the following URL: http://dev.carto.ruralinnovation.us/u/lucasbraun/builder/50601761-dd14-4404-88af-691cf0e860ad
