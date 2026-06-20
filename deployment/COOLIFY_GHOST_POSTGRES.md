# Coolify — Problème des « deux Postgres » et badge « Degraded »

> **Résumé court : c'est purement cosmétique. La production est saine et les
> données sont intactes. Ne supprimez RIEN.**

## Symptôme

Dans Coolify, le stack de production `chatwoot-fazer` affiche :
- **deux services Postgres** (`pgvector/pgvector:pg16`), souvent marqués `Exited` ;
- le statut global du stack en **« Degraded (unhealthy) »** (badge orange).

Pourtant Rails, Sidekiq, Redis et Baileys sont tous `Running (healthy)` et
l'application fonctionne normalement.

## Diagnostic (fait le 2026-06-17)

| Vérification | Résultat |
|---|---|
| Conteneurs Postgres réellement présents sur l'hôte | **un seul** vivant et sain (`postgres-f8kkkgcsko4sogs88k8c80ok`) |
| Conteneur Postgres « Exited » dans Docker | **aucun** (`docker ps -a --filter ancestor=pgvector/pgvector:pg16` ne montre que le conteneur sain) |
| Service `postgres` dans le compose déployé (`/data/coolify/services/f8kk.../docker-compose.yml`) | **un seul** |
| Volume Postgres dans le compose | **un seul** (`f8kkkgcsko4sogs88k8c80ok_postgres`) |
| Rails connecté à quel Postgres ? | à l'unique Postgres sain (`postgres` → `10.0.3.5`) |

**Conclusion :** le deuxième « Postgres » affiché par Coolify est un
**enregistrement fantôme** dans la base de métadonnées de Coolify, hérité de
l'ancien stack v4.10. Il **n'a aucun conteneur ni volume derrière lui**. Coolify ne
trouve pas de conteneur pour ce service qu'il croit encore exister → il l'affiche
en rouge `Exited` → le stack passe en « Degraded ».

> Indice visuel : dans l'UI, les deux lignes Postgres n'ont pas les mêmes liens
> (l'une a « Backups », l'autre non) — signe que Coolify suit deux entrées distinctes.

### Preuves supplémentaires confirmées (captures du 2026-06-17)

- **Persistent Storages** : un « Postgres » a bien le volume
  `f8kkkgcsko4sogs88k8c80ok_postgres → /var/lib/postgresql/data` ; l'autre affiche
  **« No storage found »** → le fantôme n'a **aucun volume**.
- **New Scheduled Task → Container name** : `postgres` apparaît **deux fois** dans la
  liste → Coolify a deux enregistrements de service postgres en base.
- **Terminal → Container** : la liste ne contient que `baileys-api`, `rails`, `redis`,
  `sidekiq` — **aucun postgres** → Coolify ne rattache aucun conteneur réel à ces
  entrées (alors que `docker ps` montre l'unique conteneur postgres sain).

Le vrai Postgres = celui qui a le volume + un conteneur en cours. Le fantôme = celui
« No storage found », sans conteneur.

## Ce qui NE corrige PAS le problème

- **Restart** du stack (ne fait que redémarrer les conteneurs, ne relit pas le compose).
- **Edit Compose File → Save → Redeploy** (testé : le fantôme persiste).

## ✅ Solution simple (officielle) — supprimer le service fantôme dans l'UI

Confirmé par un mainteneur Coolify (issue
[#9591](https://github.com/coollabsio/coolify/issues/9591), commentaire de Cinzya) :

> « This is not really a bug, Coolify just doesn't clean those up automatically.
> Users have to enter the service settings and manually delete it. »

Coolify crée un enregistrement `ServiceDatabase`/`ServiceApplication` par service du
compose mais **ne supprime jamais** ceux dont le nom disparaît du compose. Il faut donc
supprimer l'entrée fantôme à la main, **dans l'UI** (ciblé, sans toucher aux volumes).

**Procédure (testée le 2026-06-17, a fonctionné) :**

1. Repérer le fantôme dans la liste **Services** : c'est le Postgres qui a **seulement
   « Settings »** (pas de **« Backups »**). Coolify ne propose « Backups » que pour une
   vraie base avec stockage ; le fantôme n'en a pas (« No storage found »).
2. Cliquer **Settings** sur ce Postgres et **vérifier** qu'il indique bien
   **« No storage found »** (aucun volume). Si au contraire il montre le volume
   `f8kkkgcsko4sogs88k8c80ok_postgres` → STOP, c'est le vrai, le fantôme est l'autre.
3. **Delete** ce service. Si une case « delete volumes » apparaît, **ne pas la cocher**
   (le fantôme n'a pas de volume de toute façon).
4. Rafraîchir l'UI → la carte disparaît et le stack repasse en **Running (healthy)**.

> Comme le fantôme n'a ni volume ni conteneur, sa suppression **n'efface aucune donnée**.

Un correctif automatique est en cours côté Coolify
([PR #9840](https://github.com/coollabsio/coolify/issues/9591) — « clean up orphaned
service records on compose re-parse »).

## À NE PAS faire

- **Ne pas** supprimer un **conteneur** ou un **volume** Postgres en ligne de commande
  pour « nettoyer » le badge — risque d'effacer la base de production.
- **Ne pas** utiliser le contournement SQL de l'issue
  (`DELETE FROM service_applications WHERE name='postgres'`) : ici les **deux** entrées
  s'appellent `postgres`, ça supprimerait les deux. La suppression via l'UI est ciblée.
- **Ne pas** recréer le service Coolify juste pour ça : il obtiendrait un **nouvel ID**
  → de **nouveaux noms de volumes** → le Postgres démarrerait **vide** (il ne se
  rattache pas tout seul à `f8kkkgcsko4sogs88k8c80ok_postgres`).

## En attendant / en général

- **Ne jugez pas la santé via le badge Coolify** ; utilisez `docker ps` sur l'hôte ou
  **Super Admin → Instance Status** dans Chatwoot.

## Référence

- Issue Coolify : https://github.com/coollabsio/coolify/issues/9591
- Détails et commandes de diagnostic : `deployment/UPGRADE_RUNBOOK.md` (§7).
