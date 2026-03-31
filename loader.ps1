Clear-Host

# ===== HEADER =====
function Show-Header {
    Write-Host "=====================================" -ForegroundColor DarkCyan
    Write-Host "         REMOTE TOOL LOADER          " -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Pause {
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

# ===== TOOLS LIST =====
# ✅ Make sure no comma after the last item
$tools = @(
    @{
        Name = "USBFix"
        Url  = "https://github.com/<username>/<repo>/releases/download/v1.0/USBFix.exe"
        File = "USBFix.exe"
        Type = "exe"
    },
    @{
        Name = "Tool2"
        Url  = "https://github.com/<username>/<repo>/releases/download/v1.0/Tool2.zip"
        File = "Tool2.zip"
        Type = "zip"
    }
    # Last element — NO COMMA!
)

# ===== DOWNLOAD + RUN FUNCTION =====
function Download-Tool($tool) {
    $OutDir = "$env:USERPROFILE\Downloads\ToolLoader"
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

    $OutFile = "$OutDir\$($tool.File)"

    # Remove existing file
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

    Write-Host ""
    Write-Host "[+] Downloading $($tool.Name)..." -ForegroundColor Yellow

    try {
        Invoke-WebRequest -Uri $tool.Url -OutFile $OutFile -UseBasicParsing
        $size = (Get-Item $OutFile).Length
        Write-Host "[*] Downloaded size: $size bytes"

        if ($size -lt 1000) {
            Write-Host "[!] File too small, download may have failed!" -ForegroundColor Red
            Pause
            return
        }

        Write-Host "[+] Download complete!" -ForegroundColor Green

        if ($tool.Type -eq "exe") {
            Write-Host "[+] Running executable..." -ForegroundColor Cyan
            Start-Process -FilePath $OutFile -WorkingDirectory $OutDir -Wait
        }
        elseif ($tool.Type -eq "zip") {
            Write-Host "[+] Extracting archive..." -ForegroundColor Cyan
            $ExtractDir = "$OutDir\$($tool.File)-extracted"
            if (-not (Test-Path $ExtractDir)) { New-Item -ItemType Directory -Path $ExtractDir | Out-Null }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($OutFile, $ExtractDir)
            Write-Host "[+] Extraction complete." -ForegroundColor Green

            $exe = Get-ChildItem -Path $ExtractDir -Filter *.exe -Recurse | Select-Object -First 1
            if ($exe) {
                Write-Host "[+] Running $($exe.Name) from archive..." -ForegroundColor Cyan
                Start-Process -FilePath $exe.FullName -WorkingDirectory $ExtractDir -Wait
            }
        }
    }
    catch {
        Write-Host "[!] Download or execution failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Pause
}

# ===== PAGED MENU =====
$pageSize = 10
$page = 0
$totalPages = [math]::Ceiling($tools.Count / $pageSize)

while ($true) {
    Clear-Host
    Show-Header
    Write-Host "TOOLS MENU (Page $($page+1)/$totalPages)" -ForegroundColor Green

    $start = $page * $pageSize
    $end = [math]::Min($start + $pageSize - 1, $tools.Count - 1)

    for ($i = $start; $i -le $end; $i++) {
        Write-Host "$($i+1). $($tools[$i].Name)"
    }

    Write-Host "`nn. Next page | p. Previous page | 0. Exit"
    $choice = Read-Host "Select tool"

    if ($choice -eq "0") { break }
    elseif ($choice -eq "n" -and $page -lt $totalPages - 1) { $page++ }
    elseif ($choice -eq "p" -and $page -gt 0) { $page-- }
    elseif ($choice -match "^\d+$") {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Download-Tool $tools[$index]
        }
    }
}
