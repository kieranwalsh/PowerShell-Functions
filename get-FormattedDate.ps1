function get-FormattedDate
{
    <#
    .SYNOPSIS
    Returns any date in human readable form with its ordinal indicator.

    .DESCRIPTION
    Returns any date in human readable form with its ordinal indicator.
    That is, it adds st, nd, rd, or th to the day in a date.

    .PARAMETER Date
    The date that you want converted. If no date is supplied then today's date is assumed.

    .EXAMPLE
    get-FormattedDate
    Wednesday, May 5th, 2021

    .EXAMPLE
    get-FormattedDate -Date "march 11 1998"
    Wednesday, March 11th, 1998

    .NOTES
        Filename: get-FormattedDate.ps1
        Contributors: Kieran Walsh
        Created: 2020-11-09
        Last Updated: 2021-05-05
        Version: 1.00.0
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [DateTime]$Date = (Get-Date)
    )
    $DaySuffix = switch -regex ($Date.Day.ToString())
    {
        '1(1|2|3)$'
        {
            'th'
            break
        }
        '.?1$'
        {
            'st'
            break
        }
        '.?2$'
        {
            'nd'
            break
        }
        '.?3$'
        {
            'rd'
            break
        }
        default
        {
            'th'
        }
    }
    '{0}, {1:MMMM} {2}{3}, {4}' -f $Date.DayOfWeek, $Date, $Date.Day, $DaySuffix, $Date.Year
}
