param($LogFileDirectory,$LogFileType,$DaysToKeepLogs,$ScheduledTasksFolder)


$api = New-Object -ComObject 'MOM.ScriptAPI'
$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,4,"Script runs. Parameters: LogFileDirectory $($LogFileDirectory), LogFileType: $($LogFileType) DaysToKeepLogs $($DaysToKeepLogs) and scheduled task folder $($scheduledTasksFolder)")	

Write-Verbose -Message "CreateLogDeletionJob.ps1 with these parameters: LogFileDirectory $($LogFileDirectory), LogFileType: $($LogFileType) DaysToKeepLogs $($DaysToKeepLogs) and scheduled task folder $($scheduledTasksFolder)"

$ComputerName          = $env:COMPUTERNAME
      
$LogFileDirectoryClean = $LogFileDirectory      -Replace('\\','-')
$LogFileDirectoryClean = $LogFileDirectoryClean -Replace(':','')

$scheduledTasksFolder  = $scheduledTasksFolder -replace([char]34,'')
$scheduledTasksFolder  = $scheduledTasksFolder -replace("`"",'')
$taskName              = "Auto-Log-Dir-Cleaner_for_$($LogFileDirectoryClean)_on_$($ComputerName)"
$taskName              = $taskName -replace '\s',''
$scriptFileName        = $taskName + '.ps1'
$scriptPath            = Join-Path -Path $scheduledTasksFolder -ChildPath $scriptFileName

                       
if ($DaysToKeepLogs -notMatch '\d' -or $DaysToKeepLogs -gt 0) {
	$daysToKeepLogs = 7
	$msg = 'Script warning. DayToKeepLogs not defined or not matching a number. Defaulting to 7 Days.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,2,$msg)	
}

if ($scheduledTasksFolder -eq $null) {
	$scheduledTasksFolder = 'C:\ScheduledTasks'
} else {
	$msg = 'Script warning. ScheduledTasksFolder not defined. Defaulting to C:\ScheduledTasks'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,2,$msg)	
	Write-Warning -Message $msg
}

if ($LogFileDirectory -match 'TheLogFileDirectory') {
	$msg =  'CreateLogDeletionJobs.ps1 - Script Error. LogFileDirectory not defined. Script ends.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,1,$msg)
	Write-Warning -Message $msg
	Exit
}

if ($LogFileType -match '\?\?\?') {	
	$msg = 'Script Error. LogFileType not defined. Script ends.'
	$api.LogScriptEvent('CreateLogDeletionJob.ps1',4000,1,$msg)	
	Write-Warning -Message $msg
	Exit
}


Function Write-LogDirCleanScript {

	param(
		[string]$scheduledTasksFolder,
		[string]$LogFileDirectory,		
		[int]$DaysToKeepLogs,		
		[string]$LogFileType,
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

	if ($LogFileType -notMatch '\*\.[a-zA-Z0-9]{3,}') {
		$LogFileType = '*.' + $LogFileType
		if ($LogFileType -notMatch '\*\.[a-zA-Z0-9]{3,}') {
			$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. LogFileType: $($LogFileType) seems to be not correct."
			Write-Warning -Message $msg
			$api.LogScriptEvent('CreateLogDeletionJob.ps1',4001,1,$msg)		
			Exit
		}
	}

$fileContent = @"
Get-ChildItem -Path `"${LogFileDirectory}`" -Include ${LogFileType} -ErrorAction SilentlyContinue | Where-Object { ((Get-Date) - `$_.LastWriteTime).days -gt ${DaysToKeepLogs} } | Remove-Item -Force
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
		
	$currentTasks = & SCHTASKS /Query /FO CSV
	$currentTasks = $currentTasks -replace "`"TaskName`",`"Next Run Time`",`"Status`"",""
	$currTasks    = ConvertFrom-Csv -InputObject $currentTasks -Header ("TaskName", "Next Run Time", "Status")
	$foundTasks   = $currTasks | Where-Object {$_.TaskName -match 'Auto-Log-Dir-Cleaner'}		

	if ($foundTasks) { 
		$msg = "Script function (Invoke-ScheduledTaskCreation) foundTask: $($foundTasks.ToString()) already. No action required."
		Write-Verbose -Message $msg
		$api.LogScriptEvent('CreateLogDeletionJob.ps1',4002,4,$msg)
	} else {				
		$taskRunFile         = "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NonInteractive -File $($scriptPath)"	
		$taskStartTimeOffset = Get-Random -Minimum 1 -Maximum 10
		$taskStartTime       = (Get-Date).AddMinutes($taskStartTimeOffset) | Get-date -Format 'HH:mm'						 						
		$taskSchedule        = 'DAILY'	
		& SCHTASKS /Create /SC $($taskSchedule) /RU `"NT AUTHORITY\SYSTEM`" /TN $($taskName) /TR $($taskRunFile) /ST $($taskStartTime) 	
	}		
		
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
	'LogFileType'          = $LogFileType
	'scriptPath'           = $scriptPath
}

Write-LogDirCleanScript @logDirCleanScriptParams


$taskCreationParams = @{
	'ComputerName'  = $ComputerName	
	'taskName'      = $taskName
	'scriptPath'    = $scriptPath
}

Invoke-ScheduledTaskCreation @taskCreationParams