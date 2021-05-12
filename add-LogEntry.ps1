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
    } Else
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