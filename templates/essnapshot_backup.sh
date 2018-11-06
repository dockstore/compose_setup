#!/usr/bin/env bash
set -x

WEBHOOK_URL='{{SLACK_URL}}'

today=`date +%Y-%m-%d.%H:%M:%S`
dayofmonth=`date +%d`
mkdir -p /home/ubuntu/compose_setup/logs
filename="/home/ubuntu/compose_setup/logs/$today"
# Corresponding cronjobs are:
# "0 0 * * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh"

curator --config /home/ubuntu/compose_setup/curator/curator.yml /home/ubuntu/compose_setup/curator/delete_old_snapshots.yml
curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E" | grep accepted\":true
if [ $? -ne 0 ]
then
	curl -X POST -H 'Content-type: application/json' --data '{"text":"Taking snapshot failed."}' $WEBHOOK_URL
else
	cd /home/ubuntu/compose_setup
	zip -r essnapshot-$dayofmonth.zip essnapshot
	aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 cp /home/ubuntu/compose_setup/essnapshot-$dayofmonth.zip s3://logstash-elasticdata/essnapshot-$dayofmonth.zip > $filename
	if [ $? -ne 0 ]
	then
		curl -X POST -H 'Content-type: application/json' --data '{"text":"Sending snapshot to s3 failed."}' $WEBHOOK_URL
	fi
fi
