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
| Build workflow | `.github/workflows/publish_my_ee_docker.yml` — **the only automatic publisher**; on push of tag `v*`, builds multi-arch (amd64+arm64), asserts the fork customizations, appends `-ee` **only if absent** |
| Deploy platform | **Coolify** on host `vm-coolify-n8n` (ssh `azureuser@vm-coolify-n8n`) |
| **PROD Coolify service** | `f8kkkgcsko4sogs88k8c80ok` ("chatwoot-fazer") → https://chatwoot.cheminneuf.community, DB `chatwoot_production` |
| **STAGING Coolify service** | `vkg4sgcco4wg8os4sckws088` ("Chatwoot Fazer.ai Staging") → https://staging-chatwoot.cheminneuf.community, DB `chatwoot_staging` |
| Container naming | `<component>-<service-uuid>`, e.g. `postgres-f8kkkgcsko4sogs88k8c80ok`, `rails-vkg4sgcco4wg8os4sckws088` |
| ⚠️ Not a service uuid | `q4sgkowosk88os848k008o0o` is the Coolify **project** "Production Stack" that contains *every* service — prod, staging and everything unrelated. Both stacks above live inside it; they are separate **services**, not separate projects. |
| Compose files (repo) | `docker-compose.production-<ver>.yaml`, `docker-compose.staging-<ver>.yaml` |
| Current prod version | **v4.17.0-fazer-ai.115-ee** (cut over 2026-09-17 19:43 CEST) |
| Current staging version | **v4.17.0-fazer-ai.115-ee** (as of 2026-09-17) |
| Repo topology | **single branch `main`** — every historical branch was folded in and deleted 2026-09-17 |
| Rollback target | `v4.14.2-fazer-ai.85-ee` → commit `6105d475a` (tag, not a branch) |

### ⚠️ Confirm `main` IS what prod runs before branching

The repo is single-branch now, so `main` *should* be production — but check, because it
silently wasn't once. In Sept 2026 prod ran `v4.14.2-fazer-ai.85-ee` = commit `6105d475a`,
carrying `fix(sidebar): remove native Kanban entry`, which lived on a side branch `main`
never got. Branching that upgrade off `main` would have reintroduced the native Kanban menu
item, and nothing would have complained. Two seconds to verify:

```bash
ssh coolify-vm 'docker inspect rails-f8kkkgcsko4sogs88k8c80ok --format "{{.Config.Image}}"'
git merge-base --is-ancestor $(git rev-parse <that-tag>^{commit}) main \
  && echo "main contains prod - branch from main" \
  || echo "DRIFT - branch from the tag's commit, not main"
```

Belt as well as braces: §1's publish workflow now fails the build if a fork customization
is missing, so a wrong base can no longer ship quietly.

**Why we build our own image** (not fazer-ai's stock): we keep customizations. As of
v4.17.0 there are exactly **three**, all frontend, all asserted by CI on every publish:

| customization | file |
|---|---|
| `OPERATOR_TYPES_7` defined | `app/javascript/dashboard/routes/dashboard/settings/automation/operators.js` |
| text custom attributes use it | `app/javascript/dashboard/helper/automationHelper.js` |
| custom attributes resolve in create mode too | `app/javascript/dashboard/helper/automationHelper.js` |

Plus one *removal*: the native Kanban sidebar entry stays out of
`components-next/sidebar/Sidebar.vue` (upstream keeps re-adding it; we use external
KanbanCW). Everything else was upstreamed or reverted — Azure OpenAI was abandoned.

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
git checkout -b upgrade-to-<ver> main    # main, after the §0 drift check
git merge <upstream-tag>                # e.g. v4.17.0-fazer-ai.115
# Resolve conflicts (every upgrade so far: only the config/app.yml version line).
# Large upstream merges OOM-kill the husky/eslint pre-commit hook — use:
git commit --no-verify

# Tag + push to trigger the build.
git tag <upstream-tag>-ee               # e.g. v4.17.0-fazer-ai.115-ee
git push origin upgrade-to-<ver> <upstream-tag>-ee
```

> **Tag the `-ee` name explicitly.** You cannot reuse the bare upstream tag name — after
> `git fetch upstream --tags`, `v4.17.0-fazer-ai.115` already exists locally and points at
> *upstream's* commit, so `git tag v4.17.0-fazer-ai.115` fails. The workflow handles either
> spelling (it appends `-ee` only when absent), so always tag `<upstream-tag>-ee` and the
> image lands at `ghcr.io/lucouto/chatwoot.fazer.ai:<upstream-tag>-ee`.

**Before merging, dry-run it in a throwaway worktree** — it costs nothing and tells you the
conflict surface before you commit to anything:
```bash
git worktree add --detach /tmp/mergetest main
cd /tmp/mergetest && git merge --no-commit --no-ff <upstream-tag>
git diff --name-only --diff-filter=U        # expect: config/app.yml, nothing else
cd - && git worktree remove --force /tmp/mergetest
```

### Only ONE workflow may publish — fixed 2026-09-17

Six workflows could publish to this repo's ghcr. `build_custom_ee_image.yml` fired on the
same `v*-ee` tag, built the same image and pushed the **same tag**; since each platform job
pushes the tag directly, whichever finished last won. On v4.17.0-fazer-ai.115-ee the primary
workflow published a correct 2-arch manifest at 16:42:46, the duplicate clobbered it with an
amd64-only one, and it only became 2-arch again when the duplicate's own merge job finished.
Both were valid EE images — *which* one you got was luck.

The three release-triggered publishers were the same defect unfired: they push to this ghcr
**and move the floating `:latest` / `:latest-ee` / `:beta`**, so cutting a GitHub Release
would have overwritten a published image with a differently-built one.

**All six are now `workflow_dispatch`-only**, leaving `publish_my_ee_docker.yml` as the sole
automatic publisher (`push: tags: v*`). It also gained a **pre-publish check** that fails the
build if any of the three customizations is missing, if the native Kanban entry returns, or
if `enterprise/` is absent.

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
**Current rollback target: `v4.14.2-fazer-ai.85-ee`** (commit `6105d475a`).

Image rollback alone is normally enough — migrations are additive, and 4.14.2 tolerates the
4.17 schema. Restore from the §5 dump only if a migration corrupted data.

Rollback does **not** depend on any branch. All upgrade branches were deleted 2026-09-17;
every commit that matters is pinned by a tag and reachable from `main`:

| tag | commit | what it is |
|---|---|---|
| `v4.17.0-fazer-ai.115-ee` | `0478ecdf7` | what prod runs (Instance Status shows `Build 0478ecd`) |
| `v4.14.2-fazer-ai.85-ee` | `6105d475a` | rollback target |

If you roll back, put the §5 dump somewhere safe first — it is the only copy of the
pre-cutover data.

---

## 9. After prod is verified

Do this in the same session as the cutover. The drift in §0 happened precisely because it
was left for later.

```bash
# 1. main takes the upgrade, then the branch goes away - keep the repo single-branch
git checkout main && git merge --ff-only upgrade-to-<ver>
git push origin main
git branch -d upgrade-to-<ver>                 # -d, not -D: it must refuse if unmerged
git push origin --delete upgrade-to-<ver>
```

2. **Backups on the Coolify host.** Keep the pre-cutover dump until the new version has run
   a few normal days — it is the rollback data. Delete any rehearsal dump from §2, which is
   redundant the moment the cutover succeeds. Verify the keeper is readable *before*
   removing the other, so there is never a moment without a good backup:
   ```bash
   docker run --rm -v /home/azureuser:/bk pgvector/pgvector:pg16 \
     pg_restore -l /bk/<keep>.dump | wc -l      # ~1230 entries, no stderr
   rm /home/azureuser/<redundant>.dump
   ```

3. **Update this file**: the `Current prod version` / `Rollback target` rows in §0, and the
   §5 measured-cost table if the numbers moved. Then the memory file
   `chatwoot-fork-upgrade-2026-06.md`.

4. Leave the release tags alone forever — §8 rollback depends on them, not on branches.
