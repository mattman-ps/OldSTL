# OldSTL Development Workflow

This document describes the day-to-day workflow for managing the OldSTL historical photos project.

## Overview

```text
DuckDB (locations.duckdb)          → Your master database (local only)
    ↓
GeoJSON (src/data/locations.geojson) → Generated for web (committed to git)
    ↓
Cloudinary                          → Image hosting (external service)
    ↓
Leaflet Map                         → Displays on website
```

## Initial Setup (One-time)

### 1. Install DuckDB CLI

```powershell
# Using winget
winget install DuckDB.cli

# OR using chocolatey
choco install duckdb

# OR download from: https://duckdb.org/docs/installation/
```

### 2. Install VS Code Database Client Extension

1. Open VS Code Extensions (`Ctrl+Shift+X`)
2. Search for "Database Client"
3. Install: `cweijan.vscode-database-client2`

### 3. Set Up Cloudinary Account

1. Sign up at <https://cloudinary.com> (free tier)
2. Note your **Cloud Name** from dashboard
3. Create folder: `stl/historical/`

### 4. Migrate Existing Data to DuckDB

```powershell
# Navigate to project root
cd D:\repos\github\OldSTL

# Run migration script
.\scripts\migrate-to-duckdb.ps1
```

This creates `locations.duckdb` from your existing `locations.json`.

## Daily Workflow

### Adding New Photos

#### Step 1: Upload Image to Cloudinary

- Upload to folder: `stl/historical/`
- Name format: `STL-XXXX.jpg` (e.g., `STL-0022.jpg`)
- Note the image ID for database entry

#### Step 2: Add Record to Database

Option A: Using VS Code Database Client Extension

1. Open Database Client sidebar
2. Click "+" → DuckDB
3. Select `locations.duckdb`
4. Right-click `photos` table → Insert Row
5. Fill in fields:
   - `id`: 'STL-0022'
   - `title`: 'Photo Title'
   - `year`: 1965
   - `latitude`: 38.627
   - `longitude`: -90.199
   - `folder`: 'Location Name'
   - `cloudinary_id`: 'STL-0022'
   - Fill other fields as needed

Option B: Using SQL in DuckDB CLI

```powershell
duckdb locations.duckdb
```

```sql
INSERT INTO photos (
    id, title, description, note, date, year, folder,
    latitude, longitude, located_str, cloudinary_id
) VALUES (
    'STL-0022',
    'New Historical Photo',
    '1 photographic print: b&w.',
    'Description of the photo and its historical context.',
    '1965',
    1965,
    'Location Name',
    38.6270,
    -90.1994,
    'Address or location description',
    'STL-0022'
);
```

#### Step 3: Export to GeoJSON

```powershell
# Export all photos
.\scripts\export-geojson.ps1 -CloudName "your-cloudinary-cloud-name"

# OR export filtered by year range
.\scripts\export-geojson.ps1 -CloudName "your-cloud" -MinYear 1900 -MaxYear 1950
```

This generates/updates `src/data/locations.geojson`.

#### Step 4: Deploy

```powershell
# Review changes
git status
git diff src/data/locations.geojson

# Commit GeoJSON (NOT the .duckdb file)
git add src/data/locations.geojson
git commit -m "Add new photos: [brief description]"
git push
```

Render auto-deploys from GitHub - your changes will be live in a few minutes.

### Editing Existing Photos

#### Option 1: VS Code Database Client

1. Open Database Client → `locations.duckdb`
2. Browse to `photos` table
3. Double-click cell to edit
4. Save changes
5. Re-export GeoJSON (Step 3 above)
6. Commit and push

#### Option 2: SQL Update

```powershell
duckdb locations.duckdb
```

```sql
-- Update a photo's information
UPDATE photos
SET title = 'Updated Title',
    note = 'Updated description'
WHERE id = 'STL-0001';

-- Update coordinates
UPDATE photos
SET latitude = 38.6280,
    longitude = -90.1790
WHERE id = 'STL-0005';
```

Then export and deploy as above.

### Deleting Photos

```sql
-- Delete a photo
DELETE FROM photos WHERE id = 'STL-9999';
```

Then export and deploy.

## Common Queries

### View All Photos by Location

```sql
SELECT id, title, year, folder
FROM photos
WHERE folder = 'Old Courthouse'
ORDER BY year;
```

### Find Photos in a Year Range

```sql
SELECT id, title, year
FROM photos
WHERE year BETWEEN 1900 AND 1950
ORDER BY year;
```

### Count Photos by Decade

```sql
SELECT
    (year / 10) * 10 as decade,
    COUNT(*) as photo_count
FROM photos
GROUP BY decade
ORDER BY decade;
```

### Find Photos by Location (Geographic Search)

```sql
-- Photos within ~0.01 degrees (~1km) of a point
SELECT id, title, latitude, longitude
FROM photos
WHERE latitude BETWEEN 38.62 AND 38.64
  AND longitude BETWEEN -90.20 AND -90.18;
```

### List All Unique Locations

```sql
SELECT DISTINCT folder, COUNT(*) as photo_count
FROM photos
GROUP BY folder
ORDER BY photo_count DESC;
```

## File Organization

### Files You Work With

- **`locations.duckdb`** - Your master database (keep local, backup regularly)
- **`src/data/locations.geojson`** - Generated output (commit to git)

### Files to Commit to Git

- ✅ `src/data/locations.geojson` - Generated GeoJSON
- ✅ `src/js/app.js` - Application code
- ✅ `src/css/styles.css` - Styles
- ✅ `index.html` - Main page
- ✅ `scripts/*.ps1` - Build scripts
- ✅ `scripts/schema.sql` - Database schema
- ✅ `docs/*.md` - Documentation

### Files to Keep Local (NOT in git)

- ❌ `locations.duckdb` - Your database
- ❌ `locations.duckdb.wal` - DuckDB write-ahead log
- ❌ `src/data/locations.json` - Legacy (can delete after migration)

### Add to .gitignore

```gitignore
# DuckDB database files
*.duckdb
*.duckdb.wal

# Legacy data
src/data/locations.json
```

## Backup Strategy

### Database Backup

Your DuckDB file should be backed up regularly:

#### Option 1: Manual Backup

```powershell
# Copy database to backup location
Copy-Item locations.duckdb "G:\My Drive\Backups\OldSTL\locations-$(Get-Date -Format 'yyyy-MM-dd').duckdb"
```

#### Option 2: Export to Parquet (archive format)

```powershell
duckdb locations.duckdb
```

```sql
COPY photos TO 'backups/photos-backup.parquet' (FORMAT PARQUET);
```

#### Option 3: Export to CSV (human-readable)

```sql
COPY photos TO 'backups/photos-backup.csv' (FORMAT CSV, HEADER);
```

### Restore from Backup

```powershell
# Restore database file
Copy-Item "G:\My Drive\Backups\OldSTL\locations-2025-11-11.duckdb" locations.duckdb

# OR import from Parquet
duckdb new-database.duckdb
```

```sql
CREATE TABLE photos AS SELECT * FROM 'backups/photos-backup.parquet';
```

## Troubleshooting

### Database is Locked

If you get a "database is locked" error:

- Close all connections to the database
- Close VS Code Database Client
- Restart VS Code
- Delete `locations.duckdb.wal` if present

### GeoJSON Export Failed

- Check that DuckDB CLI is in PATH: `duckdb --version`
- Verify database exists: `Test-Path locations.duckdb`
- Check for SQL errors in export script output
- Ensure output directory exists: `src/data/`

### Photos Not Appearing on Map

- Verify GeoJSON was exported: check file modification time
- Check Cloudinary URLs are correct (cloud name matches)
- Verify image IDs match between database and Cloudinary
- Check browser console for errors
- Verify coordinates are valid (lat: -90 to 90, lng: -180 to 180)

### DuckDB CLI Not Found

```powershell
# Check if installed
duckdb --version

# If not found, install
winget install DuckDB.cli

# Or download from https://duckdb.org/docs/installation/
```

## Quick Reference

### Essential Commands

```powershell
# Export GeoJSON for deployment
.\scripts\export-geojson.ps1 -CloudName "your-cloud-name"

# Open database in CLI
duckdb locations.duckdb

# View table structure
duckdb locations.duckdb -c "DESCRIBE photos"

# Count all photos
duckdb locations.duckdb -c "SELECT COUNT(*) FROM photos"

# Deploy to production
git add src/data/locations.geojson
git commit -m "Update locations"
git push
```

### Database Schema Quick Reference

```text
photos table columns:
- id              VARCHAR (PRIMARY KEY)
- title           VARCHAR (NOT NULL)
- description     VARCHAR
- note            VARCHAR
- date            VARCHAR (display date)
- year            INTEGER (for filtering)
- folder          VARCHAR (location name)
- latitude        DOUBLE (NOT NULL)
- longitude       DOUBLE (NOT NULL)
- located_str     VARCHAR
- date_start      DATE
- date_end        DATE
- technique       VARCHAR
- cloudinary_id   VARCHAR
- created_at      TIMESTAMP
- updated_at      TIMESTAMP
```

## Support Resources

- **DuckDB Documentation**: <https://duckdb.org/docs/>
- **Cloudinary Docs**: <https://cloudinary.com/documentation>
- **Leaflet.js Docs**: <https://leafletjs.com/reference.html>
- **Project GitHub**: <https://github.com/mattman-ps/OldSTL>

## Workflow Checklist

- [ ] Image uploaded to Cloudinary (`stl/historical/STL-XXXX.jpg`)
- [ ] Record added to DuckDB database
- [ ] Coordinates verified (latitude, longitude)
- [ ] Year extracted and set correctly
- [ ] GeoJSON exported (`.\scripts\export-geojson.ps1 -CloudName "cloud"`)
- [ ] Changes tested locally
- [ ] GeoJSON committed to git
- [ ] Pushed to GitHub
- [ ] Verified deployment on Render
