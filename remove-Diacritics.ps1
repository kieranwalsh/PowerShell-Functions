function remove-Diacritics
{
    <#
    .SYNOPSIS
    This function removes diacritcs, or accents, from characters as those are not allowed in email addresses.

    .DESCRIPTION
    This function removes diacritcs, or accents, from characters as those are not allowed in email addresses.
    Mostly used in onboarding scripts, any new username or email address can be passed through the function to get
    the windows allowed version.

    .PARAMETER Name
    The string that you wish to remove diacritics from.

    .EXAMPLE
    remove-Diacritics -Name "Renée Siân Böhner"
    Renee Sian Bohner

    .NOTES
        Filename: remove-Diacritics.ps1
        Contributors: Kieran Walsh
        Created: 2021-03-01
        Last Updated: 2021-05-05
        Version: 1.00.00
    #>
    [CmdletBinding()]
    Param
    (
        # https://en.wikipedia.org/wiki/Diacritic
        [string]$Name
    )

    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding('Cyrillic').GetBytes($Name))
}
