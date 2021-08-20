# Specify source directories.
$sourceDirs = @(
    # 'C:\path\to\source folder'
    # 'C:\path\to\source folder 2'
)

# Specify other directories (i.e. directories that might contain duplicates).
$otherDirs = @(
    # May be the same as source directories (if you are looking for duplicates within only source directories).
    # 'C:\path\to\source folder'
    # 'C:\path\to\source folder 2'

    # Or else specify other folders
    # 'C:\path\to\other folder'
    # 'C:\path\to\other folder 2'
)

# Specify the duplicate criteria.
# If you a criteria that includes all criteria, enter the sum of all numbers. E.g. If I want all the criteria, the value will be 1 + 2 + 4 + 8 = 15
# 1 - Same file name
# 2 - Same file size
# 4 - Same file hash
# 8 - Same date modified
$criteria = 15

function Get-FileMetaData {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $File
    ,
        [Parameter()]
        [ValidateRange(1,15)]
        [int]
        $Criteria
    )

    process {
        # Get file objects from an existing .json, or else create the file objects
        foreach ($f in $File) {

            $o = [ordered]@{
                FullName = $f.FullName
            }
            $key = ''

            if ($Criteria -band 1) {
                $key += "-$( $f.Name )"
            }

            if ($Criteria -band 2) {
                $key += "-$( $f.Length )"
            }

            if ($Criteria -band 4) {
                $hash = Get-FileHash $File.FullName -Algorithm SHA256 | Select-Object -ExpandProperty 'Hash'
                $key += "-$hash"
                $o['Hash'] = $hash
            }

            if ($Criteria -band 8) {
                $dateIso = Get-Date -Date $File.LastWriteTimeUtc -Format 'yyyy-MM-dd HH:mm:ss zz00'
                $key += "-$dateIso"
                $o['LastWriteTimeUtcIso'] = $dateIso
            }

            $key = $key -replace '^-', ''
            $o['key'] = $key

            $o -as [pscustomobject] # Send this immediately down the pipeline
        }
    }
}

Set-StrictMode -Version Latest

# Normalize, compile, validate configuration
$sourceDirs = @( $sourceDirs | % { $_.Trim() } | ? { $_ } )
if ($sourceDirs.Count -eq 0) {
    "No source directories specified." | Write-Warning
    return
}
$otherDirs = @( $otherDirs | % { $_.Trim() } | ? { $_ } )
if ($otherDirs.Count -eq 0) {
    "No other directories specified." | Write-Warning
    return
}
if (!$criteria) {
    "No criteria specified" | Write-Warning
    return
}

# Get source items
$sourceFiles = [ordered]@{}
$sourceDirs | ForEach-Object {
    "`nProcessing source directory $( $_ )" | Write-Host -ForegroundColor Cyan
    Get-ChildItem -LiteralPath $_ -File -Force -Recurse | Sort-Object -Property 'FullName' | Get-FileMetaData -Criteria $criteria | % {
        $s = $_
        if (! $sourceFiles.Contains($s.key)) {
            $sourceFiles[$s.key] = $s # There may only be one unique source file
        }else {
            "Ignoring a duplicate file in source directory. file: `n$( $sourceFiles[$s.key].FullName ), duplicate: $( $s.FullName )" | Write-Verbose
        }
    }
}
# Get other items
$otherFiles = [ordered]@{}
$otherDirs | ForEach-Object {
    "`nProcessing other directory $( $_ )" | Write-Host -ForegroundColor Cyan
    Get-ChildItem -LiteralPath $_ -File -Force -Recurse | Sort-Object -Property 'FullName' | Get-FileMetaData -Criteria $criteria | % {
        $o = $_
        if (! $otherFiles.Contains($o.key)) {
            $otherFiles[$o.key] = @() # There may be more than one other file
        }
        $otherFiles[$o.key] += $o
    }
}

# Get duplicates
$dups = [ordered]@{}
foreach ($k in $otherFiles.Keys) {
    if ($sourceFiles.Contains($k)) {
        $s = $sourceFiles[$k]
        foreach ($o in $otherFiles[$k]) {
            if ($s.FullName -ne $o.FullName) {
                "File $( $o.FullName ) is a duplicate of $( $s.FullName )" | Write-Host -ForegroundColor Green
                if (!$dups.Contains($k)) {
                    $dups[$k] = @( $s.FullName ) # Source file is always the first object in the array
                }
                $dups[$k] += $o.FullName
            }
        }
    }
}

# Export duplicates to json
$jsonFile = Join-Path $PWD 'duplicates.json'
$dups | ConvertTo-Json -Depth 100 | Out-File $jsonFile -Encoding utf8
"Exporting duplicates to $jsonFile" | Write-Host -ForegroundColor Green

# Now you can do whatever you want with the duplicates, e.g.
# $dups = Get-Content $jsonFile -Encoding utf8 -raw | ConvertFrom-Json
# $dups.psobject.Properties | % {
#     $key = $_.Name
#     $value = $_.Value
#     $sourceFile = $value[0]
#     $duplicateFiles = $value[1..($value.Count - 1)] # Ignore the first object
#     foreach ($f in $duplicateFiles) {
#         # Do something
#     }
# }
