#!/usr/bin/env bash
set -x

WEBHOOK_URL='{{SLACK_URL}}'

mkdir -p /home/ubuntu/compose_setup/logs
# Corresponding cronjobs are:
# "0 0 * * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh daily &> /home/ubuntu/compose_setup/logs/`/bin/date +\%Y-\%m-\%d.\%H:\%M:\%S`-cron.log"
# "15 0 * * 0 /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh weekly &> /home/ubuntu/compose_setup/logs/`/bin/date +\%Y-\%m-\%d.\%H:\%M:\%S`-cron.log"
# "30 0 1 * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh monthly &> /home/ubuntu/compose_setup/logs/`/bin/date +\%Y-\%m-\%d.\%H:\%M:\%S`-cron.log"
/home/ubuntu/.local/bin/curator --config /home/ubuntu/compose_setup/curator/curator.yml /home/ubuntu/compose_setup/curator/delete_old_snapshots.yml
curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E?wait_for_completion=true" | grep accepted\":true
if [ $? -ne 0 ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Taking snapshot failed."}' $WEBHOOK_URL
    exit 1
fi

cd /home/ubuntu/compose_setup
zip -r essnapshot-$1.zip essnapshot
previoussize=`/home/ubuntu/.local/bin/aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 ls s3://logstash-elasticdata/essnapshot-$1.zip --summarize | grep 'Total Size:' | awk '{print $3}'`
currentsize=`stat --printf="%s" essnapshot-$1.zip`

if [ $previoussize -gt $currentsize ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Size of previous snapshots greater than current snapshots, aborting."}' $WEBHOOK_URL
    echo "Size of previous snapshots greater than current snapshots"
    exit 1
fi

/home/ubuntu/.local/bin/aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 cp /home/ubuntu/compose_setup/essnapshot-$1.zip s3://logstash-elasticdata/essnapshot-$1.zip

if [ $? -ne 0 ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Sending snapshot to s3 failed."}' $WEBHOOK_URL
fi

