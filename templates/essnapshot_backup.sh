#!/usr/bin/env bash
set -x

WEBHOOK_URL='{{SLACK_URL}}'

# Corresponding cronjob is "0 0 * * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh"

curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E" | grep accepted\":true
if [ $? -ne 0 ]
then
	curl -X POST -H 'Content-type: application/json' --data '{"text":"Taking snapshot failed."}' $WEBHOOK_URL
else
	aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 sync /home/ubuntu/compose_setup/essnapshot s3://logstash-elasticdata/essnapshot
	if [ $? -ne 0 ]
	then
		curl -X POST -H 'Content-type: application/json' --data '{"text":"Sending snapshot to s3 failed."}' $WEBHOOK_URL
	fi
fi
