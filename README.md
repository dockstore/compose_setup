# compose\_setup
This project contains configuration template files needed to run Dockstore using AWS Fargate. View the [dockstore-deploy repository](https://github.com/dockstore/dockstore-deploy)
for more information about how Dockstore is setup using AWS Fargate.
Log issues and see general documentation at [dockstore](https://github.com/ga4gh/dockstore/issues) and [docs.dockstore.org](https://docs.dockstore.org/) respectively

If you are looking for how to run Dockstore locally as a developer, you are probably in the wrong place and should take a look at https://github.com/dockstore/dockstore/blob/develop/docker-compose.yml

## Prerequisites

1. `mustache` (the Ruby gem, `gem install mustache`), `jq`, and `wget` to render the templates
1. Docker with Compose v2 (`docker compose`) if you want to run the development logging stack
1. A client id and client secret for each of the integrations you wish to setup, github and quay.io as a minimum probably. You will need client ids and secrets for each integration as documented on the internal [wiki](https://wiki.oicr.on.ca/display/DOC/OAuth+Apps+and+Other+3rd+Party+Registration).

## Usage

1. Fill in `dockstore_launcher_config/compose.config`, a flat JSON file of every templated value. The committed copy only contains placeholder values; do not check in real client ids, secrets, or passwords.
    1. Each integration requires a client id and a secret
    2. The discourse URL is needed to link Dockstore to a discussion forum
    3. The tag manager ID is used if you want to properly track visitors to Dockstore and what pages they browse to
    4. `UI2_HASH` selects the version of the UI whose `index.html` and `manifest.json` are downloaded from `gui.dockstore.org`

2. Run `bash install_bootstrap`. It reads `compose.config` and templates the contents of `templates` into the `config` directory (plus `scripts/essnapshot_backup.sh` and `scripts/postgres_backup.sh`) using mustache. It does not prompt for answers.

3. In staging and production, [dockstore-deploy](https://github.com/dockstore/dockstore-deploy) includes this repo as a submodule and supplies the `compose.config` values from AWS Secrets Manager. When you add a new key to `compose.config`, it also needs to be added there. After the site is started with AWS Fargate, you can browse to it at `https://<domain-name>`.

The current setup relies upon an externally hosted container orchestration service (currently AWS ECS with Fargate), externally hosted database (currently AWS RDS) and externally hosted search (currently AWS Elasticsearch).

### Loading Up a Database ###

Loading up a database is usually not necessary since AWS RDS is persistent. Refer to https://github.com/dockstore/dockstore-deploy#database-setup

Note that database migration is run once during the startup process (`templates/init_migration.sh.template`) and is controlled via the `DATABASE_GENERATED` value in `compose.config`. Set it to `true` if you are working as a developer and want to start work from scratch from an empty database. Set it to `false` if you are working as an administrator and/or wish to start Dockstore from a production or staging copy of the database.

When a new Dockstore release adds database migrations, add its version to the `--include` list on the last line of `templates/init_migration.sh.template`.


## Logging Usage

The development logging stack (Elasticsearch, Logstash, Kibana, ElastAlert) is defined in `docker-compose.dev.yml`. Its containers use the `awslogs` logging driver, so `LOG_GROUP_NAME` must be set in the environment (or in a `.env` file). Run `bash install_bootstrap` first so that the files it mounts from `config/` exist.

```
docker compose -f docker-compose.dev.yml build
nohup docker compose -f docker-compose.dev.yml up --force-recreate --remove-orphans >/dev/null 2>&1 &
docker compose -f docker-compose.dev.yml logs --follow
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml kill
```

`--force-recreate --remove-orphans` re-creates all containers known to compose and removes containers for services that no longer exist. `docker system prune` cleans out old containers and images. See [DEV-README.md](DEV-README.md) for more details on the logging stack.

### Kibana Dashboard Setup ###
Import the [export.json](export.json) Dashboard from compose\_setup/export.json by going to Kibana's management => saved objects => import.  See https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html for more info, especially the 2nd warning.

## Installing git-secrets
Dockstore uses git-secrets to help make sure that keys and private data stay out
of the source tree.
To install and check for git secrets:

```
npm ci
npm run install-git-secrets
``` 

This should install git secrets into your local repository and perform a scan. 
If secrets are found, the run will error and output the potential secret to stdout.
If you believe the scan is a false-positive, add the line glob to .gitallowed.
