#!/bin/sh
mkdir -p config/$1/generated
cd jsonnet
FILES=*$2*.jsonnet
for f in $FILES
do
  echo "Processing $f file..."
  jsonnet $f > tmp.json
  python -c 'import sys,yaml,json; yaml.safe_dump(json.load(sys.stdin),sys.stdout,default_flow_style=False)' < tmp.json > ../config/$1/generated/$f.yaml
done
rm tmp.json
