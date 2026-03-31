Clear-Host

# ===== HEADER =====
function Show-Header {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "         EPSON RESETTER ONLINE           " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Pause {
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

# ===== TOOLS LIST =====
$tools = @(
    @{Name="USBFix"; Url="https://github.com/<username>/<repo>/releases/download/v1.0/USBFix.exe"; File="USBFix.exe"; Type="exe"},
    @{Name="Tool2"; Url="https://github.com/<username>/<repo>/releases/download/v1.0/Tool2.zip"; File="Tool2.zip"; Type="zip"}
)

# ===== DOWNLOAD + RUN FUNCTION =====
function Download-Tool($tool) {
    $OutDir = "$env:USERPROFILE\Downloads\EpsonResetterTools"
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

    $OutFile = "$OutDir\$($tool.File)"
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

    Write-Host ""
    Write-Host "[+] Downloading $($tool.Name)..." -ForegroundColor Yellow

    try {
        Invoke-WebRequest -Uri $tool.Url -OutFile $OutFile -UseBasicParsing
        $size = (Get-Item $OutFile).Length
        Write-Host "[*] Downloaded size: $size bytes"

        if ($size -lt 1000) {
            Write-Host "[!] Downloaded file may be incomplete!" -ForegroundColor Red
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
                Write-Host "[+] Running $($exe.Name)..." -ForegroundColor Cyan
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

# ===== MENU =====
while ($true) {
    Clear-Host
    Show-Header
    Write-Host "TOOLS MENU" -ForegroundColor Green
    Write-Host "----------------------------------------" -ForegroundColor DarkGray

    for ($i = 0; $i -lt $tools.Count; $i++) {
        Write-Host "$($i+1). $($tools[$i].Name)" -ForegroundColor White
    }

    Write-Host "0. Exit" -ForegroundColor Yellow
    $choice = Read-Host "`nSelect tool"

    if ($choice -eq "0") { break }

    if ($choice -match "^\d+$") {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Download-Tool $tools[$index]
        }
    }
}
