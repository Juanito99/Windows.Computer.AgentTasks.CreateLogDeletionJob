param($LogFileDirectory,$LogFileTypes,$DaysToKeepLogs,$ScheduledTasksFolder)


$api = New-Object -ComObject 'MOM.ScriptAPI'
$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,4,"Script runs. Parameters: LogFileDirectory $($LogFileDirectory), LogFileTypes: $($LogFileTypes) DaysToKeepLogs $($DaysToKeepLogs) and scheduled task folder $($scheduledTasksFolder)")	

Write-Verbose -Message "CreateLogDeletionJob.ps1 with these parameters: LogFileDirectory $($LogFileDirectory), LogFileTypes: $($LogFileTypes) DaysToKeepLogs $($DaysToKeepLogs) and scheduled task folder $($scheduledTasksFolder)"

$ComputerName          = $env:COMPUTERNAME
      
$LogFileDirectoryClean = $LogFileDirectory      -Replace('\\','-')
$LogFileDirectoryClean = $LogFileDirectoryClean -Replace(':','')

$scheduledTasksFolder  = $scheduledTasksFolder -replace([char]34,'')
$scheduledTasksFolder  = $scheduledTasksFolder -replace("`"",'')
$taskName              = "Auto-Log-Dir-Cleaner_for_$($LogFileDirectoryClean)_on_$($ComputerName)"
$taskName              = $taskName -replace '\s',''
$scriptFileName        = $taskName + '.ps1'
$scriptPath            = Join-Path -Path $scheduledTasksFolder -ChildPath $scriptFileName

                       
if ($DaysToKeepLogs -notMatch '\d' -or $DaysToKeepLogs -le 0) {	
	$msg = 'Script Error. DayToKeepLogs not defined or not matching a number. Script ends.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,1,$msg)	
	Write-Warning -Message $msg
	Exit
}

if ($scheduledTasksFolder -eq $null) {
	$scheduledTasksFolder = 'C:\ScheduledTasks'
} else {
	$msg = 'Script info. ScheduledTasksFolder not defined. Defaulting to C:\ScheduledTasks'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,2,$msg)	
	Write-Verbose -Message $msg
}

if ($LogFileDirectory -match 'TheLogFileDirectory') {
	$msg =  'Script Error. LogFileDirectory not defined. Script ends.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,1,$msg)
	Write-Warning -Message $msg
	Exit
}

if ($LogFileTypes -match '\?\?\?') {	
	$msg = 'Script Error. LogFileTypes not defined. Script ends.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,1,$msg)	
	Write-Warning -Message $msg
	Exit
}


Function Write-LogDirCleanScript {

	param(
		[string]$scheduledTasksFolder,
		[string]$LogFileDirectory,		
		[int]$DaysToKeepLogs,		
		[string]$LogFileTypes,
		[string]$scriptPath
	)
	
	if (Test-Path -Path $scheduledTasksFolder) {
		$foo = 'folder exists, no action requried'
	} else {
		& mkdir $scheduledTasksFolder
	}
	
	if (Test-Path -Path $LogFileDirectory) {
		$foo = 'folder exists, no action requried'
	} else {
		$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. LogFileDirectory not found $($LogFileDirectory)"
		Write-Warning -Message $msg
		$api.LogScriptEvent('CreateLogDeletionJob.ps1',4001,1,$msg)		
		Exit
	}

	if ($LogFileTypes -notMatch '\*\.[a-zA-Z0-9]{3,}') {
		$LogFileTypes = '*.' + $LogFileTypes
		if ($LogFileTypes -notMatch '\*\.[a-zA-Z0-9]{3,}') {
			$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. LogFileTypes: $($LogFileTypes) seems to be not correct."
			Write-Warning -Message $msg
			$api.LogScriptEvent('CreateLogDeletionJob.ps1',4001,1,$msg)		
			Exit
		}
	}


$fileContent = @"
`$now = Get-Date
Get-ChildItem -Path `"${LogFileDirectory}\*`" -Include ${LogFileTypes} -ErrorAction SilentlyContinue | Where-Object { (New-TimeSpan -start `$_.LastWriteTime -end (`$now)).TotalDays -gt ${DaysToKeepLogs} } | Remove-Item -Force	
"@	
	
	$fileContent | Set-Content -Path $scriptPath -Force
	
	if ($error) {
		$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. $($error)"		
		$api.LogScriptEvent('CreateLogDeletionJob.ps1',4001,1,$msg)	
		Write-Warning -Message $msg
	} else {
		$msg = "Script: $($scriptPath) successfully created"	
		Write-Verbose -Message $msg
	}

} #End Function Write-LogDirCleanScript


Function Invoke-ScheduledTaskCreation {

	param(
		[string]$ComputerName,		
		[string]$taskName
	)         	 
		
	$taskRunFile         = "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NonInteractive -File $($scriptPath)"	
	$taskStartTimeOffset = 5
	$taskStartTime       = (Get-Date).AddMinutes($taskStartTimeOffset) | Get-date -Format 'HH:mm'						 						
	$taskSchedule        = 'DAILY'	
	& SCHTASKS /Create /SC $($taskSchedule) /RU `"NT AUTHORITY\SYSTEM`" /TN $($taskName) /TR $($taskRunFile) /ST $($taskStartTime) /F	
		
	if ($error) {
		$msg = "Sript function (Invoke-ScheduledTaskCreation) Failure during task creation! $($error)"
		$api.LogScriptEvent('CreateLogDeletionJob.ps1',4002,1,$msg)		
		Write-Warning -Message $msg
	} else {
		$msg = "Scheduled Tasks: $($taskName) successfully created"	
		Write-Verbose -Message $msg
	}	

} #End Function Invoke-ScheduledTaskCreation


$logDirCleanScriptParams   = @{
	'scheduledTasksFolder' = $ScheduledTasksFolder
	'LogFileDirectory'     = $LogFileDirectory	
	'daysToKeepLogs'       = $DaysToKeepLogs	
	'LogFileTypes'          = $LogFileTypes
	'scriptPath'           = $scriptPath
}

Write-LogDirCleanScript @logDirCleanScriptParams


$taskCreationParams = @{
	'ComputerName'  = $ComputerName	
	'taskName'      = $taskName
	'scriptPath'    = $scriptPath
}

Invoke-ScheduledTaskCreation @taskCreationParams