#!/bin/bash

# Usage function to display help
usage() {
  echo "Usage: $0 [file-storage-storageClassName] "
  echo "Example: $0 nfs-storage"
}

# Check if one argument are provided
if [ $# -ne 1 ]; then
  usage
  exit 1
fi

# Retrieve the wildcard domain from the default ingress controller
WILDCARD_DOMAIN=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')

# Check if the domain was successfully retrieved
if [ -z "$WILDCARD_DOMAIN" ]; then
    echo "Failed to retrieve the wildcard domain."
    exit 1
else
    echo "The wildcard domain is: $WILDCARD_DOMAIN"
fi
export WILDCARD_DOMAIN=$WILDCARD_DOMAIN
 
export  STORAGE_CLASS_NAME=$1

yq eval '.spec.wildcardDomain=env(WILDCARD_DOMAIN)' -i 05-api-manager.yaml
yq eval '.spec.system.fileStorage.persistentVolumeClaim.storageClassName=env(STORAGE_CLASS_NAME)' -i 05-api-manager.yaml

# Create 3scale namespace
oc apply -f 00-namespace.yaml
oc apply -f 01-operator-group.yaml
oc apply -f 02-3scale-operator.yaml

# Define the namespace
NAMESPACE="webhook-system-3scale"

CSV_NAME="3scale-operator"

# Loop until the CSV is in the 'Succeeded' phase
while true; do
  # Check if the CSV is in the 'Succeeded' phase
  if oc get csv -n $NAMESPACE -o jsonpath="{range .items[*]}{.metadata.name}:{.status.phase}{'\n'}{end}" | grep "^3scale-operator.*:Succeeded"; then
    echo "Operator $CSV_NAME is successfully installed."
    break  # Ensure this break is uncommented to exit the loop once the operator is installed
  else
    echo "Waiting for Operator $CSV_NAME to be installed..."
  fi
  # Sleep for 10 seconds before checking again
  sleep 10
done
echo "Installing 3scale API Manager."
# Apply further configurations after the operator installation is confirmed
oc apply -f 04-system-seed-secret.yaml
oc apply -f 05-api-manager.yaml
oc -n $NAMESPACE create secret generic threescale-provider-account --from-literal=adminURL=https://webhook-apis-admin.$WILDCARD_DOMAIN --from-literal=token=88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512