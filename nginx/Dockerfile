FROM nginx:latest

USER root

RUN apt-get update

RUN apt-get install -y git

RUN git clone https://github.com/certbot/certbot /opt/letsencrypt

RUN mkdir -p /var/www/letsencrypt/

RUN chgrp -Rf www-data /var/www/letsencrypt/

RUN mkdir -p /var/www/html

RUN mkdir -p /.well-known/acme-challenge/

RUN chown 755 /.well-known/acme-challenge/

