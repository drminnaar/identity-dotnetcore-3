﻿function Set-ConsoleForegroundColor ($foregroundColor) {
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $foregroundColor
    return $currentForegroundColor
}

$projectPath = Get-Location
$sqliteMigrationsPath = "$($projectPath)/Identity.Database.Sqlite/Migrations"
$sqliteDbPath = "$($projectPath)/Identity.Database.Sqlite/identity.db"

$currentForegroundColor = Set-ConsoleForegroundColor "Green"
Write-Host "`r`nScript started! Creating new Identity database using Sqlite."

# Remove old data and migrations
Set-ConsoleForegroundColor Yellow | Out-Null
Write-Host "`r`n"

if (Test-Path -Path $sqliteDbPath) {
    Remove-Item -Path $sqliteDbPath
    Write-Host "Removed Sqlite Db '$($sqliteDbPath)'"
}

if (Test-Path -Path $sqliteMigrationsPath) {
    Remove-Item -Recurse -Path $sqliteMigrationsPath
    Write-Host "Removed Sqlite database migrations folder '$($sqliteMigrationsPath)'"
}

# Clean, Restore and Build solution
Set-ConsoleForegroundColor White | Out-Null

Write-Host "`r`nBuilding solution"
dotnet clean
dotnet restore
dotnet build --no-restore --configuration Release
Write-Host "Completed building solution"

# Create Sqlite migrations and update database
Set-ConsoleForegroundColor Magenta | Out-Null
Write-Host "`r`nCreating initial Sqlite Identity database migration"
dotnet ef migrations add --startup-project ./Identity.Database.Sqlite CreateInitialIdentitySchema
Write-Host "Created initial Sqlite Identity database migration"

Set-ConsoleForegroundColor DarkMagenta | Out-Null
Write-Host "`r`nStarting Sqlite Identity database migrations"
dotnet ef database update --startup-project ./Identity.Database.Sqlite
Write-Host "Completed Sqlite Identity database migrations"

# Seed Identity database
Set-ConsoleForegroundColor DarkYellow | Out-Null
Write-Host "`r`nSeeding Identity Sqlite database"
Set-Location ./Identity.Database.Seeder
# The following command runs seeder by specifying 1 argument the indicates
# the name of the connection string in the settings.json file
dotnet ./bin/Release/net5.0/Identity.Database.Seeder.dll "Identity_Sqlite"
Set-Location ..
Write-Host "Completed seeding Identity Sqlite database"

# Complete script
Set-ConsoleForegroundColor Green | Out-Null
Write-Host "`r`nScript completed! You can find the Sqlite database file located at '$($sqliteDbPath)'"
Write-Host "`r`n"

Set-ConsoleForegroundColor $currentForegroundColor | Out-Null