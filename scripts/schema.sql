-- OldSTL DuckDB Schema
-- Denormalized single table for photo metadata and locations
--
-- Usage:
--   duckdb locations.duckdb < scripts/schema.sql

-- Drop table if exists (for clean re-creation)
DROP TABLE IF EXISTS photos;

-- Create photos table with all metadata in one place
CREATE TABLE photos (
    -- Primary identifier
    id VARCHAR PRIMARY KEY,

    -- Photo metadata
    title VARCHAR NOT NULL,
    description VARCHAR,
    note VARCHAR,
    date VARCHAR,                    -- Display date (e.g., "1965", "1900-1910")
    year INTEGER NOT NULL,           -- Extracted year for filtering/sorting
    folder VARCHAR NOT NULL,         -- Location/folder name (e.g., "Old Courthouse")

    -- Geographic data
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    located_str VARCHAR,             -- Human-readable location description

    -- Date range (for photos spanning multiple years)
    date_start DATE,                 -- ISO date: start of range
    date_end DATE,                   -- ISO date: end of range

    -- Extraction metadata
    technique VARCHAR,               -- How location was determined: 'manual', 'geocoded', etc.

    -- Image reference (Cloudinary ID only, URLs generated dynamically)
    cloudinary_id VARCHAR,           -- Just the ID (e.g., 'STL-0001'), NOT the full URL

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CHECK (year >= 1800 AND year <= 2100),
    CHECK (latitude BETWEEN -90 AND 90),
    CHECK (longitude BETWEEN -180 AND 180)
);

-- Create indexes for common queries
CREATE INDEX idx_photos_year ON photos(year);
CREATE INDEX idx_photos_folder ON photos(folder);
CREATE INDEX idx_photos_location ON photos(latitude, longitude);

-- Create a view for easy GeoJSON-compatible output
CREATE VIEW photos_geojson AS
SELECT
    id,
    title,
    description,
    note,
    date,
    year,
    folder,
    latitude,
    longitude,
    located_str,
    date_start,
    date_end,
    technique,
    cloudinary_id,
    -- Construct Cloudinary URL (replace 'YOUR_CLOUD_NAME' when exporting)
    'https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/v1/stl/historical/' || cloudinary_id || '.jpg' AS url
FROM photos;

-- Display schema info
DESCRIBE photos;

-- Display row count
SELECT COUNT(*) as total_photos FROM photos;
