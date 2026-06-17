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

## Ce qu'il faut faire

**Rien d'urgent — c'est cosmétique.** Règles de survie :

1. **Ne jugez PAS la santé via le badge Coolify** pour ce stack. Utilisez plutôt :
   - `docker ps` sur l'hôte, ou
   - la page **Super Admin → Instance Status** dans Chatwoot.
2. **Ne supprimez JAMAIS** un conteneur ou un volume Postgres pour « nettoyer » le
   badge — vous risqueriez d'effacer la base de production.

## Correction définitive — AVANCÉ, déconseillé pour un simple badge

⚠️ **Piège important sur les volumes.** Coolify nomme les volumes
`<ID-service>_<nom>`. Recréer le service génère un **nouvel ID** → donc de
**nouveaux noms de volumes** (`<nouvelID>_postgres`). Le nouveau Postgres ne
réutilisera **PAS** automatiquement `f8kkkgcsko4sogs88k8c80ok_postgres` : il
démarrerait sur une **base vide**. « Les volumes survivent » est vrai sur le disque,
mais le nouveau service ne s'y rattache pas tout seul.

Si on y tient vraiment (sauvegarde §5 du runbook **obligatoire** d'abord) :

- **Option A — chirurgie sur la base interne de Coolify** : supprimer la ligne de
  service orpheline dans la base de Coolify. Spécifique à la version, risqué.
- **Option B — supprimer/recréer le service** : il faut soit **restaurer le dump**
  dans le nouveau Postgres, soit **épingler explicitement** le volume externe
  existant (`f8kkkgcsko4sogs88k8c80ok_postgres`) dans le compose recréé.

**Recommandation : ne rien faire.** Le badge est cosmétique ; le coût et le risque
d'une « correction » dépassent largement le bénéfice. Surveiller la santé via
`docker ps` / Instance Status.

## Référence

Détails et commandes de diagnostic dans `deployment/UPGRADE_RUNBOOK.md` (§7).
