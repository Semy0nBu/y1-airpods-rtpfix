param(
    [Parameter(Mandatory = $true)]
    [string]$OriginalSystemImg,

    [string]$AndroidNdkRoot = $env:ANDROID_NDK_ROOT,

    [string]$OutputDir = ".\out",

    [string]$WorkDir = ".\work",

    [switch]$SkipBuild,

    [string]$ProxyPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function Resolve-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function ConvertTo-WslPath {
    param([Parameter(Mandatory = $true)][string]$WindowsPath)

    $FullPath = [System.IO.Path]::GetFullPath($WindowsPath)
    try {
        $Converted = (& wsl wslpath -a $FullPath 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($Converted)) {
            return $Converted.Trim()
        }
    } catch {
        # Fall back to simple drive-letter conversion below.
    }

    if ($FullPath -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Cannot convert Windows path to WSL path: $FullPath"
    }

    $Drive = $Matches[1].ToLowerInvariant()
    $Rest = $Matches[2] -replace '\\', '/'
    return "/mnt/$Drive/$Rest"
}

function Quote-Bash {
    param([Parameter(Mandatory = $true)][string]$Value)
    return "'" + $Value.Replace("'", "'\''") + "'"
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-Host $Description
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE"
    }
}

function Invoke-WslChecked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Invoke-Checked -FilePath "wsl" -Arguments @("sh", "-lc", $Command) -Description $Description
}

function Invoke-DebugfsRead {
    param(
        [Parameter(Mandatory = $true)][string]$ImageWsl,
        [Parameter(Mandatory = $true)][string]$DebugfsCommand,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $Command = "debugfs -R " + (Quote-Bash $DebugfsCommand) + " " + (Quote-Bash $ImageWsl)
    Invoke-WslChecked -Command $Command -Description $Description
}

function Invoke-DebugfsWrite {
    param(
        [Parameter(Mandatory = $true)][string]$ImageWsl,
        [Parameter(Mandatory = $true)][string]$DebugfsCommand,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $Command = "debugfs -w -R " + (Quote-Bash $DebugfsCommand) + " " + (Quote-Bash $ImageWsl)
    Invoke-WslChecked -Command $Command -Description $Description
}

function Remove-ImagePathIfPresent {
    param(
        [Parameter(Mandatory = $true)][string]$ImageWsl,
        [Parameter(Mandatory = $true)][string]$PathInImage
    )

    $Command = "debugfs -w -R " + (Quote-Bash "rm $PathInImage") + " " + (Quote-Bash $ImageWsl) + " >/dev/null 2>&1 || true"
    Invoke-WslChecked -Command $Command -Description "Remove existing $PathInImage from copied image if present"
}

function Write-ImageFile {
    param(
        [Parameter(Mandatory = $true)][string]$ImageWsl,
        [Parameter(Mandatory = $true)][string]$SourceWsl,
        [Parameter(Mandatory = $true)][string]$PathInImage
    )

    Invoke-DebugfsWrite -ImageWsl $ImageWsl -DebugfsCommand "write $SourceWsl $PathInImage" -Description "Write $PathInImage"
    Invoke-DebugfsWrite -ImageWsl $ImageWsl -DebugfsCommand "set_inode_field $PathInImage mode 0100644" -Description "Set mode 0644 on $PathInImage"
    Invoke-DebugfsWrite -ImageWsl $ImageWsl -DebugfsCommand "set_inode_field $PathInImage uid 0" -Description "Set uid 0 on $PathInImage"
    Invoke-DebugfsWrite -ImageWsl $ImageWsl -DebugfsCommand "set_inode_field $PathInImage gid 0" -Description "Set gid 0 on $PathInImage"
}

function Assert-Sha256Match {
    param(
        [Parameter(Mandatory = $true)][string]$ExpectedPath,
        [Parameter(Mandatory = $true)][string]$ActualPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $ExpectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ExpectedPath).Hash.ToLowerInvariant()
    $ActualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ActualPath).Hash.ToLowerInvariant()
    if ($ExpectedHash -ne $ActualHash) {
        throw "$Label hash mismatch. expected=$ExpectedHash actual=$ActualHash"
    }
    Write-Host "$Label SHA256 verified: $ActualHash"
}

function Find-AndroidClang {
    param([Parameter(Mandatory = $true)][string]$NdkRoot)

    $Candidates = @(
        (Join-Path $NdkRoot "toolchains\llvm\prebuilt\windows-x86_64\bin\clang.cmd"),
        (Join-Path $NdkRoot "toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"),
        (Join-Path $NdkRoot "toolchains\llvm\prebuilt\windows\bin\clang.cmd"),
        (Join-Path $NdkRoot "toolchains\llvm\prebuilt\windows\bin\clang.exe")
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    throw "Unable to find Android NDK clang under $NdkRoot"
}

$RepoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")

Write-Host "Innioasis Y1 AirPods 2 system.img patch-kit helper"
Write-Host "This script prepares files only. It does not use adb, does not flash, and does not touch a device."

Write-Step "Checking inputs"
$OriginalSystemImgPath = Resolve-RepoPath $OriginalSystemImg
if (-not (Test-Path -LiteralPath $OriginalSystemImgPath)) {
    throw "OriginalSystemImg not found: $OriginalSystemImgPath"
}

if ($SkipBuild) {
    if ([string]::IsNullOrWhiteSpace($ProxyPath)) {
        throw "-ProxyPath is required when -SkipBuild is used."
    }
    $ProxyInputPath = Resolve-RepoPath $ProxyPath
    if (-not (Test-Path -LiteralPath $ProxyInputPath)) {
        throw "ProxyPath not found: $ProxyInputPath"
    }
} else {
    if ([string]::IsNullOrWhiteSpace($AndroidNdkRoot)) {
        throw "Android NDK is required unless -SkipBuild is used. Pass -AndroidNdkRoot or set ANDROID_NDK_ROOT."
    }
    $AndroidNdkRoot = [System.IO.Path]::GetFullPath($AndroidNdkRoot)
    if (-not (Test-Path -LiteralPath $AndroidNdkRoot)) {
        throw "Android NDK root not found: $AndroidNdkRoot"
    }
}

Write-Step "Checking WSL and required Linux tools"
Invoke-WslChecked -Command "uname -a" -Description "Check WSL"
Invoke-WslChecked -Command "command -v debugfs >/dev/null && command -v e2fsck >/dev/null && command -v sha256sum >/dev/null" -Description "Check WSL tools: debugfs, e2fsck, sha256sum"

Write-Step "Preparing local folders"
$OutputDirPath = Resolve-RepoPath $OutputDir
$WorkDirPath = Resolve-RepoPath $WorkDir
$VerifyDirPath = Join-Path $WorkDirPath "verify"
New-Item -ItemType Directory -Path $OutputDirPath -Force | Out-Null
New-Item -ItemType Directory -Path $WorkDirPath -Force | Out-Null
New-Item -ItemType Directory -Path $VerifyDirPath -Force | Out-Null

$PatchedImagePath = Join-Path $OutputDirPath "system_airpods2_fixed.img"
$OfficialLibPath = Join-Path $WorkDirPath "libbluetoothdrv.so.official_original"
$ProxyWorkPath = Join-Path $WorkDirPath "libbluetoothdrv.so.proxy"
$DumpedProxyPath = Join-Path $VerifyDirPath "libbluetoothdrv.so.from_img"
$DumpedRealPath = Join-Path $VerifyDirPath "libbluetoothdrv_real.so.from_img"

Write-Step "Copying official system.img to output image"
Copy-Item -LiteralPath $OriginalSystemImgPath -Destination $PatchedImagePath -Force
Write-Host "Patched image working copy: $PatchedImagePath"

$PatchedImageWsl = ConvertTo-WslPath $PatchedImagePath
$OfficialLibWsl = ConvertTo-WslPath $OfficialLibPath
$ProxyWorkWsl = ConvertTo-WslPath $ProxyWorkPath
$DumpedProxyWsl = ConvertTo-WslPath $DumpedProxyPath
$DumpedRealWsl = ConvertTo-WslPath $DumpedRealPath

Write-Step "Extracting original official Bluetooth driver from copied image"
if (Test-Path -LiteralPath $OfficialLibPath) {
    Remove-Item -LiteralPath $OfficialLibPath -Force
}
Invoke-DebugfsRead -ImageWsl $PatchedImageWsl -DebugfsCommand "dump /lib/libbluetoothdrv.so $OfficialLibWsl" -Description "Dump /lib/libbluetoothdrv.so from copied image"

if (-not (Test-Path -LiteralPath $OfficialLibPath)) {
    throw "Failed to extract original /lib/libbluetoothdrv.so from image."
}

if ($SkipBuild) {
    Write-Step "Using existing local proxy binary"
    Copy-Item -LiteralPath $ProxyInputPath -Destination $ProxyWorkPath -Force
    Write-Host "Copied proxy to work file: $ProxyWorkPath"
} else {
    Write-Step "Building RTP timestamp fix proxy locally"
    $SourcePath = Join-Path $RepoRoot "src\libbluetoothdrv_proxy\libbluetoothdrv_proxy.c"
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Proxy source not found: $SourcePath"
    }

    $Clang = Find-AndroidClang -NdkRoot $AndroidNdkRoot
    $Args = @(
        "--target=armv7a-linux-androideabi16",
        "-shared",
        "-fPIC",
        "-O2",
        "-DENABLE_BT_SETCONFIG_REWRITE=0",
        "-DENABLE_RTP_TIMESTAMP_FIX=1",
        "-DENABLE_VERBOSE_BT_MEDIA_LOG=0",
        "-Wl,-soname,libbluetoothdrv.so",
        "-o",
        $ProxyWorkPath,
        $SourcePath,
        "-llog",
        "-ldl"
    )

    Write-Host "$Clang $($Args -join ' ')"
    & $Clang @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Android NDK clang failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $ProxyWorkPath)) {
    throw "Proxy output not found: $ProxyWorkPath"
}

Write-Step "Patching copied system image"
Remove-ImagePathIfPresent -ImageWsl $PatchedImageWsl -PathInImage "/lib/libbluetoothdrv.so"
Remove-ImagePathIfPresent -ImageWsl $PatchedImageWsl -PathInImage "/lib/libbluetoothdrv_real.so"
Write-ImageFile -ImageWsl $PatchedImageWsl -SourceWsl $ProxyWorkWsl -PathInImage "/lib/libbluetoothdrv.so"
Write-ImageFile -ImageWsl $PatchedImageWsl -SourceWsl $OfficialLibWsl -PathInImage "/lib/libbluetoothdrv_real.so"
Write-Host "Left /lib/libmtkbtextadpa2dp.so untouched."

Write-Step "Dumping patched files back out for verification"
if (Test-Path -LiteralPath $DumpedProxyPath) { Remove-Item -LiteralPath $DumpedProxyPath -Force }
if (Test-Path -LiteralPath $DumpedRealPath) { Remove-Item -LiteralPath $DumpedRealPath -Force }
Invoke-DebugfsRead -ImageWsl $PatchedImageWsl -DebugfsCommand "dump /lib/libbluetoothdrv.so $DumpedProxyWsl" -Description "Dump patched /lib/libbluetoothdrv.so"
Invoke-DebugfsRead -ImageWsl $PatchedImageWsl -DebugfsCommand "dump /lib/libbluetoothdrv_real.so $DumpedRealWsl" -Description "Dump patched /lib/libbluetoothdrv_real.so"

Write-Step "Comparing SHA256 hashes"
Assert-Sha256Match -ExpectedPath $ProxyWorkPath -ActualPath $DumpedProxyPath -Label "Proxy /lib/libbluetoothdrv.so"
Assert-Sha256Match -ExpectedPath $OfficialLibPath -ActualPath $DumpedRealPath -Label "Original /lib/libbluetoothdrv_real.so"

Write-Step "Running read-only filesystem check"
Invoke-WslChecked -Command ("e2fsck -f -n " + (Quote-Bash $PatchedImageWsl)) -Description "Run e2fsck -f -n on patched image"

Write-Step "Done"
Write-Host "Patched image: $PatchedImagePath"
Write-Host ""
Write-Host "Final image layout:"
Write-Host "  /lib/libbluetoothdrv.so       = RTP timestamp fix proxy"
Write-Host "  /lib/libbluetoothdrv_real.so  = original official 3.0.7 libbluetoothdrv.so"
Write-Host "  /lib/libmtkbtextadpa2dp.so    = untouched original library"
Write-Host ""
Write-Host "Next manual steps:"
Write-Host "  1. Back up the Innioasis Updater original system.img."
Write-Host "  2. Copy the patched image to: C:\Users\USER\AppData\Local\Innioasis Updater\system.img"
Write-Host "  3. Open: C:\Users\USER\AppData\Local\Innioasis Updater\Toolkit\SP Flash Tool"
Write-Host "  4. Run: 2. Run Me + Connect Y1"
Write-Host "  5. Fully power off the Y1 and connect it by USB when the tool waits."
Write-Host ""
Write-Host "This script did not flash anything and did not call adb."
