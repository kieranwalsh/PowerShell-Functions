function get-SPFRecord
{
    <#
    .SYNOPSIS
    get-SPFRecord returns the SPF record of any entered domain.

    .DESCRIPTION
    get-SPFRecord returns the SPF record of any entered domain.

    .PARAMETER Domain
    The full domain you wish to query.

    .EXAMPLE
    get-SPFRecord.ps1 -Domain 'microsoft.com'

    .NOTES
         Filename: get-SPFRecord.ps1
    Contributors: Kieran Walsh
    Created: 2021-07-12
    Last Updated: 2021-07-12
    Version: 0.01.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]$Domain
    )

    try
    {
        (Resolve-DnsName -Name $Domain -Type TXT -ErrorAction stop |
            Where-Object -FilterScript {
                ($_.Type -notmatch 'NS|A') -and ($_.Strings -match 'spf')
            }).Strings
    }
    catch
    {
        "Unable to find the domain: '$Domain'"
    }
}
