# compose\_setup
This project documents how to setup Dockstore staging and production using composed Docker containers. 
Log issues and see general documentation at [dockstore](https://github.com/ga4gh/dockstore/issues) and [docs.dockstore.org](https://docs.dockstore.org/) respectively

Ports 80 and 8443 are exposed over http. These ports should not be exposed to the public. A separately [configured load
balancer](https://github.com/dockstore/dockstore-deploy) is responsible for SSL termination and forwarding traffic to this instance. Previously this repo handled the SSL termination with nginx and LetsEncrypt.

## Prerequisities

1. Tested on Ubuntu 16.04.3 LTS
1. At least 20GB of disk space, 4GB of RAM, and two CPUs
1. Docker setup following [https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/) including the post-installation steps for running without sudo
1. The running Dockstore website will require ports 80, 8443, and 443 by default
1. A client id and client secret for each of the integrations you wish to setup, github and quay.io as a minimum probably. You will need client ids and secrets for each integration as documented at the [Dockstore Primer](https://wiki.oicr.on.ca/display/SEQWARE/Dockstore+Primer#DockstorePrimer-SettingupDockstoreonyourcomputerfordevelopment(AssumingUbuntu)).

## Usage

1. Call the install\_bootstrap script. This templates the contents of `templates` using mustache to the `config` directory while recording your answers for future use. Note that this will also
rebuild your docker images without affecting existing running containers 

2. Some additional information on the answers requested in the script
    1. Each integration requires a client id and a secret, it is worth saying that you should not check these in 
    2. The discourse URL is needed to link Dockstore to a discussion forum 
    3. the Google verification code and tag manager ID are used if you want to properly track visitors to Dockstore and what pages they browse to

3. The bootstrap script can also rebuild your Docker images. Keep in mind the following handy commands:
    1. `install_bootstrap --script` will template and build everything using your previous answers (useful for quick iteration) 
    2. `docker-compose down` will bring all containers down safely 
    3. `nohup docker-compose up --force-recreate --remove-orphans >/dev/null 2>&1 &` will re-create all containers known to docker-compose and delete those volumes that no longer are associated with running containers
    4. `docker system prune` for cleaning out old containers and images
    5. To watch the logs `docker-compose logs --follow` while debugging

4. After following the instructions in the bootstrap script and starting up the site with `docker-compose`, you can browse to the Dockstore site hosted at port 443 by default. `https://<domain-name>` if you specified https or `http://<domain-name>:443` if you did not. 

5.  Note that the following volumes are created, `composesetup_esdata1` for ephermeral elastic search data, `composesetup_log_volume` for logging, and `composesetup_ui2_content` for storing the built UIs before they are handed off the nginx for service. 
    
6. For database backups, you can use a script setup in the cron for the host

```
@daily 		(echo '['`date`'] Nightly Back-up' && /home/ubuntu/compose_setup/scripts/postgres_backup.sh) 2>&1 | tee -a /home/ubuntu/compose_setup/scripts/ds_backup.log
```

This relies upon an IAM role for the appropriate S3 bucket. You will also need the AWS cli installed via ` sudo apt-get install awscli`. Note that this may not be readily apparent since a cron has a limited $PATH and it seems easy to accidentally get the awscli installed for specific users. 

### Loading Up a Database ###

The docker-compose setup uses a mount from the host to keep the postgres database persistent (which is different from elastic search which is not) 

However, this does require a convoluted way to add content to the DB as follows

```
docker-compose down
# needed since dropping the schema can still leave some user information behind
sudo rm -Rf postgres-data/
nohup docker-compose up --force-recreate --remove-orphans &
docker cp /tmp/backup.sql <container>:/tmp
docker exec -ti <container> /bin/bash
su - postgres
psql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
CREATE USER dockstore WITH password 'dockstore';
ALTER DATABASE postgres OWNER to dockstore;
ALTER SCHEMA public OWNER to dockstore;
\quit
psql postgres -U dockstore -f  /tmp/backup.sql 
# exit container (ctrl+d) and then run migration using newly loaded DB
docker-compose down
nohup docker-compose up --force-recreate --remove-orphans &
```


Note that database migration is run once during the startup process and is controlled via the `DATABASE_GENERATED` variable. Answer `yes` if you are working as a developer and want to start work from scratch from an empty database. Answer `no` if you are working as an administrator and/or wish to start Dockstore from a production or staging copy of the database.

### Modifying the Database ###

If direct modification of the database is required, e.g, a curator needs to modify the value of some row/column that is not accessible via the API, you can use the same steps as above, except for dropping the schema.

This should be exercised with extreme caution, and with someone looking over your shoulder, as you have the potential to unintentionally overwrite or delete data. If you wish to proceed:

```
# Assuming you copied a file `fix.sql` to the /tmp directory:
docker cp /tmp/fix.sql <container>:/tmp
docker exec -ti <container> /bin/bash
su - postgres
psql -f  /tmp/fix.sql 
```

## Logging Usage

If using with logstash in a container (for development), use `-f docker-compose.yml -f docker-compose.dev.yml` flags after each `docker-compose` command to merge docker-compose files (e.g. `docker-compose -f docker-compse.yml -f docker-compose.dev.yml build`) 

For example to deploy just logging 

```
docker-compose  -f docker-compose.dev.yml build
nohup docker-compose -f docker-compose.dev.yml up --force-recreate --remove-orphans >/dev/null 2>&1 &
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml kill
```

### Kibana Dashboard Setup ###
Import the [export.json](export.json) Dashboard from compose\_setup/export.json by going to Kibana's management => saved objects => import.  See https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html for more info, especially the 2nd warning.

## Installing git-secrets
Dockstore uses git-secrets to help make sure that keys and private data stay out
of the source tree.
To install and check for git secrets:

```
npm ci
npm run install-git secrets
``` 

This should install git secrets into your local repository and perform a scan. 
If secrets are found, the run will error and output the potential secret to stdout.
If you believe the scan is a false-positive, add the line glob to .gitallowed.
