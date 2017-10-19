# compose\_setup
Demonstrate how to setup and run Dockstore using composed containers

## Usage

To create a HTTP certificate (necessary for running in HTTPS mode)

    docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot certonly --agree-tos  -m <your email address here> --webroot --webroot-path=/data/letsencrypt --staging  -d staging.dockstore.org -d staging.dockstore.org

Change --staging as necessary and the domain names as necessary

For example, for renewing staging on a monthly basis, stick this in the crontab

```
docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot renew
docker-compose restart nginx_https
```

For database backups, you can use a script setup in the cron

```
@monthly	docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt certbot/certbot renew && docker-compose restart nginx_https && curl -sm 30 k.wdt.io/denis.yuen@oicr.on.ca/staging.https.renew?c=0_0_1_*_* 
@daily 		(echo '['`date`'] Nightly Back-up' && /home/ubuntu/compose_setup/scripts/postgres_backup.sh) |  tee /home/ubuntu/compose_setup/scripts/ds_backup.log
```

This relies upon an IAM role for the appropriate S3 bucket. 
