# compose_setup
Demonstrate how to setup and run Dockstore using composed containers

## Developers

One useful tool is https://github.com/royrusso/elasticsearch-HQ 
Make sure to get the right version for your version of elastic search (I've been testing with v2.0.3 with a 2.4.5) version of Elastic Search. 
Note that Elastic Search will need to be started with something akin to 

    docker run -p 9200:9200 -p 9300:9300  -d elasticsearch:2.4.5 --http.cors.enabled=true --http.cors.allow-origin=*

However, this is not a secure way to run in production
