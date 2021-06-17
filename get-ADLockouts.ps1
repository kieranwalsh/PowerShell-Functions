function get-ADLockouts
{
    <#
.SYNOPSIS
    This function lists all Active Directory lockouts. The default search limit is one day.

    .DESCRIPTION
    This function lists all Active Directory lockouts. The default search limit is one day.
    The script will detect the PDC Emulator for the domain and then query the Security log of that machine for 4740 events.
    Those events will be parsed, sorted, and only the relevant data will be presented to the host.

    .PARAMETER Days
    The number of days you wish to query. By default, the Security log overwrites itself very quickly, so there may not be many days to query.

    .EXAMPLE
    get-ADLockouts

    .EXAMPLE
    get-ADLockouts -Days 3

    .NOTES
    Filename: Get-ADLockouts.ps1
    Contributors: Kieran Walsh
    Created: 2021-06-16
    Last Updated: 2021-06-16
    Version: 0.01.02
#>

    [CmdletBinding()]
    Param(
        [Parameter()]
        [int]$Days = 1
    )

    If (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
    {
        Write-Warning -Message "'$($MyInvocation.MyCommand)' cannot be run because the current Windows PowerShell session is not running as an administrator. Start Windows PowerShell as an administrator and run the script again."

        Break
    }

    try
    {
        $PDCEmulator = ((Get-ADDomain -ErrorAction Stop).PDCEmulator -split '\.')[0]
    }
    catch
    {
        Write-Warning -Message 'Unable to query the domain. Are the PowerShell tools installed? This script should run without problems in a DC.'
        break
    }

    "Querying the PDC emulator, '$PDCEmulator' for lockout events in the last $($Days) days."

    try
    {
        $Events = Get-WinEvent -ComputerName $PDCEmulator -FilterHashtable @{
            logname      = 'Security'
            providername = 'Microsoft-Windows-Security-Auditing'
            ID           = '4740'
            StartTime    = $((Get-Date).AddDays(-$Days))
        } -ErrorAction Stop
    }
    catch
    {
        if($error[0].exception.message -match 'No events were found that match the specified selection criteria')
        {
            "There were NO lockouts detected since $(Get-Date(Get-Date).AddDays(-$Days) -Format 'yyyy-MM-dd HH:mm'):"
        }
        Else
        {
            Write-Warning -Message "Unable to query the events on the PDC emulator, '$PDCEmulator'."
        }
        break
    }

    $Lockouts = foreach($Event in $Events)
    {
        $EventXML = [xml]$Event.ToXml()

        $UserName = ($EventXML.Event.EventData.Data | Where-Object -FilterScript {
                $_.name -eq 'TargetUserName'
            }).'#text'
        $Device = ($EventXML.Event.EventData.Data | Where-Object -FilterScript {
                $_.name -eq 'TargetDomainName'
            }).'#text'
        [PSCustomObject]@{
            'User'         = $UserName
            'Computer'     = $Device -replace '\\\\', ''
            'Lockout Time' = Get-Date(($Event).TimeCreated) -Format 'yyyy-MM-dd HH:mm'
        }
    }

    "There were $(($Lockouts | Measure-Object).count) lockouts since $(Get-Date(Get-Date).AddDays(-$Days) -Format 'yyyy-MM-dd HH:mm'):"

    $Lockouts | Sort-Object User, Time
}

get-ADLockouts