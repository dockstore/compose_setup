# Compose Setup Requirements

There are 3 different sets of metric logs being sent to logstash's elasticsearch:
1. Apache HTTP logs => Logstash => elasticsearch
2. Dropwizard Metrics => Metricbeats => elasticsearch
3. Postgres Metrics => Metricbeats => elasticsearch

## Apache HTTP Logs

Currently, install_bootstrap and docker-compose handles all necessary configuration

## Postgres

Setup is unlikely required if metricbeats and postgres are on the same docker network.  If it isn't, ensure that `/etc/postgresql/9.6/main/pg_hba.conf` allows the requests.
Additionally, if pg_stat_statements are required, `shared_preload_libraries = 'pg_stat_statements'` needs to be added to the `/etc/postgresql/9.6/main/postgresql.conf` file.

## Dropwizard

Get the admin port of Dockstore dropwizard (likely 8081 by default).  Make sure it's open to metricbeat.

# Dashboards, visualizations, and index patterns configuration

## Alerts

New rules are placed in the rules directory.  Rules can be either added/modified there or via the elasticAlert kibana plugin in the kibana dashboard.

## Kibana setup

See the correct elastic version of the [elastic guide](https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html#_import_objects) on how to import saved objects.  The JSON file is [export.json](export.json).  If index ID is missing during the import, it will likely let you choose another index.  The index to choose is `logstash-*`.  If `logstash-*` is not one of the selectable options, skip it for now and let it continue.  Then perform the import instructions again, `logstash-*` should be selectable this time.

## Elasticsearch backup

### Snapshot repository creation:
Make sure elasticsearch-logstash has essnapshot write permissions
From within kibana of the docker-compose.dev.yml:
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
From the docker-compose.dev.yml server:
`curl -X PUT "localhost:9200/_snapshot/my_backup/%3Csnapshot-%7Bnow%2Fd%7D%3E"` to take a daily backup that results in a snapshot named like snapshot-2018.09.26

### Delete snapshot
`curl -X DELETE "localhost:9200/_snapshot/my_backup/snapshot-2018.09.26"`


### Restoring snapshots
From the docker-compose.dev.yml server:
- `curl -X POST "localhost:9200/_all/_close"` 
- `curl -X POST "localhost:9200/_snapshot/my_backup/snapshot-2018.09.26/_restore"`
- `curl -X POST "localhost:9200/_all/_open"`

# Quirks

- Port 9200 on the logstash's elasticsearch must be opened to metricbeats in order for metricbeats to send data to elasticsearch directly. 
- If metricbeats is brought up before logstash's elasticsearch, metricbeats will keep restarting until logstash's elasticsearch is operational.
- Taking down logstash's elasticsearch will causes the metricbeats to go down.  Metricbeats must then be restarted.
- Default index pattern must be selected before any dashboards can be viewed.  Set the default index pattern using the star.

# Additional Notes

To use self-signed certificate to run https locally, swap the comments in the [templates/default.nginx_https.shared.conf.template](templates/default.nginx_https.shared.conf.template) and [docker-compose.yml](docker-compose.yml)
