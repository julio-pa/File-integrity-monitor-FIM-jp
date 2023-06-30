
Write-Host ""
Write-Host "what would you like do?"
Write-Host "    A) Collect new Baseline"
Write-Host "    B) Begin monitoring files with saved Baseline"
Write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        #Delete it
        Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    #Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists

    #Calculate Hash forn the target files and store in baseline.txt

    #Collect all files in the target folder
    $files = Get-ChildItem -Path .\files 
    $files

    #For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File  -FilePath .\baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()){
    
    $fileHashDictionary = @{}
    
    #Load file|hash from baseline.txt and store them in a dictionary
    $filePathAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0], $f.Split("|")[1])
    }

    #Begin (continously) monitoring files with sved Baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\files

        #For each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File  -FilePath .\baseline.txt -Append

            #Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null){
                #A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            # Notify if a new file has been changed
            if ($fileHashDictionary[$hash.Path]-eq $hash.Hash){
                # The file has not changed
            }
            else {
                # The file has been compromised, notify the user
                Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
            }
        }
        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if(-Not $baselineFileStillExists) {
                #One of the baseline files must have been deleted, notify the user
                write-Host "$($key) has been deleted" -ForegroundColor Red
            }
        }
    }
}