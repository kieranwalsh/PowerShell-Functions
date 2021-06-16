<#
    .SYNOPSIS
    Installs Microsoft KB files as part of a shutdown script.

    .DESCRIPTION
    Installs Microsoft KB files as part of a shutdown script.
    Logs all actions locally, plus outputs the log of the KB itself, and optionally outputs summary data to a server share.

    .PARAMETER Updates
    A list of the updates that you wish to install.

    .PARAMETER UpdatesPath
    The UNC path where the update files ares stored.

    .PARAMETER ServerLogPath
    The UNC path where you want to save the summary logs.

    .PARAMETER LogFile
    The local path to store a verbose log. By default this is in C:\Windows\Temp.

    .EXAMPLE
    The script is meant to be run as a shutdown script so an example can't be shown.

    .Notes
    Filename: Start-WindowsUpdatesInstall.ps1
    Contributors: Kieran Walsh
    Created: 2021-05-10
    Last Updated: 2021-05-12
    Version: 01.00.00
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [string[]]$Updates = @(
        'KB4511839',
        'KB5001391'
    ),
    [string]$UpdatesPath = '\\yourserver.domain\system\Software\Windows Updates\2021-04 Windows 10 20H2',
    [string]$ServerLogPath = '\\yourserver.domain\system\Software\Windows Updates\Logs',
    [string]$LogFile = (Join-Path $env:windir -ChildPath '\Temp\WindowsUpdatesInstall.log')
)

#TODO Include qualifying build versions.
#TODO Maintanence Window.
#TODO Currently only does MSU - need to expand to EXE and MSI as well.

#region functions
function add-LogEntry
{
    <#
    .SYNOPSIS
    Add-LogEntry sends output to the host and a log file.

    .DESCRIPTION
    Add-LogEntry sends output to the host and a log file.
    Output sent to the log file includes time entries. Those are not generally needed on the host and may take up too much room.
    You can pass on directions to indent output or indicate that it was a Success, Warning, or Failure. Everything else is marked as Info.

    .PARAMETER Logfile
    The full path to where you want to save the log. There's no need to specify this every time if you enter this in your main script:
    $PSDefaultParameterValues = @{'add-LogEntry:LogFile' = 'C:\scripts\sample output.log'}

    .PARAMETER Output
    The data you wish to send to the host and logfile.

    .PARAMETER Indent
    Data that you want to indent by 4 spaces. Can help readability in some situations.

    .PARAMETER IsError
    Marks the entry as [Error]

    .PARAMETER IsSuccess
    Marks the entry as [Success]

    .PARAMETER IsWarning
    Marks the entry as [Warning]

    .EXAMPLE
    add-LogEntry -Output "Starting script"
    Host:
        Starting script

    Logfile:
        2021-05-03 10:01:43   INFO      Starting script

    .EXAMPLE
    add-LogEntry -Output "Computer '$computer' is uncontactable" -IsWarning
    Host:
        Computer 'PC01' is uncontactable

    Logfile:
        2021-05-03 14:03:39   [WARNING] Computer 'PC01' is uncontactable


    .EXAMPLE
    add-LogEntry -Output "Querying computer '$computer'"
    add-LogEntry -Output "Processor: $CPU" -indent
    add-LogEntry -Output "Memory: $RAM" -indent

    Host:
        Querying computer 'PC01'
        Processor: Core i5-11600K
        Memory: 16 GB

    Logfile:
        2021-05-03 14:07:58   INFO      Querying computer 'PC01'
        2021-05-03 14:08:00   INFO          Processor: Core i5-11600K
        2021-05-03 14:08:01   INFO          Memory: 16 GB

    .NOTES
        Filename: add-LogEntry.ps1
        Contributors: Kieran Walsh
        Created: 2018-01-12
        Last Updated: 2021-05-03
        Version: 0.05.0
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Message')]
        [string]$Output,
        [string]$LogFile = 'C:\Windows\Temp\file.log',
        [switch]$Indent,
        [switch]$IsError,
        [switch]$IsSuccess,
        [switch]$IsWarning
    )
    if($Indent)
    {
        $Space = 5
    }
    Else
    {
        $Space = 1
    }
    $Type = 'INFO'
    if($IsError)
    {
        $Type = '[ERROR]'
    }if($IsSuccess)
    {
        $Type = '[SUCCESS]'
    }
    if($IsWarning)
    {
        $Type = '[WARNING]'
    }
    $Output
    "{0,-22}{1,-10}{2,-$Space}{3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Type, ' ', $Output | Out-File -FilePath $LogFile -Encoding 'utf8' -Append
}

function Search-Logfile
{
    $LogfileData = Get-Content $LogFile
    $Errors = $LogfileData | Where-Object {$_ -match '\[ERROR\]'}
    $Warnings = $LogfileData | Where-Object {$_ -match '\[WARNING\]'}
    $Result = 'Script complete with '
    If($Errors)
    {
        $Result += "$(($Errors | Measure-Object).count) error(s)"
        if($Warnings)
        {
            $Result += ", and $(($Warnings | Measure-Object).count) warning(s)"
        }
    }
    Elseif($Warnings)
    {
        $Result += "$(($Warnings | Measure-Object).count) warnings"
    }
    Else
    {
        $Result += 'no errors or warnings'
    }
    $Result += ' detected.'
    add-LogEntry -Output $Result
}

#endregion

$StartTime = Get-Date
if(Test-Path -Path $LogFile)
{
    Clear-Content -Path $LogFile
}
$ComputerName = [System.Net.Dns]::GetHostName()
$PSDefaultParameterValues = @{'add-LogEntry:LogFile' = $LogFile}
add-LogEntry -Output "Starting script on '$ComputerName'."
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
$OS = switch($OperatingSystem.version)
{
    '6.1.7600'
    {
        "$($OperatingSystem.caption)"
    }
    '6.1.7601'
    {
        "$($OperatingSystem.caption)"
    }
    '10.0.14393'
    {
        "$($OperatingSystem.caption) - 1607"
    }
    '10.0.15063'
    {
        "$($OperatingSystem.caption) - 1703"
    }
    '10.0.16299'
    {
        "$($OperatingSystem.caption) - 1709"
    }
    '10.0.17134'
    {
        "$($OperatingSystem.caption) - 1803"
    }
    '10.0.17763'
    {
        "$($OperatingSystem.caption) - 1809"
    }
    '10.0.18362'
    {
        "$($OperatingSystem.caption) - 1903"
    }
    '10.0.18363'
    {
        "$($OperatingSystem.caption) - 1909"
    }
    '10.0.19041'
    {
        "$($OperatingSystem.caption) - 2004"
    }
    '10.0.19042'
    {
        "$($OperatingSystem.caption) - 20H2"
    }
    '10.0.19043'
    {
        "$($OperatingSystem.caption) - 21H1"
    }
    default
    {
        $OperatingSystem.caption
    }
}
$ReplaceString = "' Codename '"
add-LogEntry -Output ("The operating system is '$($OS -replace ' - ',$ReplaceString)" + "'.")
add-LogEntry -Output "The script is being run by '$(whoami.exe)'."
$Finished = $false

$InstalledUpdates = try
{
    Get-HotFix -ErrorAction 'Stop'
}
catch
{
    add-LogEntry -Output 'Unable to query updates' -IsError
    $Error[0]
}

$EarliestInstalledUpdate = Get-Date (($InstalledUpdates | Where-Object {$_.InstalledOn -gt '01/01/1971'} | Sort-Object 'InstalledOn' | Select-Object -First 1).InstalledOn) -Format 'dd MMM yyyy'
$LastInstalledUpdate = Get-Date (($InstalledUpdates | Sort-Object 'InstalledOn' | Select-Object -Last 1).InstalledOn) -Format 'dd MMM yyyy'

if($InstalledUpdates)
{
    add-LogEntry -Output "There are $(($InstalledUpdates | Measure-Object).count) updates installed."
    if((($InstalledUpdates | Measure-Object).count) -gt 1)
    {
        add-LogEntry -Output "They were installed between '$EarliestInstalledUpdate' and '$LastInstalledUpdate'."
    }
    else
    {
        add-LogEntry -Output "It was installed on $EarliestInstalledUpdate."
    }
}
Else
{
    add-LogEntry -Output 'No updates have been installed.'
    $Finished = $true
}

if(-not($Finished))
{
    add-LogEntry -Output "There are $(($Updates | Measure-Object).count) updates in folder '$UpdatesPath'."
    if((Get-Service -Name 'wuauserv').starttype -ne 'manual|automatic')
    {
        try
        {
            add-LogEntry -Output 'The Windows Update Service start-up type is incorrect. Will change it.'
            Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction stop
            add-LogEntry -Output "The Windows Update Service start-up type has been changed to 'Manual'" -IsSuccess
        }
        catch
        {
            add-LogEntry -Output 'Failed to change the Windows Update Service start-up type. That will likely impact the ability to install updates.' -IsWarning
        }
    }

    $WUSAPath = (Get-Command wusa.exe).Source
    foreach ($Update in $Updates)
    {
        add-LogEntry -Output "Checking if the update '$Update' is already installed."
        if($InstalledUpdates | Where-Object {$_.HotFixID -match $Update})
        {
            add-LogEntry -Output "'$Update' is installed." -IsSuccess -Indent
            continue
        }
        Else
        {
            add-LogEntry -Output "'$Update' is not installed." -Indent
            try
            {
                $InstallationFile = Get-ChildItem -Path $UpdatesPath -ErrorAction Stop | Where-Object {$_.name -match $Update}
            }
            catch
            {
                add-LogEntry -Output "Unable to find an installation file for '$Update' in the folder '$UpdatesPath'." -IsError -Indent
                continue
            }
            add-LogEntry -Output "Beginning the installation of '$Update' from '$($InstallationFile.fullname)'." -Indent
            $InstallArguments = @(
                """$($InstallationFile.fullname)""",
                '/quiet',
                '/norestart',
                "/log:$($Env:windir)\Temp\$($Update)_Installation.evtx"
            )

            $ExitCode = (Start-Process -FilePath $WUSAPath -ArgumentList $InstallArguments -Wait -PassThru).exitcode
            add-LogEntry -Output "The installation ended with exit code: $($ExitCode)" -Indent
            switch ([string]$ExitCode)
            {
                '-2145124329'
                {
                    $ResultType = 'Warning'
                    $ResultString = 'The update is not applicable to your computer.'
                }
                '0'
                {
                    $ResultType = 'Success'
                    $ResultString = 'The installation completed successfully.'
                }
                '59'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'An unexpected network error occurred. Perhaps the end user reset the device.'
                }
                '112'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'The OS drive does not have enough free space.'
                }
                '1058'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Unable to use the Windows Update service - check if it is disabled.'
                }

                '1602'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'The installation was cancelled. The computer may have been reset by an end user.'
                }
                '1618'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Another Installation is currently taking place.'
                }
                '1619'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Could not find the installation package.'
                }
                '1625'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'This installation is forbidden by system policy.'
                }
                '1639'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Invalid command line argument.'
                }
                '3010'
                {
                    $ResultType = 'Success'
                    $ResultString = 'Update installed, but reboot required to complete.'
                }
                Default
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Failed with an unknown reason.'
                }
            }
            if($ResultType -eq 'Success')
            {
                add-LogEntry -Output "$ResultString" -IsSuccess -Indent
            }
            else
            {
                add-LogEntry -Output "Installation failed: '$ResultString'." -IsWarning -Indent
            }
        }
        '{0,-22}{1,-20}{2,-40}{3,-12}{4,-10}{5}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ComputerName, $OS, $Update, $ResultType, $ResultString | Out-File -FilePath (Join-Path $ServerLogPath -ChildPath ("Updates $(Get-Date -Format 'yyyy-MM-dd').log")) -Encoding utf8 -Append
    }
}

$EndTime = Get-Date
$TimeTaken = ''
$TakenSpan = New-TimeSpan -Start $StartTime -End $EndTime
if($TakenSpan.Hours)
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
<#
    .SYNOPSIS
    Installs Microsoft KB files as part of a shutdown script.

    .DESCRIPTION
    Installs Microsoft KB files as part of a shutdown script.
    Logs all actions locally, plus outputs the log of the KB itself, and optionally outputs summary data to a server share.

    .PARAMETER Updates
    A list of the updates that you wish to install.

    .PARAMETER UpdatesPath
    The UNC path where the update files ares stored.

    .PARAMETER ServerLogPath
    The UNC path where you want to save the summary logs.

    .PARAMETER LogFile
    The local path to store a verbose log. By default this is in C:\Windows\Temp.

    .EXAMPLE
    The script is meant to be run as a shutdown script so an example can't be shown.

    .Notes
    Filename: Start-WindowsUpdatesInstall.ps1
    Contributors: Kieran Walsh
    Created: 2021-05-10
    Last Updated: 2021-05-12
    Version: 01.00.00
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [string[]]$Updates = @(
        'KB4511839',
        'KB5001391'
    ),
    [string]$UpdatesPath = '\\yourserver.domain\system\Software\Windows Updates\2021-04 Windows 10 20H2',
    [string]$ServerLogPath = '\\yourserver.domain\system\Software\Windows Updates\Logs',
    [string]$LogFile = (Join-Path $env:windir -ChildPath '\Temp\WindowsUpdatesInstall.log')
)

#TODO Include qualifying build versions.
#TODO Maintanence Window.
#TODO Currently only does MSU - need to expand to EXE and MSI as well.

#region functions
function add-LogEntry
{
    <#
    .SYNOPSIS
    Add-LogEntry sends output to the host and a log file.

    .DESCRIPTION
    Add-LogEntry sends output to the host and a log file.
    Output sent to the log file includes time entries. Those are not generally needed on the host and may take up too much room.
    You can pass on directions to indent output or indicate that it was a Success, Warning, or Failure. Everything else is marked as Info.

    .PARAMETER Logfile
    The full path to where you want to save the log. There's no need to specify this every time if you enter this in your main script:
    $PSDefaultParameterValues = @{'add-LogEntry:LogFile' = 'C:\scripts\sample output.log'}

    .PARAMETER Output
    The data you wish to send to the host and logfile.

    .PARAMETER Indent
    Data that you want to indent by 4 spaces. Can help readability in some situations.

    .PARAMETER IsError
    Marks the entry as [Error]

    .PARAMETER IsSuccess
    Marks the entry as [Success]

    .PARAMETER IsWarning
    Marks the entry as [Warning]

    .EXAMPLE
    add-LogEntry -Output "Starting script"
    Host:
        Starting script

    Logfile:
        2021-05-03 10:01:43   INFO      Starting script

    .EXAMPLE
    add-LogEntry -Output "Computer '$computer' is uncontactable" -IsWarning
    Host:
        Computer 'PC01' is uncontactable

    Logfile:
        2021-05-03 14:03:39   [WARNING] Computer 'PC01' is uncontactable


    .EXAMPLE
    add-LogEntry -Output "Querying computer '$computer'"
    add-LogEntry -Output "Processor: $CPU" -indent
    add-LogEntry -Output "Memory: $RAM" -indent

    Host:
        Querying computer 'PC01'
        Processor: Core i5-11600K
        Memory: 16 GB

    Logfile:
        2021-05-03 14:07:58   INFO      Querying computer 'PC01'
        2021-05-03 14:08:00   INFO          Processor: Core i5-11600K
        2021-05-03 14:08:01   INFO          Memory: 16 GB

    .NOTES
        Filename: add-LogEntry.ps1
        Contributors: Kieran Walsh
        Created: 2018-01-12
        Last Updated: 2021-05-03
        Version: 0.05.0
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Message')]
        [string]$Output,
        [string]$LogFile = 'C:\Windows\Temp\file.log',
        [switch]$Indent,
        [switch]$IsError,
        [switch]$IsSuccess,
        [switch]$IsWarning
    )
    if($Indent)
    {
        $Space = 5
    }
    Else
    {
        $Space = 1
    }
    $Type = 'INFO'
    if($IsError)
    {
        $Type = '[ERROR]'
    }if($IsSuccess)
    {
        $Type = '[SUCCESS]'
    }
    if($IsWarning)
    {
        $Type = '[WARNING]'
    }
    $Output
    "{0,-22}{1,-10}{2,-$Space}{3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Type, ' ', $Output | Out-File -FilePath $LogFile -Encoding 'utf8' -Append
}

function Search-Logfile
{
    $LogfileData = Get-Content $LogFile
    $Errors = $LogfileData | Where-Object {$_ -match '\[ERROR\]'}
    $Warnings = $LogfileData | Where-Object {$_ -match '\[WARNING\]'}
    $Result = 'Script complete with '
    If($Errors)
    {
        $Result += "$(($Errors | Measure-Object).count) error(s)"
        if($Warnings)
        {
            $Result += ", and $(($Warnings | Measure-Object).count) warning(s)"
        }
    }
    Elseif($Warnings)
    {
        $Result += "$(($Warnings | Measure-Object).count) warnings"
    }
    Else
    {
        $Result += 'no errors or warnings'
    }
    $Result += ' detected.'
    add-LogEntry -Output $Result
}

#endregion

$StartTime = Get-Date
if(Test-Path -Path $LogFile)
{
    Clear-Content -Path $LogFile
}
$ComputerName = [System.Net.Dns]::GetHostName()
$PSDefaultParameterValues = @{'add-LogEntry:LogFile' = $LogFile}
add-LogEntry -Output "Starting script on '$ComputerName'."
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
$OS = switch($OperatingSystem.version)
{
    '6.1.7600'
    {
        "$($OperatingSystem.caption)"
    }
    '6.1.7601'
    {
        "$($OperatingSystem.caption)"
    }
    '10.0.14393'
    {
        "$($OperatingSystem.caption) - 1607"
    }
    '10.0.15063'
    {
        "$($OperatingSystem.caption) - 1703"
    }
    '10.0.16299'
    {
        "$($OperatingSystem.caption) - 1709"
    }
    '10.0.17134'
    {
        "$($OperatingSystem.caption) - 1803"
    }
    '10.0.17763'
    {
        "$($OperatingSystem.caption) - 1809"
    }
    '10.0.18362'
    {
        "$($OperatingSystem.caption) - 1903"
    }
    '10.0.18363'
    {
        "$($OperatingSystem.caption) - 1909"
    }
    '10.0.19041'
    {
        "$($OperatingSystem.caption) - 2004"
    }
    '10.0.19042'
    {
        "$($OperatingSystem.caption) - 20H2"
    }
    '10.0.19043'
    {
        "$($OperatingSystem.caption) - 21H1"
    }
    default
    {
        $OperatingSystem.caption
    }
}
$ReplaceString = "' Codename '"
add-LogEntry -Output ("The operating system is '$($OS -replace ' - ',$ReplaceString)" + "'.")
add-LogEntry -Output "The script is being run by '$(whoami.exe)'."
$Finished = $false

$InstalledUpdates = try
{
    Get-HotFix -ErrorAction 'Stop'
}
catch
{
    add-LogEntry -Output 'Unable to query updates' -IsError
    $Error[0]
}

$EarliestInstalledUpdate = Get-Date (($InstalledUpdates | Where-Object {$_.InstalledOn -gt '01/01/1971'} | Sort-Object 'InstalledOn' | Select-Object -First 1).InstalledOn) -Format 'dd MMM yyyy'
$LastInstalledUpdate = Get-Date (($InstalledUpdates | Sort-Object 'InstalledOn' | Select-Object -Last 1).InstalledOn) -Format 'dd MMM yyyy'

if($InstalledUpdates)
{
    add-LogEntry -Output "There are $(($InstalledUpdates | Measure-Object).count) updates installed."
    if((($InstalledUpdates | Measure-Object).count) -gt 1)
    {
        add-LogEntry -Output "They were installed between '$EarliestInstalledUpdate' and '$LastInstalledUpdate'."
    }
    else
    {
        add-LogEntry -Output "It was installed on $EarliestInstalledUpdate."
    }
}
Else
{
    add-LogEntry -Output 'No updates have been installed.'
    $Finished = $true
}

if(-not($Finished))
{
    add-LogEntry -Output "There are $(($Updates | Measure-Object).count) updates in folder '$UpdatesPath'."
    if((Get-Service -Name 'wuauserv').starttype -ne 'manual|automatic')
    {
        try
        {
            add-LogEntry -Output 'The Windows Update Service start-up type is incorrect. Will change it.'
            Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction stop
            add-LogEntry -Output "The Windows Update Service start-up type has been changed to 'Manual'" -IsSuccess
        }
        catch
        {
            add-LogEntry -Output 'Failed to change the Windows Update Service start-up type. That will likely impact the ability to install updates.' -IsWarning
        }
    }

    $WUSAPath = (Get-Command wusa.exe).Source
    foreach ($Update in $Updates)
    {
        add-LogEntry -Output "Checking if the update '$Update' is already installed."
        if($InstalledUpdates | Where-Object {$_.HotFixID -match $Update})
        {
            add-LogEntry -Output "'$Update' is installed." -IsSuccess -Indent
            continue
        }
        Else
        {
            add-LogEntry -Output "'$Update' is not installed." -Indent
            try
            {
                $InstallationFile = Get-ChildItem -Path $UpdatesPath -ErrorAction Stop | Where-Object {$_.name -match $Update}
            }
            catch
            {
                add-LogEntry -Output "Unable to find an installation file for '$Update' in the folder '$UpdatesPath'." -IsError -Indent
                continue
            }
            add-LogEntry -Output "Beginning the installation of '$Update' from '$($InstallationFile.fullname)'." -Indent
            $InstallArguments = @(
                """$($InstallationFile.fullname)""",
                '/quiet',
                '/norestart',
                "/log:$($Env:windir)\Temp\$($Update)_Installation.evtx"
            )

            $ExitCode = (Start-Process -FilePath $WUSAPath -ArgumentList $InstallArguments -Wait -PassThru).exitcode
            add-LogEntry -Output "The installation ended with exit code: $($ExitCode)" -Indent
            switch ([string]$ExitCode)
            {
                '-2145124329'
                {
                    $ResultType = 'Warning'
                    $ResultString = 'The update is not applicable to your computer.'
                }
                '0'
                {
                    $ResultType = 'Success'
                    $ResultString = 'The installation completed successfully.'
                }
                '59'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'An unexpected network error occurred. Perhaps the end user reset the device.'
                }
                '112'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'The OS drive does not have enough free space.'
                }
                '1058'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Unable to use the Windows Update service - check if it is disabled.'
                }

                '1602'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'The installation was cancelled. The computer may have been reset by an end user.'
                }
                '1618'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Another Installation is currently taking place.'
                }
                '1619'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Could not find the installation package.'
                }
                '1625'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'This installation is forbidden by system policy.'
                }
                '1639'
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Invalid command line argument.'
                }
                '3010'
                {
                    $ResultType = 'Success'
                    $ResultString = 'Update installed, but reboot required to complete.'
                }
                Default
                {
                    $ResultType = 'Failed'
                    $ResultString = 'Failed with an unknown reason.'
                }
            }
            if($ResultType -eq 'Success')
            {
                add-LogEntry -Output "$ResultString" -IsSuccess -Indent
            }
            else
            {
                add-LogEntry -Output "Installation failed: '$ResultString'." -IsWarning -Indent
            }
        }
        '{0,-22}{1,-20}{2,-40}{3,-12}{4,-10}{5}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ComputerName, $OS, $Update, $ResultType, $ResultString | Out-File -FilePath (Join-Path $ServerLogPath -ChildPath ("Updates $(Get-Date -Format 'yyyy-MM-dd').log")) -Encoding utf8 -Append
    }
}

$EndTime = Get-Date
$TimeTaken = ''
$TakenSpan = New-TimeSpan -Start $StartTime -End $EndTime
if($TakenSpan.Hours)
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
{
    $TimeTaken += "$($TakenSpan.Hours) hours, $($TakenSpan.Minutes) minutes, "
}
Elseif($TakenSpan.Minutes)
{
    $TimeTaken += "$($TakenSpan.Minutes) minutes, "
}
$TimeTaken += "$($TakenSpan.Seconds) seconds"

add-LogEntry -Output "The script took $TimeTaken to run."
Search-Logfile
