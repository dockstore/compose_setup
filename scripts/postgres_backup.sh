#!/usr/bin/env bash
set -x
set -e

cd compose_setup
s3_url_db_backup='s3://oicr.backups.dockstore/staging.dockstore.org/database/'`date +%Y-%m-%d`
s3_url_config_backup='s3://oicr.backups.dockstore/staging.dockstore.org/config/'`date +%Y-%m-%d`
temp_dir=`mktemp -d`
output_file=ds-webservice_${2:-prod}_`date +%Y-%m-%dT%H-%M-%S%z`.sql

/usr/local/bin/docker-compose exec -T --user postgres postgres pg_dump > $temp_dir/$output_file

aws s3 --region us-east-1 cp $temp_dir/$output_file $s3_url_db_backup/
aws s3 --region us-east-1 cp /home/ubuntu/compose_setup/dockstore_launcher_config/compose.config $s3_url_config_backup/

echo "Dumped database ${1:-webservice} and uploaded to $s3_url_db_backup/$output_file."
echo "Config backup to $s3_url_config_backup/"