#!/bin/sh

./load.sh myapp-dashboards	
#./load.sh kafka-dashboards	
#./load.sh graphite-dashboards	
./load.sh k8s-dashboards	
./load.sh elk-dashboards	
