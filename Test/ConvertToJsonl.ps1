param (
    [Parameter()]
    [string]$SourceDir = "Test Cases/source",
    [Parameter()]
    [string]$OutDir = "Test Cases/out"
)

# Get the root directory (where the script is being run from)
$rootDir = Get-Location

# Create absolute paths
$SourceDirFull = Join-Path -Path $rootDir -ChildPath $SourceDir
$OutDirFull = Join-Path -Path $rootDir -ChildPath $OutDir

# Check if directories exist
if (-not (Test-Path -Path $SourceDirFull -PathType Container)) {
    Write-Host "Source directory does not exist: $SourceDirFull" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $OutDirFull -PathType Container)) {
    Write-Host "Output directory does not exist: $OutDirFull, creating it..." -ForegroundColor Yellow
    New-Item -Path $OutDirFull -ItemType Directory -Force | Out-Null
}

Write-Host "Converting JSON files from $SourceDirFull to JSONL in $OutDirFull"

# Process all subdirectories in the source directory
function Process-Directory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirPath
    )

    Write-Host "Processing directory: $DirPath"

    # Skip if directory doesn't exist
    if (-not (Test-Path -Path $DirPath -PathType Container)) {
        Write-Host "Directory does not exist: $DirPath" -ForegroundColor Yellow
        return
    }

    $relativePath = $DirPath.Substring($SourceDirFull.Length).TrimStart('\').TrimStart('/')
    $outDirPath = Join-Path -Path $OutDirFull -ChildPath $relativePath

    # Create output directory if it doesn't exist
    if (-not (Test-Path -Path $outDirPath)) {
        New-Item -Path $outDirPath -ItemType Directory -Force | Out-Null
        Write-Host "  Created directory: $outDirPath"
    }

    # Get all JSON files in this directory
    $jsonFiles = Get-ChildItem -Path $DirPath -Filter "*.json"
    Write-Host "  Found $($jsonFiles.Count) JSON files"

    # Process each JSON file individually
    foreach ($file in $jsonFiles) {
        Write-Host "  Processing file: $($file.FullName)"
        
        # Get file content
        $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        
        # Create output file name (same name but with .jsonl extension)
        $outFileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".jsonl"
        $outFilePath = Join-Path -Path $outDirPath -ChildPath $outFileName
        
        # Build the JSONL content
        $jsonlContent = ""
        
        # Check if the content has a testCases property
        if ($content.PSObject.Properties.Name -contains "testCases") {
            foreach ($testCase in $content.testCases) {
                $jsonLine = ConvertTo-Json -InputObject $testCase -Compress
                $jsonlContent += "$jsonLine`n"
            }
        } else {
            # If not, treat the entire content as a single item or array
            if ($content -is [System.Array]) {
                foreach ($item in $content) {
                    $jsonLine = ConvertTo-Json -InputObject $item -Compress
                    $jsonlContent += "$jsonLine`n"
                }
            } else {
                $jsonLine = ConvertTo-Json -InputObject $content -Compress
                $jsonlContent += "$jsonLine`n"
            }
        }
        
        # Remove the trailing newline
        $jsonlContent = $jsonlContent.TrimEnd("`n")
        
        # Write to file
        Set-Content -Path $outFilePath -Value $jsonlContent -NoNewline
        Write-Host "  Created JSONL file: $outFilePath"
    }

    # Process subdirectories
    $subdirs = Get-ChildItem -Path $DirPath -Directory
    foreach ($subdir in $subdirs) {
        Process-Directory -DirPath $subdir.FullName
    }
}

# Start processing from the source directory
Process-Directory -DirPath $SourceDirFull

Write-Host "Conversion completed successfully!" 