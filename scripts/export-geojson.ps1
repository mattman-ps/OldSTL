# Export DuckDB to GeoJSON
#
# This script exports photos from DuckDB to GeoJSON format for web deployment
#
# Usage:
#   .\scripts\export-geojson.ps1 -CloudName "your-cloud-name"
#   .\scripts\export-geojson.ps1 -CloudName "your-cloud-name" -MinYear 1900 -MaxYear 1950

param(
    [Parameter(Mandatory=$true)]
    [string]$CloudName,

    [Parameter(Mandatory=$false)]
    [string]$InputDb = "locations.duckdb",

    [Parameter(Mandatory=$false)]
    [string]$OutputGeoJSON = "src\data\locations.geojson",

    [Parameter(Mandatory=$false)]
    [int]$MinYear,

    [Parameter(Mandatory=$false)]
    [int]$MaxYear
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OldSTL: Export GeoJSON from DuckDB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if DuckDB CLI is available
Write-Host "Checking DuckDB installation..." -ForegroundColor Yellow
$duckdbCmd = Get-Command duckdb -ErrorAction SilentlyContinue

if (-not $duckdbCmd) {
    Write-Host "Error: DuckDB CLI not found." -ForegroundColor Red
    Write-Host "Please install from: https://duckdb.org/docs/installation/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ DuckDB found" -ForegroundColor Green
Write-Host ""

# Check if database exists
if (-not (Test-Path $InputDb)) {
    Write-Host "Error: Database not found: $InputDb" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run migration first:" -ForegroundColor Yellow
    Write-Host "  .\scripts\migrate-to-duckdb.ps1" -ForegroundColor White
    exit 1
}

$dbSize = (Get-Item $InputDb).Length / 1KB
Write-Host "Input:  $InputDb ($([math]::Round($dbSize, 2)) KB)" -ForegroundColor Cyan
Write-Host "Output: $OutputGeoJSON" -ForegroundColor Cyan
Write-Host "Cloud:  $CloudName" -ForegroundColor Cyan

if ($MinYear -or $MaxYear) {
    Write-Host "Filter: Years $MinYear - $MaxYear" -ForegroundColor Cyan
}

Write-Host ""

# Build SQL query for GeoJSON export
$whereClause = ""
if ($MinYear -or $MaxYear) {
    $conditions = @()
    if ($MinYear) { $conditions += "year >= $MinYear" }
    if ($MaxYear) { $conditions += "year <= $MaxYear" }
    $whereClause = "WHERE " + ($conditions -join " AND ")
}

# Create GeoJSON export query
# Note: GeoJSON coordinates are [longitude, latitude] - reversed from typical lat/lng!
$exportSql = @"
COPY (
    SELECT json_object(
        'type', 'FeatureCollection',
        'features', list(json_object(
            'type', 'Feature',
            'geometry', json_object(
                'type', 'Point',
                'coordinates', [longitude, latitude]
            ),
            'properties', json_object(
                'id', id,
                'title', title,
                'description', description,
                'note', note,
                'date', date,
                'year', year,
                'folder', folder,
                'url', 'https://res.cloudinary.com/$CloudName/image/upload/v1/stl/historical/' || cloudinary_id || '.jpg',
                'date_start', date_start,
                'date_end', date_end,
                'technique', technique,
                'located_str', located_str,
                'extracted', json_object(
                    'latlon', [latitude, longitude],
                    'date_range', [CAST(date_start AS VARCHAR), CAST(date_end AS VARCHAR)],
                    'technique', technique,
                    'located_str', located_str
                )
            )
        ) ORDER BY year, id)
    ) AS geojson
    FROM photos
    $whereClause
) TO '$($OutputGeoJSON.Replace('\', '/'))' (FORMAT JSON);
"@

# Write SQL to temp file
$tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
$exportSql | Out-File -FilePath $tempSqlFile -Encoding UTF8

Write-Host "Exporting GeoJSON..." -ForegroundColor Yellow

try {
    # Execute export
    $sqlContent = Get-Content $tempSqlFile -Raw
    $result = $sqlContent | & duckdb $InputDb -readonly 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Export failed." -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }

    Write-Host "✓ Export complete" -ForegroundColor Green
}
finally {
    Remove-Item $tempSqlFile -Force -ErrorAction SilentlyContinue
}

# Verify output file
if (-not (Test-Path $OutputGeoJSON)) {
    Write-Host "Error: Output file was not created." -ForegroundColor Red
    exit 1
}

# Get statistics
$outputSize = (Get-Item $OutputGeoJSON).Length / 1KB

# Count features in GeoJSON
$geojsonContent = Get-Content $OutputGeoJSON -Raw | ConvertFrom-Json
$featureCount = $geojsonContent.features.Count

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Export Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output file: $OutputGeoJSON" -ForegroundColor Cyan
Write-Host "File size:   $([math]::Round($outputSize, 2)) KB" -ForegroundColor Cyan
Write-Host "Features:    $featureCount photos" -ForegroundColor Cyan
Write-Host ""

# Show sample feature
if ($featureCount -gt 0) {
    $sample = $geojsonContent.features[0]
    Write-Host "Sample feature:" -ForegroundColor Yellow
    Write-Host "  ID:    $($sample.properties.id)" -ForegroundColor White
    Write-Host "  Title: $($sample.properties.title)" -ForegroundColor White
    Write-Host "  Year:  $($sample.properties.year)" -ForegroundColor White
    Write-Host "  URL:   $($sample.properties.url)" -ForegroundColor White
    Write-Host ""
}

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated GeoJSON file" -ForegroundColor White
Write-Host "  2. Test locally with your map application" -ForegroundColor White
Write-Host "  3. Commit and push to deploy:" -ForegroundColor White
Write-Host "       git add $OutputGeoJSON" -ForegroundColor Gray
Write-Host "       git commit -m `"Update locations data`"" -ForegroundColor Gray
Write-Host "       git push" -ForegroundColor Gray
Write-Host ""
