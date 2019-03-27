require "open-uri"
require "zip"

# Method for downloading and unziping csv data file packages
def download_data_file(url, directory, destination_filename)
  filepath = "#{directory}/#{destination_filename}"
  puts ">> Downloading #{filepath}..."
  IO.copy_stream(open(url), filepath)

  Zip::File.open(filepath) do |zip_file|
    data_file = zip_file.glob('*.csv').first
    filepath = "#{directory}/#{data_file.name}"
    puts ">> Extracting #{filepath}..."
    data_file.extract(filepath)
  end
end

# FCC broadband data URLs
vt_data_url = "https://transition.fcc.gov/form477/BroadbandData/Fixed/Dec17/Version%201/VT-Fixed-Dec2017.zip"
nh_data_url = "https://transition.fcc.gov/form477/BroadbandData/Fixed/Dec17/Version%201/NH-Fixed-Dec2017.zip"

# Download FCC broadband data
download_data_file(vt_data_url, "data", "vt_data.zip")
download_data_file(nh_data_url, "data", "nh_data.zip")

# Set up spatial database
puts ">> Setting up database..."
`dropdb broadband_map`
`createdb broadband_map`
`psql broadband_map -c "create extension postgis"`

# Load census block shapefiles with population data into database
puts ">> Loading census blocks..."
`shp2pgsql -s 4269 data/tabblock2010_50_pophu/tabblock2010_50_pophu.shp vt_census_blocks | psql broadband_map`
`shp2pgsql -s 4269 data/tabblock2010_33_pophu/tabblock2010_33_pophu.shp nh_census_blocks | psql broadband_map`

# Load county subdivision shapefiles into database
puts ">> Loading county subdivisions..."
`shp2pgsql -s 4269 data/cb_2017_50_cousub_500k/cb_2017_50_cousub_500k.shp vt_county_subdivisions | psql broadband_map`
`shp2pgsql -s 4269 data/cb_2017_33_cousub_500k/cb_2017_33_cousub_500k.shp nh_county_subdivisions | psql broadband_map`

# Run SQL queries to generate table with county-subdivision-level broadband data
puts ">> Prepping map data..."
`psql -f prepare_data.sql broadband_map`

# Export data to .gpkg file
puts ">> Exporting map data to geopackage..."
`ogr2ogr -f "GPKG" data/county_subdivisions.gpkg PG:"dbname=broadband_map" "county_subdivisions"`
