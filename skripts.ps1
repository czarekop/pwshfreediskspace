
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Drive
)

#log directory
if ($PSVersionTable.Platform -eq 'Unix') {
    $logPath = '/tmp'
}
else {
    $logPath = 'C:\test\logs'
}

$logFile = "$logPath\driveCheck.log" #logfile
#verify log directory
try {
   if(-not(Test-Path -Path $logPath -ErrorAction Stop)){
        #output dir not found create the dir
        New-Item -itemType Directory -Path $logPath -ErrorAction Stop | Out-Null
        New-Item -ItemType File -Path $logFile -ErrorAction Stop | Out-Null
 }
}
catch {
    throw 
}

Add-Content -Path $logFile -Value "[INFO] Running $PSCommandPath"
# verify the poshgram is installed
if(-not (Get-Module -Name PoshGram -ListAvailable)){
   #poshgram installed 
   Add-Content -Path $logFile -Value "[ERROR] Poshgram is not installed. "
   throw
}
else {
    Add-Content -Path $logFile -Value "[INFO] Poshgram is installed. "
}

try {
    if ($PSVersionTable.Platform -eq 'Unix') {
        $volume = Get-PSDrive -Name $Drive -ErrorAction Stop
        #verify volume actually exists
        if ($volume) {
            $total = $volume.Free + $volume.Used
            $percentFree = [int](($volume.Free / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $Drive was not found."
            throw
        }
    }
    else {
        $volume = Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter -eq $Drive }
        #verify volume actually exists
        if ($volume) {
            $total = $volume.Size
            $percentFree = [int](($volume.SizeRemaining / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $Drive was not found."
            throw
        }
    }
}
catch {
    Add-Content -Path $logFile -Value '[ERROR] Unable to retrieve volume information:'
    Add-Content -Path $logFile -Value $_
    throw
}

# send tg msg 
if ($PercentFree -le 70) {

    try {
        Import-Module -name PoshGram -ErrorAction Stop
        Add-Content -Path $logFile -Value "[INFO] Importet Poshgram sucess"
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] PoshGram could not be imported: "
        Add-Content -Path $logFile -Value $_
    }
    
    Add-Content -Path $logFile -Value "[INFO] Sending telegram notification"

    $freesize = ($volume.SizeRemaining / 1073741824)

    $messageSplat = @{
        BotToken    = "nnnnnnnnn:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx"
        ChatID      = "-nnnnnnnnn"
        Message     = "[LOW SPACE] Drive at: $percentFree% FREE SIZE $freesize GB "
        ErrorAction = 'Stop'
    }

    try {
        Send-TelegramTextMessage @messageSplat
        Add-Content -Path $logFile -Value '[INFO] Message sent successfully'
    }
    catch {
        Add-Content -Path $logFile -Value '[ERROR] Error encountered sending message:'
        Add-Content -Path $logFile -Value $_
        throw
    }

}

#$botToken = 'nnnnnnnnn:xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxx'                                                             $chat = '-nnnnnnnnn'              






