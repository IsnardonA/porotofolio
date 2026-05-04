# Data Engineering Skeleton

Ce dépôt contient un squelette vide de projet Data Engineering open source, conteneurisé, local-first et prêt à être déployé sur Google Cloud Platform via Terraform.

## Architecture

- Ingestion : `dlt` vers `DuckDB`
- Transformation : `dbt-duckdb`
- Orchestration : `Kestra`
- Infrastructure : `Terraform` pour GCP
- CI/CD : `GitHub Actions`

## Structure

- `infra/terraform/` : configuration GCP (main.tf, variables.tf, outputs.tf)
- `docker/` : image pipeline Python (dlt + dbt)
- `kestra/` : configuration Kestra (application.yml)
- `src/dbt_project/` : projet dbt vide (profiles.yml configuré pour DuckDB)
- `.github/workflows/` : CI GitHub Actions
- `docker-compose.yml` : exécution locale de Kestra (worker commenté)

## Prérequis

- Docker
- Docker Compose
- Python 3.11 (pour le développement local)

## Variables d’environnement

- `DB_PATH` : chemin vers le fichier DuckDB (ex. `/data/warehouse.duckdb`)
- `API_BASE_URL` : URL de l’API source
- `GCP_PROJECT_ID` : ID du projet Google Cloud (optionnel, uniquement pour GCP)
- `GCP_APPLICATION_CREDENTIALS` : chemin du fichier de credentials JSON (optionnel)

## Fichier d’exemple d’environnement

Copiez `.env.example` vers `.env` et adaptez les valeurs :

```bash
cp .env.example .env
```

## Lancer le projet en local

1. Créez le dossier des données :

```bash
mkdir -p data
```

2. Chargez les variables depuis `.env` :

```bash
export $(grep -v '^#' .env | xargs)
```

3. Installez le helper `make` dans votre environnement virtuel :

```bash
pip install -e .
```

4. Lancez le projet en une commande :

```bash
make up
```

> Le fichier `Makefile` reste le point d’entrée principal des targets.
> Sur Windows, si le binaire `make` n’est pas disponible, installez le package dans le venv puis utilisez `make.cmd up`.

4. Ouvrez l’interface Kestra :

```text
http://localhost:8080
```

## Ajouter des pipelines

### Pipeline DLT

Créez un script dans `src/dlt_pipelines/` (ex. `ingest_api.py`) :

```python
import os
import dlt

DB_PATH = os.getenv("DB_PATH", "/data/warehouse.duckdb")
API_BASE_URL = os.getenv("API_BASE_URL", "https://jsonplaceholder.typicode.com")

def get_data():
    import requests
    response = requests.get(f"{API_BASE_URL}/posts")
    response.raise_for_status()
    return response.json()

pipeline = dlt.pipeline(
    pipeline_name="my_pipeline",
    destination="duckdb",
    destination_config={"path": DB_PATH},
    dataset_name="my_data",
)

pipeline.run(get_data)
```

### Pipeline Kestra

Ajoutez un fichier YAML dans `kestra/` (ex. `pipeline.yaml`) :

```yaml
id: my-pipeline
namespace: portfolio

tasks:
  - id: run-dlt
    type: io.kestra.core.tasks.scripts.bash.Bash
    commands:
      - export DB_PATH="/data/warehouse.duckdb"
      - python /app/src/dlt_pipelines/ingest_api.py

  - id: run-dbt
    type: io.kestra.core.tasks.scripts.bash.Bash
    commands:
      - export DB_PATH="/data/warehouse.duckdb"
      - cd /app/src/dbt_project
      - dbt deps
      - dbt run
```

### Modèles dbt

Ajoutez des modèles dans `src/dbt_project/models/` :

```sql
-- models/staging/stg_data.sql
with raw_data as (
    select *
    from {{ source('my_data', 'posts') }}
)

select
    id,
    userId as user_id,
    title,
    body,
    current_timestamp() as loaded_at
from raw_data
```

## Déploiement GCP (optionnel)

La partie `infra/terraform` est conservée pour un déploiement futur sur Google Cloud. Elle n’est pas requise pour exécuter le projet localement.

1. Initialisez Terraform :

```bash
cd infra/terraform
terraform init
```

2. Appliquez la configuration :

```bash
terraform apply -var="gcp_project_id=YOUR_PROJECT_ID"
```

## CI/CD

La pipeline GitHub Actions vérifie :

- lint Python avec `flake8`
- format Terraform
- build Docker
- validation de `docker-compose.yml`

## Bonnes pratiques

- Utiliser des variables d’environnement pour toute la configuration
- Préserver le fichier `*.duckdb` dans `.gitignore`
- Conserver la logique métier dans `src/` et la configuration dans `infra/` et `kestra/`
