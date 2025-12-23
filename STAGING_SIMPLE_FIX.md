# Fix pour docker-compose.staging-simple.yaml

## Problème

Coolify ne supporte pas les variables d'environnement dans les volumes de cette manière : `${STAGING_PATCHES_DIR}/app:/app/app:ro`

## Solution

Le fichier `docker-compose.staging-simple.yaml` utilise maintenant le chemin direct `/home/azureuser/chatwoot-staging-patches`.

## Si votre utilisateur est différent

Si votre utilisateur n'est pas `azureuser`, modifiez le fichier et remplacez `/home/azureuser/` par votre chemin :

```bash
# Sur votre machine locale
sed -i '' 's|/home/azureuser/|/home/VOTRE-USER/|g' docker-compose.staging-simple.yaml
```

Ou modifiez directement dans Coolify en remplaçant `azureuser` par votre utilisateur.

## Vérification

Le script `prepare_staging_files.sh` vous donne le chemin exact. Utilisez ce chemin dans le docker-compose.

