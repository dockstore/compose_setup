#!/usr/bin/env bash
set -x
set -e

cd compose_setup
s3_url_essnapshot_backup='s3://oicr.backups.dockstore/staging.dockstore.org/essnapshot'

aws s3 --region us-east-1 cp essnapshot $s3_url_essnapshot_backup/ --recursive

echo "Uploaded essnapshot to s3://oicr.backups.dockstore/staging.dockstore.org/essnapshot"
