#!/bin/bash

bower --allow-root update
ng build
# the following doesn't work, which isn't quite right
# ng build --prod
http-server -p 4200 ./dist 
