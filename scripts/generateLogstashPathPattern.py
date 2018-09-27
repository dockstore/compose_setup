import json
import re
import urllib

link = "https://dockstore.org/api/swagger.json"
f = urllib.urlopen(link)
json_string = f.read()
parsed_json = json.loads(json_string)
paths = parsed_json['paths']
pathArray = paths.keys()
sortedPathArray = sorted(pathArray, reverse=True)
for path in sortedPathArray:
    pattern = re.sub("{[a-zA-Z\_\-]+}", "[^/]+", path)
    logstashPattern = "\"^" + pattern + "$\" => \"" + path + "\""
    logstashPattern = logstashPattern.replace("/descriptor/[^/]+", "/descriptor/.*")
    print logstashPattern
