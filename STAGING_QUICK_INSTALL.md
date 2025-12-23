# Installation Rapide Staging sur Serveur Coolify

## 🚀 Installation en une commande

Depuis votre machine locale, exécutez :

```bash
# Si vous avez un alias SSH
ssh coolify-vm "bash -s" < deployment/install_staging_on_server.sh

# Ou avec l'adresse IP/hostname
ssh user@your-coolify-server "bash -s" < deployment/install_staging_on_server.sh
```

Le script va :
1. ✅ Cloner/mettre à jour votre repo sur le serveur
2. ✅ Préparer tous les fichiers personnalisés
3. ✅ Vous donner les instructions pour Coolify

## 📋 Après l'installation

Le script affichera le chemin exact. Dans Coolify :

1. **Ajoutez la variable d'environnement** :
   - Nom : `STAGING_PATCHES_DIR`
   - Valeur : Le chemin affiché (ex: `/home/azureuser/chatwoot-staging-patches`)

2. **Changez le docker-compose** :
   - Remplacez `docker-compose.staging.yaml` par `docker-compose.staging-simple.yaml`

3. **Déployez** 🎉

## 🔄 Mise à jour des fichiers

Quand vous modifiez du code :

```bash
# Depuis votre machine locale
ssh coolify-vm "cd /tmp/chatwoot-staging-repo && git pull origin main && export STAGING_PATCHES_DIR=\$HOME/chatwoot-staging-patches && ./deployment/prepare_staging_files.sh"
```

Ou manuellement via SSH :
```bash
ssh coolify-vm
cd /tmp/chatwoot-staging-repo
git pull origin main
export STAGING_PATCHES_DIR=$HOME/chatwoot-staging-patches
./deployment/prepare_staging_files.sh
```

## 🆚 Alternative : Préparer localement et transférer

Si vous préférez préparer les fichiers localement :

```bash
# 1. Préparer localement (vous l'avez déjà fait)
./deployment/prepare_staging_files.sh

# 2. Transférer vers le serveur
scp -r ~/chatwoot-staging-patches coolify-vm:~/chatwoot-staging-patches

# 3. Dans Coolify, définissez STAGING_PATCHES_DIR=/home/votre-user/chatwoot-staging-patches
```

