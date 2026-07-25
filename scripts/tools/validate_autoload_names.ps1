param(
    [string]$ProjectFile = (Join-Path $PSScriptRoot "..\..\project.godot"),
    [string]$ScriptsRoot = (Join-Path $PSScriptRoot "..")
)

$autoloadNames = @(
    Select-String -Path $ProjectFile -Pattern '^([A-Za-z_][A-Za-z0-9_]*)="\*res://.*"$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
)

$classNames = @(
    Get-ChildItem -Path $ScriptsRoot -Recurse -Filter '*.gd' -File |
        Select-String -Pattern '^class_name\s+([A-Za-z_][A-Za-z0-9_]*)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
)

$duplicates = @($autoloadNames | Where-Object { $classNames -contains $_ } | Sort-Object -Unique)
if ($duplicates.Count -gt 0) {
    Write-Error ("Autoload name conflicts with GDScript class_name: " + ($duplicates -join ', '))
    exit 1
}

Write-Output "Autoload/class_name name check passed."
exit 0
