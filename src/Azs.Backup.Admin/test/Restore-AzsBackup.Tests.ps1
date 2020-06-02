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

$TestRecordingFile = Join-Path $PSScriptRoot 'Restore-AzsBackup.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

Describe 'Restore-AzsBackup' {
    . $PSScriptRoot\Common.ps1

    AfterEach {
        $global:Client = $null
    }

    It "TestRestoreBackupExpanded" -Skip:$('TestRestoreBackupExpanded' -in $global:SkippedTests) {
        $global:TestName = 'TestRestoreBackupExpanded'

        $backup = Start-AzsBackup
        $backup | Should Not Be $Null

        try
        {
            [System.IO.File]::WriteAllBytes($global:decryptionCertPath, [System.Convert]::FromBase64String($global:decryptionCertBase64))
            Restore-AzsBackup -Name $backup.Name -DecryptionCertPath $global:decryptionCertPath -DecryptionCertPassword $global:decryptionCertPassword -Force
        }
        finally
        {
            if (Test-Path -Path $global:decryptionCertPath -PathType Leaf)
            {
                Remove-Item -Path $global:decryptionCertPath -Force -ErrorAction Continue
            }
        }
    }

    It "TestRestoreBackupViaIdentityExpanded" -Skip:$('TestRestoreBackupViaIdentityExpanded' -in $global:SkippedTests) {
        $global:TestName = 'TestRestoreBackupViaIdentityExpanded'

        $backup = Start-AzsBackup
        $backup | Should Not Be $Null

        try
        {
            [System.IO.File]::WriteAllBytes($global:decryptionCertPath, [System.Convert]::FromBase64String($global:decryptionCertBase64))
            Restore-AzsBackup -InputObject $backup -Force
        }
        finally
        {
            if (Test-Path -Path $global:decryptionCertPath -PathType Leaf)
            {
                Remove-Item -Path $global:decryptionCertPath -Force -ErrorAction Continue
            }
        }
    }
}
