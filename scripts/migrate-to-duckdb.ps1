# Migrate JSON locations to DuckDB
#
# This script converts your existing locations.json to a DuckDB database
#
# Usage:
#   .\scripts\migrate-to-duckdb.ps1 [-InputJson "src/data/locations.json"] [-OutputDb "locations.duckdb"]

param(
    [Parameter(Mandatory=$false)]
    [string]$InputJson = "src\data\locations.json",

    [Parameter(Mandatory=$false)]
    [string]$OutputDb = "locations.duckdb",

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OldSTL: Migrate JSON to DuckDB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if DuckDB CLI is available
Write-Host "Checking DuckDB installation..." -ForegroundColor Yellow
$duckdbCmd = Get-Command duckdb -ErrorAction SilentlyContinue

if (-not $duckdbCmd) {
    Write-Host "Error: DuckDB CLI not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install DuckDB:" -ForegroundColor Yellow
    Write-Host "  - Download from: https://duckdb.org/docs/installation/" -ForegroundColor White
    Write-Host "  - Or use: winget install DuckDB.cli" -ForegroundColor White
    Write-Host "  - Or use: choco install duckdb" -ForegroundColor White
    exit 1
}

$duckdbVersion = & duckdb --version
Write-Host "Found: DuckDB $duckdbVersion" -ForegroundColor Green
Write-Host ""

# Check if input JSON exists
if (-not (Test-Path $InputJson)) {
    Write-Host "Error: Input JSON file not found: $InputJson" -ForegroundColor Red
    exit 1
}

$jsonSize = (Get-Item $InputJson).Length / 1KB
Write-Host "Input:  $InputJson ($([math]::Round($jsonSize, 2)) KB)" -ForegroundColor Cyan

# Check if output DB already exists
if ((Test-Path $OutputDb) -and -not $Force) {
    Write-Host "Warning: Database already exists: $OutputDb" -ForegroundColor Yellow
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -ne 'y') {
        Write-Host "Migration cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $OutputDb -Force
}

# Create schema
Write-Host ""
Write-Host "Creating database schema..." -ForegroundColor Yellow

$schemaContent = Get-Content "scripts\schema.sql" -Raw
$schemaResult = $schemaContent | duckdb $OutputDb

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to create schema." -ForegroundColor Red
    Write-Host $schemaResult -ForegroundColor Red
    exit 1
}

Write-Host "✓ Schema created" -ForegroundColor Green

# Load and parse JSON
Write-Host ""
Write-Host "Loading JSON data..." -ForegroundColor Yellow

$jsonData = Get-Content $InputJson -Raw | ConvertFrom-Json
$recordCount = $jsonData.Count

Write-Host "✓ Loaded $recordCount records" -ForegroundColor Green

# Generate SQL INSERT statements
Write-Host ""
Write-Host "Migrating data to DuckDB..." -ForegroundColor Yellow

$insertSql = @"
-- Insert data from JSON migration
BEGIN TRANSACTION;

"@

foreach ($record in $jsonData) {
    # Extract year from date_range or date field
    $year = 1900
    $dateStart = $null
    $dateEnd = $null

    if ($record.extracted -and $record.extracted.date_range -and $record.extracted.date_range.Count -gt 0) {
        $dateStartStr = $record.extracted.date_range[0]
        if ($dateStartStr) {
            $year = [int]$dateStartStr.Substring(0, 4)
            $dateStart = $dateStartStr
        }
        if ($record.extracted.date_range.Count -gt 1) {
            $dateEnd = $record.extracted.date_range[1]
        }
    }
    elseif ($record.date) {
        $year = [int]$record.date.Substring(0, 4)
    }

    # Extract coordinates
    $lat = 0.0
    $lng = 0.0
    if ($record.extracted -and $record.extracted.latlon -and $record.extracted.latlon.Count -eq 2) {
        $lat = $record.extracted.latlon[0]
        $lng = $record.extracted.latlon[1]
    }

    # Extract other fields
    $technique = if ($record.extracted.technique) { $record.extracted.technique } else { $null }
    $locatedStr = if ($record.extracted.located_str) { $record.extracted.located_str } else { $null }

    # Escape single quotes in strings
    $title = $record.title -replace "'", "''"
    $description = if ($record.description) { $record.description -replace "'", "''" } else { "" }
    $note = if ($record.note) { $record.note -replace "'", "''" } else { "" }
    $folder = if ($record.folder) { $record.folder -replace "'", "''" } else { "Unknown" }
    $locatedStrEscaped = if ($locatedStr) { $locatedStr -replace "'", "''" } else { "" }

    # Use ID as cloudinary_id (remove any URL parts if present)
    $cloudinaryId = $record.id

    # Build INSERT statement
    $insertSql += @"
INSERT INTO photos (id, title, description, note, date, year, folder, latitude, longitude, located_str, date_start, date_end, technique, cloudinary_id)
VALUES (
    '$($record.id)',
    '$title',
    '$description',
    '$note',
    '$($record.date)',
    $year,
    '$folder',
    $lat,
    $lng,
    $(if ($locatedStr) { "'$locatedStrEscaped'" } else { "NULL" }),
    $(if ($dateStart) { "'$dateStart'" } else { "NULL" }),
    $(if ($dateEnd) { "'$dateEnd'" } else { "NULL" }),
    $(if ($technique) { "'$technique'" } else { "NULL" }),
    '$cloudinaryId'
);

"@
}

$insertSql += @"
COMMIT;

-- Show results
SELECT COUNT(*) as total_records FROM photos;
SELECT year, COUNT(*) as count FROM photos GROUP BY year ORDER BY year;
"@

# Write SQL to temp file and execute
$tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
$insertSql | Out-File -FilePath $tempSqlFile -Encoding UTF8

try {
    $sqlContent = Get-Content $tempSqlFile -Raw
    $result = $sqlContent | duckdb $OutputDb

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to insert data." -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }

    Write-Host "✓ Data migrated successfully" -ForegroundColor Green
}
finally {
    Remove-Item $tempSqlFile -Force -ErrorAction SilentlyContinue
}

# Show database statistics
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Migration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$dbSize = (Get-Item $OutputDb).Length / 1KB
Write-Host "Database: $OutputDb ($([math]::Round($dbSize, 2)) KB)" -ForegroundColor Cyan
Write-Host ""

# Query database for summary
$summary = & duckdb $OutputDb -c "SELECT COUNT(*) as total, MIN(year) as min_year, MAX(year) as max_year, COUNT(DISTINCT folder) as locations FROM photos" -readonly

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host $summary
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Install VS Code Database Client extension" -ForegroundColor White
Write-Host "  2. Open $OutputDb in the extension to view/edit data" -ForegroundColor White
Write-Host "  3. Run: .\scripts\export-geojson.ps1 -CloudName YOUR_CLOUD_NAME" -ForegroundColor White
Write-Host ""
