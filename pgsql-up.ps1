﻿function Set-ConsoleForegroundColor ($foregroundColor) {
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $foregroundColor
    return $currentForegroundColor
}

$currentForegroundColor = Set-ConsoleForegroundColor "Green"
Write-Host "`r`nScript started! Creating new Identity database using Postgres."

$projectPath = Get-Location
$postgresProjectPath = "$($projectPath)\Identity.Database.Postgres\Migrations"

# Run Postgres in Docker container
Set-ConsoleForegroundColor DarkCyan | Out-Null
Write-Host "`r`nSetup Identity Postgres database in Docker container started"
docker-compose -f docker-compose-pg.yml down --volumes
docker-compose -f docker-compose-pg.yml up -d
Write-Host "Completed setup of Identity Postgres database in Docker container"

# Clean, Restore and Build solution
Set-ConsoleForegroundColor White | Out-Null

Write-Host "`r`nBuilding solution"
dotnet clean
dotnet restore
dotnet build --no-restore --configuration Release
Write-Host "Completed building solution"

# Remove old migrations
Set-ConsoleForegroundColor Yellow | Out-Null
Write-Host "`r`n"

if (Test-Path -Path $postgresProjectPath) {
    Remove-Item -Recurse -Path $postgresProjectPath
    Write-Host "Removed Postgres database migrations folder '$($postgresProjectPath)'"
}

# Create Postgres migrations and update database
Set-ConsoleForegroundColor Magenta | Out-Null

Write-Host "`r`nCreating initial Postgres Identity database migration"
dotnet ef migrations add --startup-project .\Identity.Database.Postgres CreateInitialIdentitySchema
Write-Host "Created initial Postgres Identity database migration"

Set-ConsoleForegroundColor DarkMagenta | Out-Null

Write-Host "`r`nStarting Postgres Identity database migrations"
dotnet ef database update --startup-project .\Identity.Database.Postgres
Write-Host "Completed Postgres Identity database migrations"

# Seed Identity database
Set-ConsoleForegroundColor DarkYellow | Out-Null
Write-Host "`r`nSeeding Identity Postgres database"
Set-Location ./Identity.Database.Seeder
# The following command runs seeder by specifying 1 argument the indicates
# the name of the connection string in the settings.json file
dotnet ./bin/Release/net5.0/Identity.Database.Seeder.dll "Identity_Postgres"
Set-Location ..
Write-Host "Completed seeding Identity Postgres database"

# Complete script
Set-ConsoleForegroundColor Green | Out-Null

Write-Host "`r`nScript completed!"
Write-Host "Connect to postgres Identity database using the following details (as per 'docker-compose-pg.yml'):"
Write-Host "  - server: localhost"
Write-Host "  - username: postgres"
Write-Host "  - password: password"
Write-Host "`r`n"

Set-ConsoleForegroundColor $currentForegroundColor | Out-Null