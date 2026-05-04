# Chargement des variables depuis .env si ce fichier existe
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -and -not ($_ -match '^\s*#')) {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                if ($name) {
                    Set-Item -Path "Env:$name" -Value $value
                }
            }
        }
    }
}

# Création du dossier local de stockage si nécessaire
if (-not (Test-Path .\data)) {
    New-Item -ItemType Directory -Path .\data | Out-Null
}

docker compose up --build
