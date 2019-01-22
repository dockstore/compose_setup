# compose\_setup
This project documents how to setup Dockstore staging and production using composed Docker containers. 
Log issues and see general documentation at [dockstore](https://github.com/ga4gh/dockstore/issues) and [docs.dockstore.org](https://docs.dockstore.org/) respectively

## Prerequisities

1. Tested on Ubuntu 16.04.3 LTS
1. At least 20GB of disk space, 4GB of RAM, and two CPUs
1. Docker setup following [https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/) including the post-installation steps for running without sudo
1. The running Dockstore website will require ports 80, 8443, and 443 by default
1. A client id and client secret for each of the integrations you wish to setup, github and quay.io as a minimum probably. You will need client ids and secrets for each integration as documented at the [Dockstore Primer](https://wiki.oicr.on.ca/display/SEQWARE/Dockstore+Primer#DockstorePrimer-SettingupDockstoreonyourcomputerfordevelopment(AssumingUbuntu)).

## Usage

1. Create a HTTP certificate if you want to run in HTTPS mode. Note that you'll actually have to create the certificate while nginx\_http is up and running.
```
docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot certonly --agree-tos  -m <your email address here> --webroot --webroot-path=/data/letsencrypt --staging  -d staging.dockstore.org -d staging.dockstore.org
```
Change --staging as necessary and the domain names as necessary to match where you are tryign to setup Dockstore.  Additionally, let's encrypt certificates expire in 90 days, you will want to renew them and restart nginx to pick up the new certificates. For example, for renewing staging on a monthly basis, stick this in the crontab

```
docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot renew
docker-compose restart nginx_https
```

2. Call the install\_bootstrap script. This templates the contents of `templates` using mustache to the `config` directory while recording your answers for future use. Note that this will also
rebuild your docker images without affecting existing running containers 

3. Some additional information on the answers requested in the script
    1. Each integration requires a client id and a secret, it is worth saying that you should not check these in 
    2. The discourse URL is needed to link Dockstore to a discussion forum 
    3. the Google verification code and tag manager ID are used if you want to properly track visitors to Dockstore and what pages they browse to

4. The bootstrap script can also rebuild your Docker images. Keep in mind the following handy commands:
    1. `install_bootstrap --script` will template and build everything using your previous answers (useful for quick iteration) 
    2. `docker-compose down` will bring all containers down safely 
    3. `nohup docker-compose up --force-recreate --remove-orphans &` will re-create all containers known to docker-compose and delete those volumes that no longer are associated with running containers
    4. `docker system prune` for cleaning out old containers and images

5. After following the instructions in the bootstrap script and starting up the site with `docker-compose`, you can browse to the Dockstore site hosted at port 443 by default. `https://<domain-name>` if you specified https or `http://<domain-name>:443` if you did not. 

6.  Note that the following volumes are created, `composesetup_certs` and `composesetup_certs-data` for https certificates, `composesetup_esdata1` for ephermeral elastic search data, `composesetup_log_volume` for logging, and `composesetup_ui2_content` for storing the built UIs before they are handed off the nginx for service. 
    
7. For database backups, you can use a script setup in the cron for the host

```
@monthly	docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt certbot/certbot renew && docker-compose restart nginx_https && curl -sm 30 k.wdt.io/denis.yuen@oicr.on.ca/staging.https.renew?c=0_0_1_*_* 
@daily 		(echo '['`date`'] Nightly Back-up' && /home/ubuntu/compose_setup/scripts/postgres_backup.sh) |  tee /home/ubuntu/compose_setup/scripts/ds_backup.log
```

This relies upon an IAM role for the appropriate S3 bucket. 

### Loading Up a Database ###

The docker-compose setup uses a mount from the host to keep the postgres database persistent (which is different from elastic search which is not) 

However, this does require a convoluted way to add content to the DB as follows

```
docker cp /tmp/backup.sql <container>:/tmp
docker exec -ti <container> /bin/bash
su - postgres
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\quit
psql -f  /tmp/backup.sql 
```

Note that database migration is run once during the startup process and is controlled via the `DATABASE_GENERATED` variable. Answer `yes` if you are working as a developer and want to start work from scratch from an empty database. Answer `no` if you are working as an administrator and/or wish to start Dockstore from a production or staging copy of the database.

## Logging Usage

If using with logstash in a container (for development), use `-f docker-compose.yml -f docker-compose.dev.yml` flags after each `docker-compose` command to merge docker-compose files (e.g. `docker-compose -f docker-compse.yml -f docker-compose.dev.yml build`) 

For example to deploy just logging 

```
docker-compose  -f docker-compose.dev.yml build
nohup docker-compose -f docker-compose.dev.yml up --force-recreate --remove-orphans &
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml kill
```

### Kibana Dashboard Setup ###
Import the [export.json](export.json) Dashboard from compose\_setup/export.json by going to Kibana's management => saved objects => import.  See https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html for more info, especially the 2nd warning.

