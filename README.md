# compose\_setup
This project documents how to setup Dockstore staging and production using composed Docker containers. 

## Prerequisities

1. Tested on Ubuntu 16.04.3 LTS
1. At least 20GB of disk space, 4GB of RAM, and two CPUs
1. Docker setup following [https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/) including the post-installation steps for running without sudo
1. The running Dockstore website will require ports 80, 8443, and 443 by default
1. A client id and client secret for each of the integrations you wish to setup, github and quay.io as a minimum probably

## Usage

1. Create a HTTP certificate if you want to run in HTTPS mode
```
docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot certonly --agree-tos  -m <your email address here> --webroot --webroot-path=/data/letsencrypt --staging  -d staging.dockstore.org -d staging.dockstore.org
```
    
  Change --staging as necessary and the domain names as necessary
    
  For example, for renewing staging on a monthly basis, stick this in the crontab
  ```
  docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot renew
  docker-compose restart nginx_https
  ```
2. Call the install_bootstrap script. This templates the contents of `templates` using mustache to the `config` directory while recording your answers for future use. It can also rebuild your Docker images and spin them up although you may wish to disable this while doing development. Keep in mind the following handy commands:
    1. `docker-compose build --no-cache` will rebuild all your images from scratch, useful if you have cached out-of-date information, such as a git checkout of the UI1 or UI2
    2. `docker-compose up --force-recreate --remove-orphans` will re-create all containers known to docker-compose and delete those volumes that no longer are associated with running containers
    3. `docker system prune` for cleaning out old containers and images

3. Follow the instructions in the bootstrap script, you should be able to browse to the running website 

4.  Note that the following volumes are created, `composesetup_certs` and `composesetup_certs-data` for https certificates, `composesetup_esdata1` for ephermeral elastic search data, `composesetup_log_volume` for logging, and `composesetup_ui1_content` and its ui2 equivalent for storing the built UIs before they are handed off the nginx for service. 
    
6. For database backups, you can use a script setup in the cron for the host

```
@monthly	docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt certbot/certbot renew && docker-compose restart nginx_https && curl -sm 30 k.wdt.io/denis.yuen@oicr.on.ca/staging.https.renew?c=0_0_1_*_* 
@daily 		(echo '['`date`'] Nightly Back-up' && /home/ubuntu/compose_setup/scripts/postgres_backup.sh) |  tee /home/ubuntu/compose_setup/scripts/ds_backup.log
```

This relies upon an IAM role for the appropriate S3 bucket. 
