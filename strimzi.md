
# Strimzi

Kafka on Kubernetes

https://docs.google.com/presentation/d/1tMXZwovpBB26UPESjurjNogjKb8Xt4LbDc1-tc6FFzQ/edit#slide=id.g84e3aac718_0_73

# Demo

```bash

#vi helmfile.yaml
kubectl get pod -n my-kafka-project -w
helmfile -e gcp apply
vi config/strimzi/my-kafka.yaml
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n my-kafka-project

kubens my-kafka-project
kubectl describe Kafka my-cluster
kubectl describe KafkaTopic my-topic   

kubectl run kafka-consumer -ti --image=strimzi/kafka:latest-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap.my-kafka-project.svc:9092 --topic my-topic

kubectl run kafka-producer -ti --image=strimzi/kafka:latest-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap.my-kafka-project.svc:9092 --topic my-topic

kubectl run kafka-consumer -ti --image=strimzi/kafka:latest-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-consumer-perf-test.sh \
  --messages 5000000 \
  --topic my-topic \
  --threads 1 \
  --bootstrap-server my-cluster-kafka-bootstrap.my-kafka-project.svc:9092

kubectl run kafka-producer -ti --image=strimzi/kafka:latest-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-producer-perf-test.sh \
  --topic my-topic \
  --num-records 5000000 \
  --record-size 100 \
  --throughput -1 \
  --producer-props acks=1 \
  bootstrap.servers=my-cluster-kafka-bootstrap.my-kafka-project.svc:9092 \
  buffer.memory=67108864 \
  batch.size=8196
  
  https://grafana.gcp.continotb.com/d/8wCTC5Tmz/strimzi-kafka?orgId=1&refresh=5s

```

# Kafka Brdige
```bash
curl -X POST \
  https://bridge.gcp.continotb.com/topics/my-topic \
  -H 'content-type: application/vnd.kafka.json.v2+json' \
  -d '{
    "records": [
        {
            "key": "key-1",
            "value": "value-1"
        },
        {
            "key": "key-2",
            "value": "value-2"
        }
    ]
}'

curl -X POST https://bridge.gcp.continotb.com/consumers/my-group \
  -H 'content-type: application/vnd.kafka.v2+json' \
  -d '{
    "name": "my-consumer",
    "format": "json",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": false
  }'
  
curl -X POST https://bridge.gcp.continotb.com:443/consumers/my-group/instances/my-consumer/subscription \
  -H 'content-type: application/vnd.kafka.v2+json' \
  -d '{
    "topics": [
        "my-topic"
    ]
}'

curl -X GET https://bridge.gcp.continotb.com:443/consumers/my-group/instances/my-consumer/records \
  -H 'accept: application/vnd.kafka.json.v2+json'
  
```
