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

# List of commands to check
commands=("oc" "yq" "jq" "podman")

# Function to check each command
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed."
        return 1
    fi
    return 0
}

# Check each command and report if missing
missing_count=0
for cmd in "${commands[@]}"; do
    if ! check_command $cmd; then
        missing_count=$((missing_count + 1))
    fi
done

# Report summary
if [ $missing_count -ne 0 ]; then
    echo "There are $missing_count missing commands."
else
    echo "All commands are installed."
fi


cd 3scale
./install-3scale-apim.sh $1
# Return to the original directory
cd -
cd amqBroker
./install-amq-broker-cluster.sh
cd -
cd dataGrid
./install-data-grid-cluster.sh
cd -
cd kafka
./install-kafka-cluster.sh
cd -
cd keda
./install-keda.sh
cd -
# Define the namespace
NAMESPACE="webhook-system-3scale"
echo "Waiting for 3scale pods to be in running status."
# Define the target number of running pods
TARGET_POD_COUNT=16

# Infinite loop to keep checking the pod count
while true; do
    # Get the current number of running pods in the specified namespace
    CURRENT_POD_COUNT=$(oc get pods -n $NAMESPACE --field-selector=status.phase=Running -o json | jq '.items | length')

    # Check if the current number of running pods matches the target
    if [ "$CURRENT_POD_COUNT" -eq "$TARGET_POD_COUNT" ]; then
        echo "3scale running pods reached: $CURRENT_POD_COUNT"
        break # Exit the loop
    else
        echo "Currently, there are $CURRENT_POD_COUNT running 3scale pods. Waiting for $TARGET_POD_COUNT..."
        sleep 10 # Wait for 10 seconds before checking again
    fi
done

cd 3scale/order-event-product
./install-product.sh
cd -
cd 3scale/dev-portal
./upload-contents.sh
cd -
cd consumer
./install.sh
cd -
cd webhook-system
./install.sh