Import-Module "C:\Users\VssAdministrator\Documents\WindowsPowerShell\Modules\Az.Accounts\2.0.1\Az.Accounts.psd1"
Import-Module "C:\Users\VssAdministrator\Documents\WindowsPowerShell\Modules\Az.Resources\0.10.0\Az.Resources.psd1"
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

$TestRecordingFile = Join-Path $PSScriptRoot 'Start-AzsBackup.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

Describe 'Start-AzsBackup' {
    . $PSScriptRoot\Common.ps1

    AfterEach {
        $global:Client = $null
    }

    It "TestCreateBackup" -Skip:$('TestCreateBackup' -in $global:SkippedTests) {
        $global:TestName = 'TestCreateBackup'

        $backup = Start-AzsBackup
        ValidateBackup -Backup $backup
    }
}
