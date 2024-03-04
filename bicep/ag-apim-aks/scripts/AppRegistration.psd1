@{
    ModuleVersion = '1.0'
    CompatiblePSEditions = @(
        'Core'
        )
    GUID = 'a65a7079-bfe9-4cb5-861b-15d92dfe964e'
    Author = 'Chris Bellee'
    CompanyName = 'Microsoft'
    Copyright = '(c) 2022 cbellee@microsoft.com. All rights reserved.'
    Description = 'Module to create app registrations & service principals'
    PowerShellVersion = '7.2'
    RequiredModules = @(
        'Microsoft.Graph.Applications'
        )
    FunctionsToExport = @(
        'New-AppRegistrations'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    }