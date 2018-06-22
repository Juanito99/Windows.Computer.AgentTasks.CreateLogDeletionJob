param($LogFileDirectory,$LogFileTypes,$DaysBeforeDeleteCompressedLogs,$DaysBeforeCompressLogs,$ScheduledTasksFolder)


$api = New-Object -ComObject 'MOM.ScriptAPI'
$api.LogScriptEvent('CreateLogCompressDeletionJob',4100,4,"Script runs. Parameters: LogFileDirectory $($LogFileDirectory), LogFileTypes: $($LogFileTypes) DaysToKeepLogs $($DaysBeforeDeleteCompressLogs) and scheduled task folder $($scheduledTasksFolder)")	

Write-Verbose -Message "CreateLogCompressDeletionJob with these parameters: LogFileDirectory $($LogFileDirectory), LogFileTypes: $($LogFileTypes) DaysToKeepLogs $($DaysBeforeDeleteCompressLogs) and scheduled task folder $($scheduledTasksFolder)"

$ComputerName          = $env:COMPUTERNAME
      
$LogFileDirectoryClean = $LogFileDirectory      -Replace('\\','-')
$LogFileDirectoryClean = $LogFileDirectoryClean -Replace(':','')

$scheduledTasksFolder  = $scheduledTasksFolder -replace([char]34,'')
$scheduledTasksFolder  = $scheduledTasksFolder -replace("`"",'')
$taskName              = "Auto-Log-Dir-Compress-Cleaner_for_$($LogFileDirectoryClean)_on_$($ComputerName)"
$taskName              = $taskName -replace '\s',''
$scriptFileName        = $taskName + '.ps1'
$scriptPath            = Join-Path -Path $scheduledTasksFolder -ChildPath $scriptFileName

                       
if (($DaysBeforeCompressLogs -eq $null) -or ($DaysBeforeCompressLogs -notMatch '\d') -or ($DaysBeforeCompressLogs -le 0)) {		
	$msg = 'Script Error. DaysBeforeCompressLogs invalid.  Value: $($DaysBeforeCompressLogs) '
	$api.LogScriptEvent('CreateLogCompressDeletionJob',4100,1,$msg)
	Write-Warning -Message $msg
	Exit
}

if ($scheduledTasksFolder -eq $null) {
	$scheduledTasksFolder = 'C:\ScheduledTasks'
} else {
	$msg = 'Script info. ScheduledTasksFolder not defined. Defaulting to C:\ScheduledTasks'
	$api.LogScriptEvent('CreateLogCompressDeletionJob',4100,2,$msg)	
	Write-Verbose -Message $msg
}

if ($LogFileDirectory -match 'TheLogFileDirectory') {
	$msg =  'CreateLogCompressDeletionJob.ps1 - Script Error. LogFileDirectory not defined. Script ends.'
	$api.LogScriptEvent('CreateLogCompressDeletionJob',4100,1,$msg)
	Write-Warning -Message $msg
	Exit
}

if ($LogFileTypes -match '\?\?\?') {	
	$msg = 'Script Error. LogFileTypes not defined. Script ends.'
	$api.LogScriptEvent('CreateLogCompressDeletionJob',4100,1,$msg)	
	Write-Warning -Message $msg
	Exit
}


Function Write-LogDirCleanScript {

	param(
		[string]$scheduledTasksFolder,
		[string]$LogFileDirectory,		
		[int]$DaysBeforeCompressLogs,
		[int]$DaysBeforeDeleteCompressedLogs,
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
		$api.LogScriptEvent('CreateLogCompressDeletionJob',4101,1,$msg)		
		Exit
	}

	if ($LogFileTypes -notMatch '\*\.[a-zA-Z0-9]{3,}[\w\-_\*]{0,}') {
		$LogFileTypes = '*.' + $LogFileTypes
		if ($LogFileTypes -notMatch '\*\.[a-zA-Z0-9]{3,}[\w\-_\*]{0,}') {
			$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. LogFileTypes: $($LogFileTypes) seems to be not correct."
			Write-Warning -Message $msg
			$api.LogScriptEvent('CreateLogCompressDeletionJob',4101,1,$msg)		
			Exit
		}
	}

$fileContent = @"
& cd `"${LogFileDirectory}`"
$([System.Environment]::NewLine)
`$timeStamp = Get-Date -Format 'yyyy-MM-dd_hh-mm'
$([System.Environment]::NewLine)
`$now = Get-Date
$([System.Environment]::NewLine)
`$tmpLogFolder = `"${LogFileDirectory}`" + '_CompressLogsOn_' + `$timeStamp
$([System.Environment]::NewLine)
if (Test-Path -Path `$tmpLogFolder) {
$([System.Environment]::NewLine)
	`$foo = 'No action required, folder exists.'
$([System.Environment]::NewLine)
} else {
$([System.Environment]::NewLine)
	& mkdir `$tmpLogFolder
$([System.Environment]::NewLine)
}
$([System.Environment]::NewLine)
`$logDirectoryParent = `$tmpLogFolder.SubString(0,`$tmpLogFolder.LastIndexOf('\')) + '\'
$([System.Environment]::NewLine)
try {
	$([System.Environment]::NewLine)
	`$targetLogZip = `"${LogFileDirectory}`" + '_CompressLogsOn_' + `$timeStamp + '.zip'
	$([System.Environment]::NewLine)	
	Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
	$([System.Environment]::NewLine)		
	Get-ChildItem -Path `"${LogFileDirectory}\*`" -Include ${LogFileTypes} -ErrorAction SilentlyContinue | Where-Object { (New-TimeSpan -start `$_.LastWriteTime -end (`$now)).TotalDays -gt ${DaysBeforeCompressLogs} } | ForEach-Object {
		$([System.Environment]::NewLine)	
		Move-Item -Path `$_ -Destination `$tmpLogFolder				
		$([System.Environment]::NewLine)
	}	
	$([System.Environment]::NewLine)
	[System.IO.Compression.ZipFile]::CreateFromDirectory(`$tmpLogFolder,`$targetLogZip)	
	$([System.Environment]::NewLine)
	Get-ChildItem -Path `$tmpLogFolder -Recurse | ForEach-Object {
		$([System.Environment]::NewLine)
		Remove-Item -Path `$_.FullName
		$([System.Environment]::NewLine)
	}
	$([System.Environment]::NewLine)
	Remove-Item -Path `$tmpLogFolder
	$([System.Environment]::NewLine)		
	
	if ( ${DaysBeforeDeleteCompressedLogs} -gt 0 ) {
		$([System.Environment]::NewLine)
		Get-ChildItem -Path `$logDirectoryParent -Filter '_CompressLogsOn_*.zip' -ErrorAction SilentlyContinue | Where-Object { (New-TimeSpan -start `$_.LastWriteTime -end (`$now)).TotalDays -gt ${DaysBeforeDeleteCompressedLogs} } | Remove-Item -Force		
		$([System.Environment]::NewLine)
	}
	$([System.Environment]::NewLine)

} catch {
	$([System.Environment]::NewLine)
	Get-ChildItem -Path `"${LogFileDirectory}\*`" -Include ${LogFileTypes} -ErrorAction SilentlyContinue | Where-Object { ((New-TimeSpan -start `$_.LastWriteTime -end (`$now)).TotalDays -gt ${DaysBeforeCompressLogs}) -and(`$_.Attributes -notMatch 'Compressed') } | ForEach-Object {	
		$([System.Environment]::NewLine)
		Move-Item -Path `$_ -Destination `$tmpLogFolder		
		$([System.Environment]::NewLine)
	}
	$([System.Environment]::NewLine)	
	& COMPACT /I /Q /C /S:`$tmpLogFolder    	
	$([System.Environment]::NewLine)

	if ( ${DaysBeforeDeleteCompressedLogs} -gt 0 ) {
		$([System.Environment]::NewLine)
		Get-ChildItem -Path "`$(`$logDirectoryParent)*_CompressLogsOn_*" -Recurse -ErrorAction SilentlyContinue | Where-Object { ((New-TimeSpan -start `$_.LastWriteTime -end (`$now)).TotalDays -gt ${DaysBeforeDeleteCompressedLogs}) -and (`$_.Attributes -match 'Compressed') } | Remove-Item -Force		
		$([System.Environment]::NewLine)
		Get-ChildItem -Path "`$(`$logDirectoryParent)*_CompressLogsOn_*" -ErrorAction SilentlyContinue | Where-Object { ((New-TimeSpan -start `$_.CreationTime -end (`$now)).TotalDays -gt ${DaysBeforeDeleteCompressedLogs}) -and (`$_.Attributes -match 'Compressed') } | Remove-Item -Force		
		$([System.Environment]::NewLine)
	}
	$([System.Environment]::NewLine)

}
$([System.Environment]::NewLine)
"@
	 
	$fileContent | Set-Content -Path $scriptPath -Force
	
	if ($error) {
		$msg = "Script function (Write-LogDirCleanScript, scriptPath: $($scriptPath)) failed. $($error)"		
		$api.LogScriptEvent('CreateLogCompressDeletionJob',4101,1,$msg)	
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
		$api.LogScriptEvent('CreateLogCompressDeletionJob',4102,1,$msg)		
		Write-Warning -Message $msg
	} else {
		$msg = "Scheduled Tasks: $($taskName) successfully created"	
		$api.LogScriptEvent('CreateLogCompressDeletionJob',4102,4,$msg)		
		Write-Verbose -Message $msg
	}	

} #End Function Invoke-ScheduledTaskCreation


$logDirCleanScriptParams = @{
	'scheduledTasksFolder'           = $ScheduledTasksFolder
	'LogFileDirectory'               = $LogFileDirectory	
	'DaysBeforeCompressLogs'         = $DaysBeforeCompressLogs	
	'DaysBeforeDeleteCompressedLogs' = $DaysBeforeDeleteCompressedLogs
	'LogFileTypes'                   = $LogFileTypes
	'scriptPath'                     = $scriptPath
}

Write-LogDirCleanScript @logDirCleanScriptParams


$taskCreationParams = @{
	'ComputerName'  = $ComputerName	
	'taskName'      = $taskName
	'scriptPath'    = $scriptPath
}

Invoke-ScheduledTaskCreation @taskCreationParams