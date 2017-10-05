# compose_setup
Demonstrate how to setup and run Dockstore using composed containers

## Developers

To create a HTTP certificate (necessary for running in HTTPS mode)

    docker run -it --rm -v composesetup_certs:/etc/letsencrypt -v composesetup_certs-data:/data/letsencrypt   certbot/certbot certonly --agree-tos  -m <your email address here> --webroot --webroot-path=/data/letsencrypt --staging  -d staging.dockstore.org -d staging.dockstore.org

Change --staging as necessary and the domain names as necessary


