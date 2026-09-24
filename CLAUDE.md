# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo holds configuration templates for running the Dockstore webservice and UI on AWS ECS/Fargate. There is no application code here. The repo contains Mustache templates, static config, Dockerfiles for the ELK logging stack, and shell scripts. Local Dockstore development belongs in the main `dockstore/dockstore` repo, not here.

Related repos:
- `dockstore/dockstore-deploy` checks this repo out as a **git submodule**. Its `cdk-templates/dockstore` Fargate stack fills in these templates from a Secrets Manager secret (`/DeploymentConfig/<env>/BootstrapConfigFile`) that holds the same key/value pairs as `compose.config`. A new key added here therefore also has to be added to that secret in each environment.
- `dockstore/dockstore` is the webservice itself. It owns the Liquibase changelogs whose version contexts `init_migration.sh.template` lists, and the Dropwizard config schema that `web.yml.template` fills in.

## Commands

```bash
# Render all templates into config/ (and a few into scripts/). Requires `mustache` (Ruby gem) and `jq`.
bash install_bootstrap --script

# Validate the rendered nginx config (this is what CI does)
docker run -v $PWD/config/nginx-conf/default.nginx_http.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $PWD/config/nginx-conf/default.nginx_http.shared.conf:/etc/nginx/conf.d/default.nginx_http.shared.conf:ro \
  -v $PWD/config/nginx-conf/default.nginx_http.security.conf:/etc/nginx/conf.d/default.nginx_http.security.conf:ro \
  nginx:1.13.1 nginx -t -c /etc/nginx/nginx.conf

# Secret scanning (also installs git-secrets hooks via husky)
npm ci
npm run install-git-secrets

# Dev ELK logging stack (elasticsearch-logstash, logstash, kibana, elastalert)
docker compose -f docker-compose.dev.yml build
docker compose -f docker-compose.dev.yml up --force-recreate --remove-orphans
```

There is no test suite. CI (`.github/workflows/docker-image.yml`) runs the git-secrets scan, renders the templates with `install_bootstrap --script`, and runs `nginx -t` on the result. Run both locally to check a change.

## How templating works

- `dockstore_launcher_config/compose.config` is a flat JSON file of every template variable. The committed copy holds only placeholder values (`replaceme`, `foobar`). Real values are supplied at deploy time and must never be committed.
- `install_bootstrap` loads that JSON as shell variables through `jq`. It uses `UI2_HASH` to download the UI's `index.html`/`manifest.json` from `gui.dockstore.org`. It then runs `mustache compose.config <template> > <output>` for each template. Outputs go to `config/nginx-conf/`, `config/nginx-html2/`, `config/webservice/`, `config/rules/` and `config/*`. `scripts/essnapshot_backup.sh` and `scripts/postgres_backup.sh` are generated too. All of these are gitignored.
- **Adding a new config value:** add the key to `compose.config`, keeping the keys alphabetical, and reference it in the relevant template (usually `templates/web.yml.template`, the Dropwizard config). In Mustache, `{{ X }}` HTML-escapes the value and `{{{ X }}}` does not. Use triple braces for passwords and other values that may contain special characters. Boolean keys drive sections (`{{#X}}...{{/X}}` / `{{^X}}...{{/X}}`).
- Any new template must also get its own `mustache` line in the `template()` function of `install_bootstrap`, or it won't be rendered.
- `staticConfig/` holds config that is mounted as-is without templating (ELK and elastalert). `templates/rules/` holds the elastalert rules. They are templated because they need `SLACK_URL`.

## Database migrations (recurring release task)

`templates/init_migration.sh.template` runs the webservice JAR's `db migrate` with Liquibase `--include` contexts. Each Dockstore release appends its version (e.g. `1.21.0`) to the comma-separated list on the **last** line, which runs as the `dockstore` user. Leave the earlier lines alone. They handle the `DATABASE_GENERATED` fresh-DB versus existing-DB paths and the `1.7.0.relinquish` step, which must run as `postgres`.

## Branching

The repo follows Hubflow (gitflow) conventions. `develop` is the main integration branch and the default target for PRs. Work is done on `feature/*` branches cut from `develop` and merged back into it. `hotfix/*` branches are for urgent fixes, and `release/*` branches are cut for releases and tagged.

## Pull requests

Always create PRs in draft mode (e.g. `gh pr create --draft`). Only a human may take a PR out of draft and mark it ready for review. Never do that yourself.

Always check with the user before pushing to GitHub, even to a branch or PR already being worked on in the conversation. A push can start a CI build or interrupt one that is already running.

Fill out PRs using `.github/PULL_REQUEST_TEMPLATE.md` (Description, Review Instructions, Issue as a GitHub issue or `SEAB-` ticket) instead of a generic Summary/Test plan format. Keep Description and Review Instructions to one paragraph each, or two for a genuinely complicated change. Copy the template's checkboxes verbatim. Never reword, reformat or condense them, and never add text to an item. Change `[ ]` to `[x]` only after actually confirming that item for this PR.

Diff the work against `develop` (or whatever branch the PR targets). Avoid stylistic or other minor changes that inflate the diff, unless they fix something a code-quality check (e.g. CodeQL) actually flagged.

### Using CI and review feedback

- Use GitHub Actions results (check runs, job logs) through `gh` or the GitHub MCP server to diagnose failures instead of guessing.
- Review comments from human developers are high-priority direction. Investigate each one and propose a concrete fix, even without being asked. Bot-authored comments are useful but come second to human reviewers.

## JIRA

When adding comments to JIRA tickets, clearly indicate that Claude wrote the comment. For example, start with a line like "This comment was generated by Claude (Claude Code)."

## Other conventions

- git-secrets runs through the husky hooks on commit. Add real false positives to `.gitallowed`.
- `docker-compose.yml` and the EC2-based setup were removed in `ff22ced`, and `install_bootstrap` no longer prompts interactively. Old docs or comments that mention them are stale.
