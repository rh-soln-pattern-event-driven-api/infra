#!/bin/bash


oc apply -f 00-cluster-monitoring-config.yaml
oc apply -f 01-namespace.yaml
oc apply -f 02-operatorgroup.yaml
oc apply -f 03-custom-metrics-autoscaler-operator.yaml


# Define the namespace
NAMESPACE="openshift-keda"

CSV_NAME="custom-metrics-autoscaler"

# Loop until the CSV is in the 'Succeeded' phase
while true; do
  # Check if the CSV is in the 'Succeeded' phase
  if oc get csv -n $NAMESPACE -o jsonpath="{range .items[*]}{.metadata.name}:{.status.phase}{'\n'}{end}" | grep "^custom-metrics-autoscaler.*:Succeeded"; then
    echo "Operator $CSV_NAME is successfully installed."
    break  # Ensure this break is uncommented to exit the loop once the operator is installed
  else
    echo "Waiting for Operator $CSV_NAME to be installed..."
  fi
  # Sleep for 10 seconds before checking again
  sleep 10
done
echo "Creating Keda Controller."
oc apply -f 04-kedacontroller.yaml