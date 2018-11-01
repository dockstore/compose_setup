#!/usr/bin/env bash
set -x
set -e

# Corresponding cronjob is "0 0 * * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh"

curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E"
aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 sync /home/ubuntu/compose_setup/essnapshot s3://logstash-elasticdata/essnapshot

echo "Uploaded essnapshot to https://object.cancercollaboratory.org:9080 s3://logstash-elasticdata/essnapshot"
