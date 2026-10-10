# Drumandbytes infra

Self-hosted oracle-x64 Docker builds use driver: docker and keep the local build cache; cleanup caps it with docker buildx prune --builder default --max-used-space 20GB, never system prune --all.

# New repo setup (drumandbytes org)

When creating a new repo under the `drumandbytes` org, consider adding Dependabot (`.github/dependabot.yml`) and, if applicable, the `drumandbytes/reusable-actions` auto-merge workflow — as part of initial setup, not as a later retrofit. Applicable = the repo has real dependencies (a package ecosystem and/or pinned GitHub Actions) and a `CI` workflow for auto-merge's `workflow_run` trigger to hook into. Skip for static/no-dependency repos, issue trackers, and forks. If the repo uses `release-please` with the `dnb-robot` bot, auto-merge needs `patch-only-authors: '["dnb-robot[bot]"]'` and `use-app-token-for-merge: true` (see `eraser` or `music-router` for the exact shape); otherwise the reusable workflow's defaults need no extra inputs.

For every public-facing Drumandbytes website or app, add a normal crawlable link to `https://drumandbytes.com/projects/` in the global footer, About panel, or equivalent persistent site chrome. Use descriptive text such as “Drumandbytes Projects” or “Part of Drumandbytes”; do not add the link to authenticated or distraction-free screens where the product intentionally hides global navigation. For public GitHub repositories, ensure the README has a prominent live-site or project-hub link near the top when useful; do not add boilerplate backlinks to every README footer solely for SEO.

When adding a new public Drumandbytes site/hostname or a Cloudflare tunnel hostname, also (both lists are hand-maintained and drift silently):
- Add its route to `cloudflare-workers/ref-logger/wrangler.toml` (explicit hosts only, never zone wildcards). If the host already has its own route Worker, call `logRef()` there with the `dnb_refs` Analytics Engine binding instead (as `quantum-de-plan` and Mystery-Game do).
- Add tunnel hostnames to the host lists in `cluster/apps/grafana-dashboards/dashboards/cloudflare-tunnel.json` (talos = `proxmox-opentofu` `tunnel_services`; ghost-hetzner = `dnb-cloudflare-tf` CNAMEs to `<tunnel-id>.cfargotunnel.com`).
- Links to it from GitHub READMEs get `?ref=<repo>-readme`, hidden behind link text; never put `?ref=` in a repo's About-sidebar website URL (it's shown verbatim).
