# Dev Compose Setup Requirements
There are 3 different sets of metric logs being sent to logstash's elasticsearch:
1. Apache HTTP logs => Logstash => elasticsearch
2. Dropwizard Metrics => Metricbeats => elasticsearch
3. Postgres Metrics => Metricbeats => elasticsearch

## Ports
- Port 9200 must be opened for metricbeats to send data to elasticsearch directly
- Port 5055 must be opened for webservice to send data to logstash
- Port 5601 must be opened for developers to view the kibana dashboard

## Apache HTTP Logs

Currently, install_bootstrap and docker-compose handles all necessary configuration

## Postgres

Setup is unlikely required if metricbeats and postgres are on the same docker network.  If it isn't, ensure that `/etc/postgresql/9.6/main/pg_hba.conf` allows the requests.
Additionally, if pg_stat_statements are required, `shared_preload_libraries = 'pg_stat_statements'` needs to be added to the `/etc/postgresql/9.6/main/postgresql.conf` file.

## Dropwizard

Get the admin port of Dockstore dropwizard (likely 8081 by default).  Make sure it's open to metricbeat.

# Dashboards, visualizations, and index patterns configuration

## Alerts

Rules should be added/modified in the [templates/rules](templates/rules) directory because SLACK_URL requires templating. Rules can be temporarily added/modified in `config/rules` or via the elasticAlert kibana plugin in the kibana dashboard.

## Elasticsearch backup

### Snapshot repository creation:
Make sure elasticsearch-logstash has essnapshot write permissions. Run this commands from within the docker-compose.dev.yml server.
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

### Creating daily snapshots
`curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E"` to take a daily backup that results in a snapshot named like snapshot-2018.09.26

### Delete snapshot
`curl -X DELETE "localhost:9200/_snapshot/my_backup/snapshot-2018.09.26"`

Alternatively, you can delete old snapshots automatically using curator.  Install with `pip install elasticsearch-curator==5.6.0` then delete old with `curator --config curator.yml delete_old_snapshots.yml` inside the curator directory.


### Restoring snapshots
- `curl -X POST "localhost:9200/_all/_close"` 
- `curl -X POST "localhost:9200/_snapshot/my_backup/snapshot-2018.09.26/_restore"`
- `curl -X POST "localhost:9200/_all/_open"`

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
- go to compose_setup
- `bash scripts/self-signed-certificate.sh`
- swap the comments in the [templates/default.nginx_https.shared.conf.template](templates/default.nginx_https.shared.conf.template) and [docker-compose.yml](docker-compose.yml)
