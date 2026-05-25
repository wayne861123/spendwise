Get-ChildItem -Path "C:\Users\GM1.4_CT\Documents\Project\finance" -Recurse -Filter "*.db" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host $_.FullName
}