param([switch]$UpdateGoldens, [switch]$SkipAndroid)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}
$flutterPath = if (Test-Path '.tooling/flutter/bin/flutter.bat') { Join-Path $projectRoot '.tooling/flutter/bin/flutter.bat' } else { 'flutter' }
$dartPath = if (Test-Path '.tooling/flutter/bin/dart.bat') { Join-Path $projectRoot '.tooling/flutter/bin/dart.bat' } else { 'dart' }
Invoke-Checked $flutterPath @('pub','get')
Invoke-Checked $dartPath @('run','build_runner','build','--delete-conflicting-outputs')
Invoke-Checked $dartPath @('format','lib','test','integration_test')
Invoke-Checked $flutterPath @('analyze','--fatal-infos')
if ($UpdateGoldens) { Invoke-Checked $flutterPath @('test','--tags','golden','--update-goldens') }
Invoke-Checked $flutterPath @('test','--coverage')
if (!$SkipAndroid) { Invoke-Checked $flutterPath @('build','apk','--debug') }
