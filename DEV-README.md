# Dev Compose Setup Requirements
There are 3 different sets of metric logs being sent to logstash's elasticsearch:
1. Apache HTTP logs => Logstash => elasticsearch
2. Dropwizard Metrics => Metricbeats => elasticsearch
3. Postgres Metrics => Metricbeats => elasticsearch

## Ports
- Port 5055 must be opened for the production webservice to send data to logstash
- Port 5066 must be opened for the staging webservice to send data to logstash
- Port 5601 must be opened for developers to view the kibana dashboard

## Apache HTTP Logs

Currently, install\_bootstrap and docker-compose handles all necessary configuration

<!-- Long term, will likely move to AWS RDS, making postgres setup simpler
## Postgres

Setup is unlikely required if metricbeats and postgres are on the same docker network.  If it isn't, ensure that `/etc/postgresql/9.6/main/pg_hba.conf` allows the requests.
Additionally, if pg\_stat\_statements are required, `shared_preload_libraries = 'pg_stat_statements'` needs to be added to the `/etc/postgresql/9.6/main/postgresql.conf` file.
-->

## Dropwizard

Get the admin port of Dockstore dropwizard (likely 8081 by default).  Make sure it's open to metricbeat.

# Dashboards, visualizations, and index patterns configuration

## Alerts

Rules should be added/modified in the [templates/rules](templates/rules) directory because SLACK\_URL requires templating. Rules can be temporarily added/modified in `config/rules` or via the elasticAlert kibana plugin in the kibana dashboard.

### Notes

The frequency rule in elasticalert is not intuitive.

If the rule says it's supposed to trigger if there's 5 documents found within a 1 hr time frame and a 5 minute query rate, I'd expect that if the logs were consistently producing 4 docs per 5 mins to trigger an alert on the 10-min mark and every 5 mins after.

However, what actually happens is the counter is cleared after every alert is triggered.  This results in an alert triggering on the 10-min mark and then every 10 mins after.


## Elasticsearch backup
Install elasticsearch-curator because it makes life a lot easier.
```
pip install elasticsearch-curator==5.6.0
``` 
Check that `curator_cli` and `curator` command works.

### Snapshot repository creation:
Make sure elasticsearch-logstash has essnapshot write permissions. 
```
sudo chown -R ubuntu:ubuntu essnapshot
sudo chmod -R 775 essnapshot
```
Run this commands from within the docker-compose.dev.yml server.
```
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
{
    "type": "fs",
    "settings": {
        "location": "/mount/backups",
        "compress": true
    }
}
'
```
If your essnapshot directory has snapshots already, double check by using:
```
curator_cli show_snapshots --repository my_backup
```

### Creating daily snapshots

Take a look at `scripts/essnapshot_backup.sh` for the appropriate cron tasks to setup the daily backup. Note that this relies upon an IAM user setup with write permissions to the appropriate S3 bucket. 

### Delete snapshot
`curl -X DELETE "localhost:9200/_snapshot/my_backup/snapshot-2018.09.26"`

Alternatively, you can delete old snapshots automatically using curator.  Delete old snapshots with `curator --config curator.yml delete_old_snapshots.yml` inside the curator directory.


### Restoring snapshots procedure
Before bringing up elasticsearch-logstash, download the newest zip file from s3 and extract its contents into the essnapshot directory. Then follow the [Snapshot repository creation](#snapshot-repository-creation) section and ensure the snapshots are readable.  Restart elasticsearch-logstash if not snapshots are found.  Perform the snapshot restore:
- `curl -X POST "localhost:9200/_all/_close"`
Replace "snapshot-2019.01.04" with the actual snapshot name
- `curl -X POST "localhost:9200/_snapshot/my_backup/snapshot-2019.01.04/_restore?wait_for_completion=true"`
- `curl -X POST "localhost:9200/_all/_open"`

Double check in Kibana that the amount of hits are sane

## Kibana setup
Generally, snapshot repo create and then snapshot restore should be used first.  In the event that there's no snapshot, export.json can be used to recover everything except for the actual logging data.

### Using export.json
See the correct elastic version of the [elastic guide](https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html#_import_objects) on how to import saved objects.  The JSON file is [export.json](export.json).  If index ID is missing during the import, it will likely let you choose another index.  The index to choose is `logstash-*`.  If `logstash-*` is not one of the selectable options, skip it for now and let it continue.  Then perform the import instructions again, `logstash-*` should be selectable this time.

# Additional Notes
- If metricbeats is brought up before logstash's elasticsearch, metricbeats will keep restarting until logstash's elasticsearch is operational.
- Default index pattern must be selected before any dashboards can be viewed.  Set the default index pattern using the star.
- Generally, every command used by docker-compose.yml should have `docker-compose` replaced with `docker-compose -f docker-compose.dev.yml`. `docker-compose up` becomes `docker-compose -f docker-compose.dev.yml up`

## Self-signed certificate
To use self-signed certificate to run https locally: 
- go to compose\_setup
- `bash scripts/self-signed-certificate.sh`
- swap the comments in the [templates/default.nginx_https.shared.conf.template](templates/default.nginx_https.shared.conf.template) and [docker-compose.yml](docker-compose.yml)

## Elasticsearch Production Setup Differences
Set vm.max_map_count as described in https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode
