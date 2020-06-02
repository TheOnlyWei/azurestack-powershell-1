$envFile = 'env.json'
Write-Host "Loading env.json"
if ($TestMode -eq 'live') {
    $envFile = 'localEnv.json'
}
if (Test-Path -Path (Join-Path $PSScriptRoot $envFile)) {
    $envFilePath = Join-Path $PSScriptRoot $envFile
} else {
    $envFilePath = Join-Path $PSScriptRoot '..\$envFile'
}
$env = @{}
if (Test-Path -Path $envFilePath) {
    $env = Get-Content (Join-Path $PSScriptRoot $envFile) | ConvertFrom-Json
    $PSDefaultParameterValues = @{"*:SubscriptionId" = $env.SubscriptionId; "*:Tenant" = $env.Tenant; "*:Location" = $env.Location; "*:ResourceGroupName" = $env.ResourceGroup }
}

$TestRecordingFile = Join-Path $PSScriptRoot 'Get-AzsBackupConfiguration.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

Describe 'Get-AzsBackupConfiguration' {
    . $PSScriptRoot\Common.ps1

    AfterEach {
        $global:Client = $null
    }

    It "TestListBackupLocation" -Skip:$('TestListBackupLocation' -in $global:SkippedTests) {
        $global:TestName = 'TestListBackupLocations'

        $backupLocations = Get-AzsBackupConfiguration -Top 10
        $backupLocations  | Should Not Be $null
        foreach ($backupLocation in $backupLocations) {
            ValidateBackupLocation -BackupLocation $backupLocation
        }
    }

    It "TestGetBackupLocation" -Skip:$('TestGetBackupLocation' -in $global:SkippedTests) {
        $global:TestName = 'TestGetBackupLocation'

        $backupLocations = Get-AzsBackupConfiguration -Top 10
        $backupLocations  | Should Not Be $null
        foreach ($backupLocation in $backupLocations) {
            $result = Get-AzsBackupConfiguration -Location $backupLocation.Location
            ValidateBackupLocation -BackupLocation $result
            AssertBackupLocationsAreEqual -expected $backupLocation -found $result
        }
    }

    It "TestGetBackupLocationViaIdentity" -Skip:$('TestGetBackupLocationViaIdentity' -in $global:SkippedTests) {
        $global:TestName = 'TestGetBackupLocationViaIdentity'

        $backupLocations = Get-AzsBackupConfiguration -Top 10
        $backupLocations  | Should Not Be $null
        foreach ($backupLocation in $backupLocations) {
            $result = $backupLocation | Get-AzsBackupConfiguration
            ValidateBackupLocation -BackupLocation $result
            AssertBackupLocationsAreEqual -expected $backupLocation -found $result
        }
    }
}
