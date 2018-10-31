#!/usr/bin/env bash
set -x
set -e

cd compose_setup

aws s3 --endpoint-url https://object.cancercollaboratory.org:9080 sync essnapshot s3://logstash-elasticdata/essnapshot

echo "Uploaded essnapshot to s3://oicr.backups.dockstore/staging.dockstore.org/essnapshot"
