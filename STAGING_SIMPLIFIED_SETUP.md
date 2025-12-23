# Configuration Staging Simplifiée

## 🎯 Objectif

Simplifier le déploiement staging en utilisant la même approche que la production :
- **Image fazer-ai** directement (pas de build)
- **Bind mounts** pour les fichiers personnalisés (comme en production)
- **Pas de service code-sync** (évite les erreurs)
- **Configuration simple** et maintenable

## 📋 Prérequis

1. Accès SSH au serveur Coolify
2. Le script `deployment/prepare_staging_files.sh` dans votre repo

## 🚀 Installation

### Étape 1 : Créer le dossier de patches (avec permissions)

SSH dans votre serveur Coolify et exécutez :

```bash
# Créer le dossier avec les bonnes permissions
sudo mkdir -p /opt/chatwoot-staging-patches
sudo chown -R $USER:$USER /opt/chatwoot-staging-patches
```

**Alternative** (si vous n'avez pas sudo) : Utilisez un dossier dans votre home :
```bash
mkdir -p ~/chatwoot-staging-patches
# Puis dans Coolify, définissez STAGING_PATCHES_DIR=/home/$USER/chatwoot-staging-patches
```

### Étape 2 : Préparer les fichiers personnalisés

```bash
# Cloner votre repo (si pas déjà fait)
git clone https://github.com/lucouto/chatwoot.fazer.ai.git /tmp/chatwoot-staging-repo

# Exécuter le script de préparation
cd /tmp/chatwoot-staging-repo
chmod +x deployment/prepare_staging_files.sh
./deployment/prepare_staging_files.sh
```

Le script va :
- Cloner/mettre à jour votre repo
- Copier tous les fichiers personnalisés dans `/opt/chatwoot-staging-patches/`
- Créer la structure de dossiers nécessaire

### Étape 3 : Configurer Coolify

1. **Dans Coolify**, allez dans votre projet staging
2. **Remplacez** `docker-compose.staging.yaml` par `docker-compose.staging-simple.yaml`
3. **Ajoutez** la variable d'environnement :
   - Nom : `STAGING_PATCHES_DIR`
   - Valeur : `/opt/chatwoot-staging-patches`

### Étape 4 : Déployer

1. **Redeployez** dans Coolify
2. Les fichiers personnalisés seront automatiquement montés depuis `/opt/chatwoot-staging-patches/`

## 🔄 Mise à jour des fichiers personnalisés

Quand vous modifiez du code dans votre repo :

```bash
# SSH dans le serveur
ssh coolify-vm

# Mettre à jour les fichiers
cd /tmp/chatwoot-staging-repo
git pull origin main
./deployment/prepare_staging_files.sh

# Redémarrer les services dans Coolify (ou attendre le prochain redéploiement)
```

## 📊 Comparaison : Avant vs Après

### ❌ Avant (docker-compose.staging.yaml)
- Service `code-sync` qui clone le repo
- Copie des fichiers au démarrage (peut échouer)
- Dépendances complexes
- Erreurs fréquentes (status 137, constantes manquantes)

### ✅ Après (docker-compose.staging-simple.yaml)
- **Pas de service code-sync** (plus simple)
- **Bind mounts directs** (comme en production)
- **Fichiers préparés à l'avance** (plus fiable)
- **Même approche que la production** (cohérent)

## 🎨 Structure des fichiers montés

```
/opt/chatwoot-staging-patches/
├── app/
│   ├── javascript/dashboard/helper/automationHelper.js
│   ├── javascript/dashboard/routes/dashboard/settings/automation/operators.js
│   └── services/filter_service.rb
├── config/
│   └── app.yml
├── enterprise/
│   └── app/services/
│       ├── llm/legacy_base_open_ai_service.rb
│       └── captain/llm/pdf_processing_service.rb
└── lib/
    └── integrations/
        └── (tous les fichiers du module)
```

## 🔒 Sécurité

- Les volumes sont montés en **read-only** (`:ro`)
- Les fichiers sont sur le serveur, pas dans l'image
- Facile à auditer et modifier

## 💡 Avantages

1. **Simple** : Pas de service code-sync, pas de copie au démarrage
2. **Fiable** : Fichiers préparés à l'avance, pas d'erreurs de timing
3. **Cohérent** : Même approche que la production
4. **Rapide** : Pas de build, déploiement en quelques minutes
5. **Maintenable** : Script simple pour mettre à jour les fichiers

## 🆚 Production vs Staging

| Aspect | Production | Staging (simplifié) |
|--------|-----------|---------------------|
| Image | fazer-ai | fazer-ai |
| Fichiers personnalisés | Bind mounts | Bind mounts |
| Préparation | Manuelle | Script automatisé |
| Complexité | Moyenne | Faible |

## 🐛 Troubleshooting

### Les fichiers ne sont pas montés

Vérifiez que :
1. Le dossier `/opt/chatwoot-staging-patches/` existe
2. La variable `STAGING_PATCHES_DIR` est définie dans Coolify
3. Les permissions sont correctes : `chmod -R 755 /opt/chatwoot-staging-patches`

### Les modifications ne s'appliquent pas

1. Exécutez `./deployment/prepare_staging_files.sh` pour mettre à jour les fichiers
2. Redéployez dans Coolify

### Erreur "No such file or directory"

Le dossier de patches n'existe pas. Exécutez le script de préparation.

## 📝 Notes

- Cette configuration **ne touche pas à la production**
- Vous pouvez tester en staging avant d'appliquer en production
- Les fichiers sont versionnés dans votre repo Git
- Facile à rollback : changez juste le docker-compose dans Coolify

