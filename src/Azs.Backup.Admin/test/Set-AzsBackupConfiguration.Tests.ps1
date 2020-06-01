#Import-Module -Name Az.AzAccounts -RequiredVersion 2.0.1 -Force 
#Import-Module -Name Az.Resources

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
    $PSDefaultParameterValues=@{"*:SubscriptionId"=$env.SubscriptionId; "*:Tenant"=$env.Tenant}
}

$TestRecordingFile = Join-Path $PSScriptRoot 'Set-AzsBackupConfiguration.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

Describe 'Set-AzsBackupConfiguration' {
    . $PSScriptRoot\Common.ps1

    AfterEach {
        $global:Client = $null
    }

    It "TestUpdateBackupLocationExpanded" -Skip:$('TestUpdateBackupLocationExpanded' -in $global:SkippedTests) {
        $global:TestName = 'TestUpdateBackupLocationExpanded'

        try
        {
            [System.IO.File]::WriteAllBytes($global:encryptionCertPath, [System.Convert]::FromBase64String($global:encryptionCertBase64))
            $location = Set-AzsBackupConfiguration -Username $global:username -Password $global:password -Path $global:path -EncryptionCertPath $global:encryptionCertPath -IsBackupSchedulerEnabled:$global:isBackupSchedulerEnabled -BackupFrequencyInHours $global:backupFrequencyInHours -BackupRetentionPeriodInDays $global:backupRetentionPeriodInDays
            ValidateBackupLocation -BackupLocation $location

            $location                             | Should Not Be $Null
            $location.Path                        | Should Be $global:path
            $location.Username                    | Should be $global:username
            $location.Password                    | Should -BeNullOrEmpty
            $location.EncryptionCertBase64        | Should -BeNullOrEmpty
            $location.IsBackupSchedulerEnabled    | Should be $global:isBackupSchedulerEnabled
            $location.BackupFrequencyInHours      | Should be $global:backupFrequencyInHours
            $location.BackupRetentionPeriodInDays | Should be $global:backupRetentionPeriodInDays
        }
        finally
        {
            if (Test-Path -Path $global:encryptionCertPath -PathType Leaf)
            {
                Remove-Item -Path $global:encryptionCertPath -Force -ErrorAction Continue
            }
        }
    }

    It "TestUpdateBackupLocation" -Skip:$('TestUpdateBackupLocation' -in $global:SkippedTests) {
        $global:TestName = 'TestUpdateBackupLocation'

        try
        {
            [System.IO.File]::WriteAllBytes($global:encryptionCertPath, [System.Convert]::FromBase64String($global:encryptionCertBase64))
            $location = Get-AzsBackupConfiguration
            $location.UserName = $global:username
            $location.Password = $global:passwordStr
            $location.Path = $global:path
            $location.EncryptionCertBase64 = $global:encryptionCertBase64
            $location.IsBackupSchedulerEnabled = $global:isBackupSchedulerEnabled
            $location.BackupFrequencyInHours = $global:backupFrequencyInHours
            $location.BackupRetentionPeriodInDays = $global:backupRetentionPeriodInDays
            $result = $location | Set-AzsBackupConfiguration
            ValidateBackupLocation -BackupLocation $result

            $result                             | Should Not Be $Null
            $result.Path                        | Should Be $global:path
            $result.Username                    | Should be $global:username
            $result.Password                    | Should -BeNullOrEmpty
            $result.EncryptionCertBase64        | Should -BeNullOrEmpty
            $result.IsBackupSchedulerEnabled    | Should be $global:isBackupSchedulerEnabled
            $result.BackupFrequencyInHours      | Should be $global:backupFrequencyInHours
            $result.BackupRetentionPeriodInDays | Should be $global:backupRetentionPeriodInDays
        }
        finally
        {
            if (Test-Path -Path $global:encryptionCertPath -PathType Leaf)
            {
                Remove-Item -Path $global:encryptionCertPath -Force -ErrorAction Continue
            }
        }
    }
}
