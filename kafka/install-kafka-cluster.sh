#!/bin/bash

# Create the Red Hat kafka namespace
oc apply -f 00-namespace.yaml
oc apply -f 01-operator-group.yaml
oc apply -f 02-amqstreams-operator.yaml

# Define the namespace
NAMESPACE="webhook-system-kafka"

# Define the name of the CSV you are looking for
CSV_NAME="amqstreams"

# Loop until the CSV is in the 'Succeeded' phase
while true; do
  # Check if the CSV is in the 'Succeeded' phase
  if oc get csv -n $NAMESPACE -o jsonpath="{range .items[*]}{.metadata.name}:{.status.phase}{'\n'}{end}" | grep "^amqstreams.*:Succeeded"; then
    echo "Operator $CSV_NAME is successfully installed."
    break  # Ensure this break is uncommented to exit the loop once the operator is installed
  else
    echo "Waiting for Operator $CSV_NAME to be installed..."
  fi
  # Sleep for 10 seconds before checking again
  sleep 10
done
echo "Creating Kafka Cluster."
# Apply further configurations after the operator installation is confirmed
oc apply -f 03-kafka-cluster.yaml
oc apply -f 04-order-created-event-topic.yaml
