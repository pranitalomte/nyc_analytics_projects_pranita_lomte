>-
  -- Clean and standardize Open Restaurant Applications data -- One row per
  application

  WITH source AS ( SELECT * FROM {{ source('raw',
  'open_restaurant_applications') }} ),

  cleaned AS ( SELECT -- Keep everything except fields we want to clean * EXCEPT
  ( objectid, submission_timestamp, restaurant_name, legal_business_name,
  doing_business_as_dba, borough, building_number, street, zip, latitude,
  longitude ),

  -- Identifier CAST(objectid AS STRING) AS application_id,

  -- Timestamp CAST(submission_timestamp AS TIMESTAMP) AS submission_timestamp,

  -- Business info CAST(restaurant_name AS STRING) AS restaurant_name,
  CAST(legal_business_name AS STRING) AS legal_business_name,
  CAST(doing_business_as_dba AS STRING) AS dba_name,

  -- Clean borough (same logic as 311) CASE WHEN UPPER(TRIM(borough)) IN
  ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan' WHEN UPPER(TRIM(borough)) IN
  ('BRONX', 'THE BRONX') THEN 'Bronx' WHEN UPPER(TRIM(borough)) IN ('BROOKLYN',
  'KINGS COUNTY') THEN 'Brooklyn' WHEN UPPER(TRIM(borough)) IN ('QUEENS',
  'QUEEN', 'QUEENS COUNTY') THEN 'Queens' WHEN UPPER(TRIM(borough)) IN ('STATEN
  ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island' ELSE 'UNKNOWN' END AS
  borough,

  -- Address CAST(building_number AS STRING) AS building_number, CAST(street AS
  STRING) AS street,

  -- Clean ZIP (reuse logic from 311) CASE WHEN UPPER(TRIM(zip)) IN ('N/A',
  'NA') THEN NULL WHEN LENGTH(TRIM(zip)) = 5 THEN TRIM(zip) WHEN
  LENGTH(TRIM(zip)) = 9 THEN TRIM(zip) WHEN LENGTH(TRIM(zip)) = 10 AND
  REGEXP_CONTAINS(zip, r'^\d{5}-\d{4}') THEN zip ELSE NULL END AS zip,

  -- Location CAST(latitude AS DECIMAL) AS latitude, CAST(longitude AS DECIMAL)
  AS longitude,

  -- Metadata CURRENT_TIMESTAMP() AS _stg_loaded_at

  FROM source

  -- Basic filtering (lighter than 311) WHERE objectid IS NOT NULL AND
  submission_timestamp IS NOT NULL

  -- Deduplication QUALIFY ROW_NUMBER() OVER ( PARTITION BY objectid ORDER BY
  submission_timestamp DESC ) = 1 )

  SELECT * FROM cleaned