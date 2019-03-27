DROP TABLE IF EXISTS broadband_data;
DROP TABLE IF EXISTS census_block_data;
DROP TABLE IF EXISTS census_blocks;
DROP TABLE IF EXISTS county_subdivision_data;
DROP TABLE IF EXISTS county_subdivisions;

-- Create table to hold broadband data based on CSV structure
CREATE TABLE broadband_data (
  LogRecNo           varchar(255),
  Provider_Id        varchar(255),
  FRN                varchar(255),
  ProviderName       varchar(255),
  DBAName            varchar(255),
  HoldingCompanyName varchar(255),
  HocoNum            varchar(255),
  HocoFinal          varchar(255),
  StateAbbr          varchar(2),
  BlockCode          varchar(255),
  TechCode           varchar(255),
  Consumer           varchar(255),
  MaxAdDown          numeric,
  MaxAdUp            numeric,
  Business           varchar(255),
  MaxCIRDown         varchar(255),
  MaxCIRUp           varchar(255)
);

-- Import broadband data from CSVs
\COPY broadband_data(LogRecNo, Provider_Id, FRN, ProviderName, DBAName, HoldingCompanyName, HocoNum, HocoFinal, StateAbbr, BlockCode, TechCode, Consumer, MaxAdDown, MaxAdUp, Business, MaxCIRDown, MaxCIRUp) FROM 'data/VT-Fixed-Dec2017-v1.csv' DELIMITER ',' CSV header;
\COPY broadband_data(LogRecNo, Provider_Id, FRN, ProviderName, DBAName, HoldingCompanyName, HocoNum, HocoFinal, StateAbbr, BlockCode, TechCode, Consumer, MaxAdDown, MaxAdUp, Business, MaxCIRDown, MaxCIRUp) FROM 'data/NH-Fixed-Dec2017-v1.csv' DELIMITER ',' CSV header;

-- Union VT and NH census block data into one table
CREATE TABLE census_block_data AS
(SELECT * FROM vt_census_blocks UNION SELECT * FROM nh_census_blocks);

-- Copy data into new table with more consistent fieldnames
-- Add two fields for broadband speed and county subdivision foreign key
-- Calculate centroid for use in spatial join with county subdivisions
CREATE TABLE census_blocks AS
(SELECT *,
  blockid10 AS blockcode,
  pop10 AS population,
  0.0 AS maxadup,
  NULL AS cousubfp,
  ST_Centroid(geom) AS center
FROM census_block_data);

-- Update "center" point when centroid is not on the surface of the block
UPDATE census_blocks SET center = ST_PointOnSurface(geom)
WHERE NOT ST_Contains(geom, center);

-- Create indexes to speed up join on large broadband_data table
CREATE INDEX idx_broadband_data_blockcode ON broadband_data(blockcode);
CREATE INDEX idx_census_blocks_blockcode ON census_blocks(blockcode);

-- Set census block max upload speed based on broadband data table
UPDATE census_blocks SET maxadup =
(SELECT max(maxadup) FROM broadband_data WHERE census_blocks.blockcode = broadband_data.blockcode);

-- Union VT and NH county subdivision data into one table
CREATE TABLE county_subdivision_data AS
(SELECT * FROM vt_county_subdivisions UNION SELECT * FROM nh_county_subdivisions);

-- Copy data into new table, adding field for broadband speed
CREATE TABLE county_subdivisions AS
(SELECT *, 0.0 AS maxadup FROM county_subdivision_data);

-- Reset IDs to address duplicates caused by union
CREATE SEQUENCE county_subdivisions_gid_seq START 1;
UPDATE county_subdivisions SET gid = nextval('county_subdivisions_gid_seq');

-- Perform a spatial join to link census blocks with county subdivisions
-- Use center point because boundaries do not match up nicely
UPDATE census_blocks SET cousubfp =
(SELECT cousubfp FROM county_subdivisions WHERE ST_Contains(county_subdivisions.geom, census_blocks.center));

-- Check how many census blocks were successfully linked
-- SELECT count(*) FROM census_blocks WHERE cousubfp IS NULL;

-- Determine max advertised upload speed in each county subdivision
-- based on the average block level upload speed, weighted by population
-- rounded to 3 decimal places, to match the precision of the source data
UPDATE county_subdivisions SET maxadup =
(SELECT ROUND(sum(maxadup * population) / sum(NULLIF(population, 0)), 3)
  FROM census_blocks
  WHERE county_subdivisions.cousubfp = census_blocks.cousubfp
  GROUP BY cousubfp);
