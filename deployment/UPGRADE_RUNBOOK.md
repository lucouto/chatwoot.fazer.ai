# Chatwoot Fork — Definitive Upgrade Runbook

> **Single source of truth for upgrading this fork.** Read ONLY this file.
> Every other `deployment/*.md` is historical and superseded. Do not read them
> unless this runbook explicitly points you there.
>
> This is version-agnostic: substitute the version tags below and follow the steps.

---

## 0. Facts you need before anything (no exploration required)

| Thing | Value |
|---|---|
| Fork repo | `lucouto/chatwoot.fazer.ai` (remote `origin`) |
| Upstream | `fazer-ai/chatwoot` (remote `upstream`) — source of `vX.Y.Z-fazer-ai.N` tags |
| OSS | `chatwoot/chatwoot` (remote `chatwoot`) |
| Image (built by us) | `ghcr.io/lucouto/chatwoot.fazer.ai:<tag>-ee` |
| Build workflow | `.github/workflows/publish_my_ee_docker.yml` — triggers on push of tag `v*`; builds multi-arch (amd64+arm64) with `CW_EDITION=ee`; appends `-ee` to the tag |
| Deploy platform | **Coolify** on host `vm-coolify-n8n` (ssh `azureuser@vm-coolify-n8n`) |
| **Live PROD DB container** | `postgres-f8kkkgcsko4sogs88k8c80ok` (Coolify project `f8kkkgcsko4sogs88k8c80ok`) |
| **STAGING DB container** | `postgres-vkg4sgcco4wg8os4sckws088` (separate Coolify project `vkg4...`) |
| Compose files (repo) | `docker-compose.production-<ver>.yaml`, `docker-compose.staging-<ver>.yaml` |
| Current prod version | **v4.17.0-fazer-ai.115-ee** (cut over 2026-09-17 19:43 CEST) |
| Current staging version | **v4.17.0-fazer-ai.115-ee** (as of 2026-09-17) |

### ⚠️ Branch from what PROD RUNS, not from `main`

`main` is not necessarily production. In Sept 2026 prod was running
`v4.14.2-fazer-ai.85-ee` = commit `6105d475a` (branch `docs/coolify-ghost-postgres`),
which carries `fix(sidebar): remove native Kanban entry` — a commit `main` never got.
Branching the upgrade from `main` would have silently reintroduced the native Kanban
menu item.

**Always resolve the base this way**, then branch from it:
```bash
ssh coolify-vm 'docker inspect rails-f8kkkgcsko4sogs88k8c80ok --format "{{.Config.Image}}"'
git rev-parse <that-tag>^{commit}    # <- branch from THIS
```

**Why we build our own image** (not fazer-ai's stock): we keep customizations.
As of v4.14.2 the only genuine in-image customization left is the **automation
custom-attribute filter operators (frontend)** — most others were upstreamed or
reverted (Azure OpenAI was abandoned entirely).

**The one patch NOT baked into the image** — must stay volume-mounted in every compose:
```
/opt/chatwoot-patches/config/initializers/99_fix_pricing_plan_quantity.rb
  → /app/config/initializers/99_fix_pricing_plan_quantity.rb:ro   (Enterprise unlock)
```

---

## 1. Build & publish the new image

```bash
cd ~/Projets_apps_github/fork_chatwoot_fazer_ai

# Sync upstream and merge the target release tag into the upgrade branch
git fetch upstream --tags
git checkout -b upgrade-to-<ver>        # or reuse the existing upgrade branch
git merge <upstream-tag>                # e.g. v4.14.2-fazer-ai.84
# Resolve conflicts (historically only config/app.yml version line).
# Large upstream merges OOM-kill the husky/eslint pre-commit hook — use:
git commit --no-verify

# Tag + push to trigger the build (the `-ee` suffix is added by the workflow)
git tag v<ver>
git push origin upgrade-to-<ver> --tags
```

### Only ONE workflow may publish — fixed 2026-09-17

`build_custom_ee_image.yml` ("Build Custom EE Image with Customizations") **also**
triggers on `push: tags: v*-ee`, builds the same image and pushes the **same tag** as
`publish_my_ee_docker.yml`. Both produce valid EE images, but each platform job of each
workflow pushes the tag directly, so whichever finishes last wins and the tag content is
**nondeterministic**. Observed on v4.17.0-fazer-ai.115-ee: the primary workflow published a
correct 2-arch manifest at 16:42:46, the duplicate then clobbered it with an amd64-only
manifest, and the tag only became 2-arch again when the duplicate's own merge job finished.

Upstream's `publish_ee_docker.yml` / `publish_foss_docker.yml` also fire on the tag (they
fail noisily, which is why §9 says to disable them).

The release-triggered publishers (`publish_ee_github_docker.yml`,
`publish_github_docker.yml`, `publish_github_docker_beta.yml`) were the same defect
waiting to fire: they push to this repo's ghcr **and move the floating `:latest`,
`:latest-ee`, `:beta` tags**, so cutting a GitHub Release here would have overwritten a
published image with a differently-built one.

**Fixed 2026-09-17:** all six are now `workflow_dispatch`-only, leaving
`publish_my_ee_docker.yml` as the single automatic publisher (`push: tags: v*`).
`publish_my_ee_docker.yml` also gained a **pre-publish customization check** that fails
the build if any fork customization is missing, if the native Kanban sidebar entry comes
back, or if `enterprise/` is absent.

**If you ever re-enable one of them, this race returns.** Verify with:
```bash
for f in .github/workflows/*publish*.yml .github/workflows/build_custom_ee_image.yml; do
  printf '%s: ' "$f"; awk '/^on:/{f=1;next} /^env:|^jobs:/{f=0} f' "$f" | grep -v '^\s*$\|^ *#' | tr -d ' \n'; echo
done   # only publish_my_ee_docker.yml may show a push/tags trigger
```

Verify the build before touching Coolify:
```bash
gh run list --repo lucouto/chatwoot.fazer.ai --workflow=publish_my_ee_docker.yml --limit 3
docker buildx imagetools inspect ghcr.io/lucouto/chatwoot.fazer.ai:v<ver>-ee
```
Both `linux/amd64` and `linux/arm64` must resolve before proceeding.

**Prove it is really the Enterprise image.** `ChatwootApp.enterprise?` is
`root.join('enterprise').exist?` (`lib/chatwoot_app.rb`) — it does **not** read
`CW_EDITION`. A CE image is made by *deleting* `enterprise/` (that `rm -rf` lives only in
upstream's FOSS workflow); our workflow has no strip step, so EE is the default outcome.
Check the artifact, not the intent:
```bash
IMG=ghcr.io/lucouto/chatwoot.fazer.ai:v<ver>-ee
docker run --rm --entrypoint sh $IMG -c 'find /app/enterprise -type f | wc -l; echo $CW_EDITION; grep -m1 version: /app/config/app.yml'
```
Expect a few hundred files, `ee`, and the version you tagged.
If the merge build fails on a transient `registry-1.docker.io context deadline exceeded`
(Buildx bootstrap), just re-run: `gh run rerun <run-id> --failed`.

---

## 2. ⚠️ ALWAYS rehearse the migration on prod data FIRST

**This is the most important rule.** A **big-bang multi-version jump** (e.g. 4.10→4.14
in one shot) runs *all* migrations at once with the *final* code loaded. Early data
migrations that reference a model whose **enum/attribute is backed by a column added
by a *later* migration** crash:
```
Undeclared attribute type for enum '<x>' in <Model>
```
We hit this live on prod: migration `20260112092041` (RemoveCountryCodeFromConversationFilters)
loaded `CustomFilter` with `enum :visibility`, but the `visibility` column is added by a
*later* migration `20260510160215`.

**Rehearse the exact prod jump on a throwaway DB before deploying anything.** This is
cheaper than incremental version-stepping and it tests the path prod will actually take.
Migrating staging incrementally does *not* test it — that is precisely why staging passed
and prod broke in June 2026.

```bash
# on the Coolify host: prod dump -> disposable pg -> migrate with the NEW image.
# No web, no sidekiq, no outbound: nothing can email or WhatsApp a real contact.
docker network create migtest-net; docker volume create migtest-pgdata
docker run -d --name migtest-pg --network migtest-net \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=migtest -e POSTGRES_DB=chatwoot_production \
  -v migtest-pgdata:/var/lib/postgresql/data pgvector/pgvector:pg16
docker run -d --name migtest-redis --network migtest-net redis:alpine
docker exec -i migtest-pg pg_restore -U postgres -d chatwoot_production \
  --no-owner --no-acl --clean --if-exists < ~/chatwoot_prod_<date>.dump

docker run --rm --network migtest-net \
  -e RAILS_ENV=production -e POSTGRES_HOST=migtest-pg -e POSTGRES_PORT=5432 \
  -e POSTGRES_USERNAME=postgres -e POSTGRES_PASSWORD=migtest \
  -e POSTGRES_DATABASE=chatwoot_production -e REDIS_URL=redis://migtest-redis:6379 \
  -e SECRET_KEY_BASE=$(head -c48 /dev/urandom | base64 | tr -d /+=) \
  -v /opt/chatwoot-patches/config/initializers/99_fix_pricing_plan_quantity.rb:/app/config/initializers/99_fix_pricing_plan_quantity.rb:ro \
  ghcr.io/lucouto/chatwoot.fazer.ai:v<ver>-ee bundle exec rails db:migrate

# teardown
docker rm -f migtest-pg migtest-redis; docker volume rm migtest-pgdata; docker network rm migtest-net
```
Pass = no `Undeclared attribute` / `PG::` / `rails aborted`, and `db:migrate:status` shows
0 `down`. **Result on 2026-09-17 for 4.14.2 → 4.17.0** (160 applied → 214, 54 migrations,
3 minor versions in one shot): clean, the §6 bug did **not** recur. If it ever does, §6 has
the fix.

---

## 3. Deploy to Coolify (staging, then prod)

1. Coolify → the service → **Edit Compose File** → paste `docker-compose.<env>-<ver>.yaml`.
2. The only volume mount that survives besides `storage`/`assets` is the
   `99_fix_pricing_plan_quantity.rb` Enterprise-unlock patch (see §0). Remove any
   other historical patch mounts (`filter_service.rb`, `show.html.erb`, Azure
   `base_open_ai_service.rb` — that last one would *reintroduce* removed code).
3. **Save** → Coolify pulls the image and redeploys. `docker/entrypoints/rails.sh`
   runs `db:chatwoot_prepare` before booting the server, so migrations run automatically
   (the compose `post_start` hook is belt-and-braces).

**Since 4.17 the worker compose MUST be updated — two lines, both mandatory:**
```yaml
  sidekiq:
    entrypoint: docker/entrypoints/sidekiq.sh          # schema gate (also in the image ENTRYPOINT)
    healthcheck:
      test: ['CMD-SHELL', 'ps aux | grep [s]idekiq | grep -qv entrypoints']
```
The gate holds the worker until `db:abort_if_pending_migrations` passes, because a worker
that boots one migration behind keeps that schema for the life of the process and only
fails on writes that CREATE records — healthy container, empty queue, messages silently
lost. While it waits, its argv still contains `sidekiq`, so the **old** healthcheck
(`ps aux | grep [s]idekiq`) calls a stalled worker healthy. Both lines or neither.

Updating a Coolify service's compose over the API needs the YAML **base64-encoded**:
```bash
PATCH $COOLIFY_API_URL/services/<uuid>   {"docker_compose_raw": "<base64>"}
GET   $COOLIFY_API_URL/services/<uuid>/start
```

SMTP is env-var driven (Gmail, port 587 STARTTLS). Set in Coolify env vars, not compose:
```
SMTP_USERNAME, SMTP_PASSWORD, MAIL_SENDER   (SMTP_ADDRESS/SMTP_PORT default to gmail:587)
```
> Remove any leftover `SMTP_TLS` / `SMTP_SSL` env vars — wrong for port 587 STARTTLS.
> The Gmail app password is in git history → treat as compromised, **rotate it**.

---

## 4. Verify (run on the host)

```bash
RAILS=$(docker ps --format '{{.Names}}' | grep -E '^rails-f8kk' | head -1)   # prod; staging = rails-vkg4
docker exec "$RAILS" sh -c "grep -m1 'version:' /app/config/app.yml"          # => <ver>
docker exec "$RAILS" bundle exec rails runner "puts ChatwootApp.enterprise?"  # => true
docker exec "$RAILS" bundle exec rails db:migrate:status | grep -c down       # => 0
docker exec "$RAILS" ls -la /app/config/initializers/99_fix_pricing_plan_quantity.rb
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://chatwoot.cheminneuf.community
```
> NOTE: in 4.14 `ChatwootApp.config[:version]` raises (`undefined method 'config'`).
> Use the `grep` on `config/app.yml` instead.

Also confirm in-app: **Super Admin → Instance Status** (version, git SHA, edition,
migrations completed, Baileys version). **Trust this over the Coolify badge** (see §7).

---

### Measured cutover cost (4.14.2 → 4.17.0, 2026-09-17)

| | |
|---|---|
| Downtime (503 → 200) | **~110 s** |
| Migrations | 160 → 214 (54), all inside the boot |
| New dead Sidekiq jobs | **0** (the 18 in the set are from June 2026) |
| WhatsApp | Baileys channel back to `connection: open` on its own |
| Prod dump | 777 MB, ~2 min |

Promote the **same image staging ran** — do not re-cut the tag for prod. Rebuilding ships
an artifact nobody tested to fix a provenance question that inspecting the image already
answers.

## 5. Back up prod DB BEFORE the prod deploy

```bash
PG=postgres-f8kkkgcsko4sogs88k8c80ok
docker exec "$PG" sh -c 'pg_dump -U "$POSTGRES_USER" -d chatwoot_production -F c' > ~/chatwoot_prod_<date>.dump
ls -lh ~/chatwoot_prod_<date>.dump   # expect ~140-150 MB, NOT 0 bytes
```
> Eval `$POSTGRES_USER` **inside the container** — the host shell has no
> `$SERVICE_USER_POSTGRES`. A 0-byte dump + `role "root" does not exist` means you
> ran it as the host user; re-run with the in-container env as above.

---

## 6. If the big-bang migration bug bites (§2)

Idempotent fix — pre-create the future column/index, mark the late migration applied,
then resume. Adapt the version/column to whatever the error names:
```bash
RAILS=rails-f8kkkgcsko4sogs88k8c80ok
docker exec "$RAILS" bundle exec rails runner "
c = ActiveRecord::Base.connection
c.execute(%q{ALTER TABLE custom_filters ADD COLUMN IF NOT EXISTS visibility integer NOT NULL DEFAULT 0})
c.execute(%q{CREATE INDEX IF NOT EXISTS index_custom_filters_on_account_type_visibility_user ON custom_filters (account_id, filter_type, visibility, user_id)})
c.execute(%q{INSERT INTO schema_migrations (version) VALUES ('20260510160215') ON CONFLICT DO NOTHING})"
docker exec "$RAILS" bundle exec rails db:migrate     # resumes; should finish all migrations
```
Then restart rails + sidekiq in Coolify.

---

## 7. Coolify "Degraded (unhealthy)" + ghost Postgres — RESOLVED 2026-06-17

**Fixed:** the phantom `ServiceDatabase` record was deleted via its Coolify **Settings → Delete**
(Coolify never auto-prunes orphaned records — issue #9591). Prod has read `running:healthy`
since. Kept below because the symptom can recur after a stack rebuild.

The prod stack showed **two Postgres rows and a "Degraded" badge**. That was **cosmetic**.
- The deployed compose (`/data/coolify/services/f8kk.../docker-compose.yml`) has exactly
  ONE `postgres` service + ONE volume; `docker ps -a --filter ancestor=pgvector/pgvector:pg16`
  shows only the one live healthy container.
- The 2nd row is an orphaned Coolify metadata record from the old 4.10 stack — **no
  container, no volume behind it**. Restart and Edit-Compose→Save→Redeploy do NOT clear it.
- **Judge health by `docker ps` / Instance Status, never the badge.**
- **Simple official fix** (Coolify issue #9591, confirmed by a maintainer): the phantom
  is an orphaned `ServiceDatabase` record Coolify never prunes. Open its **Settings** in
  the UI (it's the Postgres row with only "Settings", no "Backups" → "No storage found"),
  verify it has no volume/container, then **Delete** that single service. The stack goes
  back to healthy and no data is touched (the phantom has no volume). Full procedure in
  `deployment/COOLIFY_GHOST_POSTGRES.md`.
- ⚠️ Do NOT recreate the whole Coolify service to fix this — new service = new ID = new
  volume names → a fresh Postgres would start **empty**.

**NEVER `docker volume rm` or `docker rm` a postgres container to "fix" the badge.**

---

## 8. Rollback

In Coolify set both `rails` and `sidekiq` back to the previous tag and redeploy:
```yaml
image: 'ghcr.io/lucouto/chatwoot.fazer.ai:<previous-ver>-ee'
```
Image rollback alone is normally enough (most migrations are additive). Restore from the
§5 dump only if a migration corrupted data.

---

## 9. After prod is verified

- Merge `upgrade-to-<ver>` → `main` and tag, so the main line matches production.
- ~~Disable upstream's publish workflows on tag triggers~~ — **done 2026-09-17**, see §1.
- Keep `main` equal to what production runs. `main` had drifted behind prod (it lacked the
  `v4.14.2-fazer-ai.85-ee` sidebar commit), which is what made §0's branch-from-prod rule
  necessary. Fast-forward `main` to the upgrade branch as part of the cutover, not months later.
- Update the "Current prod version" row in §0 and the memory file
  `chatwoot-fork-upgrade-2026-06.md`.
