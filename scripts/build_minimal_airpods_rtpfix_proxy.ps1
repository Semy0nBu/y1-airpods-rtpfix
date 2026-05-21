param(
    [string]$AndroidNdkRoot = $env:ANDROID_NDK_ROOT,
    [string]$Out = "build\libbluetoothdrv.so",
    [switch]$QuietMediaLog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AndroidNdkRoot)) {
    throw "ANDROID_NDK_ROOT is not set. Pass -AndroidNdkRoot or set the environment variable."
}

$RepoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$Source = Join-Path $RepoRoot "src\libbluetoothdrv_proxy\libbluetoothdrv_proxy.c"

if ([System.IO.Path]::IsPathRooted($Out)) {
    $ResolvedOut = $Out
} else {
    $ResolvedOut = Join-Path $RepoRoot $Out
}

$ClangCandidates = @(
    (Join-Path $AndroidNdkRoot "toolchains\llvm\prebuilt\windows-x86_64\bin\clang.cmd"),
    (Join-Path $AndroidNdkRoot "toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"),
    (Join-Path $AndroidNdkRoot "toolchains\llvm\prebuilt\windows\bin\clang.cmd"),
    (Join-Path $AndroidNdkRoot "toolchains\llvm\prebuilt\windows\bin\clang.exe")
)

$Clang = $null
foreach ($Candidate in $ClangCandidates) {
    if (Test-Path -LiteralPath $Candidate) {
        $Clang = $Candidate
        break
    }
}

if (-not $Clang) {
    throw "Unable to find Android NDK clang under $AndroidNdkRoot"
}

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source not found: $Source"
}

$OutDir = Split-Path -Parent $ResolvedOut
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$Defines = @(
    "-DENABLE_BT_SETCONFIG_REWRITE=0",
    "-DENABLE_RTP_TIMESTAMP_FIX=1",
    "-DENABLE_VERBOSE_BT_MEDIA_LOG=$(if ($QuietMediaLog) { '0' } else { '1' })"
)

$Args = @(
    "--target=armv7a-linux-androideabi16",
    "-shared",
    "-fPIC",
    "-O2"
)
$Args += $Defines
$Args += @(
    "-Wl,-soname,libbluetoothdrv.so",
    "-o",
    $ResolvedOut,
    $Source,
    "-llog",
    "-ldl"
)

Write-Host "Building minimal AirPods RTP timestamp fix proxy from source:"
Write-Host "$Clang $($Args -join ' ')"
& $Clang @Args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$BuildInfoOut = Join-Path $OutDir "BUILD_INFO.txt"
$CommitHash = "unknown"
try {
    $CommitHash = (& git -C $RepoRoot rev-parse HEAD 2>$null).Trim()
    if (-not $CommitHash) {
        $CommitHash = "unknown"
    }
} catch {
    $CommitHash = "unknown"
}

$BuildInfo = @(
    "mode=airpods_minimal_rtpfix_proxy",
    "date_utc=$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "commit=$CommitHash",
    "source=$Source",
    "output=$ResolvedOut",
    "ENABLE_RTP_TIMESTAMP_FIX=1",
    "ENABLE_BT_SETCONFIG_REWRITE=0",
    "ENABLE_VERBOSE_BT_MEDIA_LOG=$(if ($QuietMediaLog) { '0' } else { '1' })",
    "install_runtime_path=/system/lib/libbluetoothdrv.so",
    "requires_runtime_real_library=/system/lib/libbluetoothdrv_real.so",
    "libmtkbtextadpa2dp.so=must_remain_untouched"
)
Set-Content -LiteralPath $BuildInfoOut -Value $BuildInfo -Encoding ASCII

Write-Host "Wrote proxy: $ResolvedOut"
Write-Host "Wrote build info: $BuildInfoOut"
Write-Host "This script does not use adb, flash anything, or modify system.img."
