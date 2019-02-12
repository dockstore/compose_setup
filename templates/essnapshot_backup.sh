#!/usr/bin/env bash
set -x

WEBHOOK_URL='{{SLACK_URL}}'

mkdir -p /home/ubuntu/compose_setup/logs
# Corresponding cronjobs are:
#0 5 * * * (date && /home/ubuntu/certbot-auto renew) >> /home/ubuntu/logs/certbot-auto.log 2>&1
#0 5 * * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh daily >> /home/ubuntu/compose_setup/logs/daily-cron.log 2>&1
#15 5 * * 0 /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh weekly >> /home/ubuntu/compose_setup/logs/weekly-cron.log 2>&1
#30 5 1 * * /bin/bash /home/ubuntu/compose_setup/scripts/essnapshot_backup.sh monthly >> /home/ubuntu/compose_setup/logs/monthly-cron.log 2>&1

/home/ubuntu/.local/bin/curator --config /home/ubuntu/compose_setup/curator/curator.yml /home/ubuntu/compose_setup/curator/delete_old_snapshots.yml
/home/ubuntu/.local/bin/curator --config /home/ubuntu/compose_setup/curator/curator.yml /home/ubuntu/compose_setup/curator/take_snapshots.yml
if [ $? -ne 0 ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Taking snapshot failed."}' $WEBHOOK_URL
    exit 1
fi

cd /home/ubuntu/compose_setup
zip --quiet -r essnapshot-$1.zip essnapshot
previoussize=`/usr/bin/aws s3 ls s3://oicr.logs.backup/essnapshot-$1.zip --summarize | grep 'Total Size:' | awk '{print $3}'`
currentsize=`stat --printf="%s" essnapshot-$1.zip`

if [ $previoussize -gt $currentsize ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Size of previous snapshots greater than current snapshots, aborting."}' $WEBHOOK_URL
    echo "Size of previous snapshots greater than current snapshots"
    exit 1
fi

/usr/bin/aws s3 cp /home/ubuntu/compose_setup/essnapshot-$1.zip s3://oicr.logs.backup/essnapshot-$1.zip

if [ $? -ne 0 ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Sending snapshot to s3 failed."}' $WEBHOOK_URL
fi

